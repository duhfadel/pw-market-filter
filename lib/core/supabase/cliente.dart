import 'package:supabase_flutter/supabase_flutter.dart';

/// The address and the publishable (anon) key of the `portal-pw` project. The
/// key goes in the bundle on purpose — what protects the data is RLS, not
/// hiding it.
const _url = 'https://yadfbwsolmkcaylbxviw.supabase.co';
const _anon = 'sb_publishable_D2hgezeh5BbZVpt_QLeXwg_FowKweu2';

/// Called once in `main()` before `runApp`.
Future<void> iniciarSupabase() =>
    Supabase.initialize(url: _url, publishableKey: _anon);

/// Shortcut to the already-initialized client.
SupabaseClient get supa => Supabase.instance.client;
