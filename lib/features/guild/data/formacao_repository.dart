import '../../../core/result/result.dart';
import '../../../core/supabase/cliente.dart';
import '../domain/guerra/formacao_guerra.dart';

/// What [FormacaoRepository.carregar] returns: the board plus the same
/// `salvo_em`/`salvo_por_email` columns [FormacaoRepository.salvar] writes.
/// Without the two, a staff member who opens the sala after a teammate
/// saved sees "ainda não salvo" — the coordination cue the audit trail
/// exists for never reaches whoever did not personally press the button.
class FormacaoCarregada {
  const FormacaoCarregada(this.formacao, {this.salvoEm, this.salvoPorEmail});

  final FormacaoGuerra formacao;
  final DateTime? salvoEm;
  final String? salvoPorEmail;
}

/// Reads and writes the single war-room board — one row, `id = 'atual'`,
/// holding every group under `pts`. There is no history here: a save
/// replaces the board outright, the same way `--rebuild` replaces an index.
class FormacaoRepository {
  Future<Result<FormacaoCarregada>> carregar() async {
    try {
      final row = await supa
          .from('formacao_guerra')
          .select('pts, salvo_em, salvo_por_email')
          .eq('id', 'atual')
          .maybeSingle();
      final pts = (row?['pts'] as List?) ?? const [];
      final salvoEmRaw = row?['salvo_em'] as String?;
      return Success(
        FormacaoCarregada(
          FormacaoGuerra.fromJson({'grupos': pts}),
          salvoEm: salvoEmRaw == null ? null : DateTime.parse(salvoEmRaw),
          salvoPorEmail: row?['salvo_por_email'] as String?,
        ),
      );
    } catch (_) {
      return const Failure(GuildFailure(GuildErro.carregar));
    }
  }

  /// Who saved and when travel alongside the board itself — an audit trail
  /// for a row nobody else can see change underneath them. Returns the
  /// email it saved with, rather than leaving the caller to ask `supa`
  /// directly — the view model has no business touching the Supabase
  /// client, the same boundary every other repository in this feature
  /// already keeps.
  Future<Result<String?>> salvar(FormacaoGuerra f) async {
    try {
      final u = supa.auth.currentUser;
      await supa.from('formacao_guerra').upsert({
        'id': 'atual',
        'pts': f.toJson()['grupos'],
        'salvo_em': DateTime.now().toUtc().toIso8601String(),
        'salvo_por': u?.id,
        'salvo_por_email': u?.email,
      });
      return Success(u?.email);
    } catch (_) {
      return const Failure(GuildFailure(GuildErro.salvar));
    }
  }
}
