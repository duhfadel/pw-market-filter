import '../../../core/result/result.dart';
import '../../../core/supabase/cliente.dart';
import '../domain/guerra/formacao_guerra.dart';

/// Reads and writes the single war-room board — one row, `id = 'atual'`,
/// holding every group under `pts`. There is no history here: a save
/// replaces the board outright, the same way `--rebuild` replaces an index.
class FormacaoRepository {
  Future<Result<FormacaoGuerra>> carregar() async {
    try {
      final row = await supa
          .from('formacao_guerra')
          .select('pts')
          .eq('id', 'atual')
          .maybeSingle();
      final pts = (row?['pts'] as List?) ?? const [];
      return Success(FormacaoGuerra.fromJson({'grupos': pts}));
    } catch (_) {
      return const Failure(GuildFailure(GuildErro.carregar));
    }
  }

  /// Who saved and when travel alongside the board itself — an audit trail
  /// for a row nobody else can see change underneath them.
  Future<Result<void>> salvar(FormacaoGuerra f) async {
    try {
      final u = supa.auth.currentUser;
      await supa.from('formacao_guerra').upsert({
        'id': 'atual',
        'pts': f.toJson()['grupos'],
        'salvo_em': DateTime.now().toUtc().toIso8601String(),
        'salvo_por': u?.id,
        'salvo_por_email': u?.email,
      });
      return const Success<void>(null);
    } catch (_) {
      return const Failure(GuildFailure(GuildErro.salvar));
    }
  }
}
