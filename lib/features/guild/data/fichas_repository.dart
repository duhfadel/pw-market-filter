import '../../../core/result/result.dart';
import '../../../core/supabase/cliente.dart';
import '../domain/ficha.dart';

/// Reads a player's stack of transcribed sheets — every `fichas` row for
/// one `jogador_id`, newest first. Writing a sheet is `FichaDoJogador`'s
/// job (upload the print, call the vision pipeline); this repository only
/// reads the history back.
class FichasRepository {
  Future<Result<List<Ficha>>> historico(String jogadorId) async {
    try {
      final linhas = await supa
          .from('fichas')
          .select()
          .eq('jogador_id', jogadorId)
          .order('criada_em', ascending: false);
      return Success([for (final l in linhas) Ficha.fromJson(l)]);
    } catch (_) {
      return const Failure(GuildFailure(GuildErro.carregar));
    }
  }

  /// A hand correction merges into the **last** ficha instead of stacking a
  /// new one — a typed-in fix is not a fresh transcription, and giving it
  /// its own snapshot would make the delta compare the correction against
  /// itself on the very next read. [camposDados] carries only the attribute
  /// keys that changed, by the same `dados` key names the parser writes
  /// (`nivel_ataque`, `hp`, `critico`…) — never the audit columns, which
  /// belong to `jogadores` and not to a ficha.
  ///
  /// A `pendente` player has no ficha at all yet, and the roster invariant —
  /// every `jogadores` row has a matching latest `fichas` row — has to hold
  /// even after a correction made before the first print was ever read. So
  /// with no history, this inserts one rather than silently doing nothing.
  Future<Result<void>> corrigirUltima(
    String jogadorId,
    Map<String, dynamic> camposDados,
  ) async {
    try {
      final ultima = await supa
          .from('fichas')
          .select()
          .eq('jogador_id', jogadorId)
          .order('criada_em', ascending: false)
          .limit(1)
          .maybeSingle();
      if (ultima == null) {
        await supa.from('fichas').insert({
          'jogador_id': jogadorId,
          'dados': camposDados,
        });
        return const Success<void>(null);
      }
      final ficha = Ficha.fromJson(ultima);
      final dados = Map<String, dynamic>.from(ficha.dados)
        ..addAll(camposDados);
      await supa.from('fichas').update({'dados': dados}).eq('id', ficha.id!);
      return const Success<void>(null);
    } catch (_) {
      return const Failure(GuildFailure(GuildErro.salvar));
    }
  }
}
