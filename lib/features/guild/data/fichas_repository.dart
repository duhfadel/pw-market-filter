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
}
