import 'dart:convert';

import 'package:http/http.dart' as http;

import 'visit_memory.dart';

/// The visit counter shown on the front page.
///
/// A static site cannot count anything, so this is the one piece of the Portal
/// with a server behind it: a Supabase project holding a row per day. The key
/// below is public by design — it is compiled into every visitor's browser and
/// there is no way to hide it. What keeps it safe is the database, not the key:
/// `visit_days` has row level security on with no policy at all, so this key
/// cannot read the table, write to it, or delete from it. The only two things
/// it can do are add one to today and read the total, because those are the
/// only two functions it was granted. Both were probed with curl before this
/// shipped, and a direct insert comes back 42501.
///
/// Nothing stops someone calling `register_visit` in a loop and inflating the
/// number. There is no cheap fix on a static site — no session, no server to
/// rate-limit at — and the cost of being wrong is a wrong number in a footer.
/// If it ever happens, `visit_days` keeps the damage to one dated row.
///
/// Unlike every other repository here this one answers with a plain `int?`
/// rather than a `Result`. `Result` earns its place when the screen has to say
/// *what* broke; here every failure — offline, project paused, free tier spent
/// — has the same answer, which is to show no number at all. A typed failure
/// nobody reads would be ceremony.
class VisitRepository {
  VisitRepository({http.Client? client, VisitMemory? memory})
    : _client = client ?? http.Client(),
      _memory = memory ?? VisitMemory.platform();

  final http.Client _client;
  final VisitMemory _memory;

  static const _url = 'https://yadfbwsolmkcaylbxviw.supabase.co/rest/v1/rpc';
  static const _key = 'sb_publishable_D2hgezeh5BbZVpt_QLeXwg_FowKweu2';

  /// Adds this browser to today's count if it is not already there, and
  /// returns the running total. `null` means "show nothing".
  ///
  /// The dedupe is per browser per day, which is what makes the word on screen
  /// *visitas* rather than *pessoas*. The same person on a phone and a laptop
  /// is two, and there is no honest way around that without tracking people —
  /// which this site is not going to do for a number in a footer.
  Future<int?> register() async {
    final today = _today();
    final counted = _memory.read() == today;

    final total = await _call(counted ? 'visit_total' : 'register_visit');

    // Only on success. Marking the day after a failed call would drop this
    // browser's visit for the rest of the day over one blip.
    if (total != null && !counted) _memory.write(today);

    return total;
  }

  Future<int?> _call(String function) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_url/$function'),
            headers: const {'apikey': _key, 'Content-Type': 'application/json'},
            body: '{}',
          )
          // The footer must never hold up the page. If the counter is slow it
          // simply does not appear.
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return null;
      final value = jsonDecode(response.body);
      return value is int ? value : null;
    } on Exception {
      return null;
    }
  }

  /// Brazil's date, matching what `register_visit` writes. Reading the
  /// browser's own timezone instead would let a traveller be counted twice on
  /// one day, and would disagree with the row the server is updating.
  static String _today() {
    final t = DateTime.now().toUtc().subtract(const Duration(hours: 3));
    return '${t.year}-${t.month}-${t.day}';
  }
}
