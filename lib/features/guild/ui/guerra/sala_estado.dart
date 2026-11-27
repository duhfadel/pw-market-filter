import '../../domain/guerra/formacao_guerra.dart';
import '../../domain/jogador.dart';

/// The war-room board, as a sealed state.
sealed class SalaEstado {
  const SalaEstado();
}

class SalaCarregando extends SalaEstado {
  const SalaCarregando();
}

/// The board plus the transcribed roster it was pruned against.
///
/// [salvoEm] marks the moment the board on screen last matched the one on
/// the server. It is seeded from the row's own `salvo_em` on `carregar()` —
/// so a staff member who opens the sala sees a teammate's save, not only
/// one made in this session — and set to now right after a successful
/// `salvar()`. [salvoPorEmail] is the same row's `salvo_por_email`, carried
/// alongside so the "salvo há X" label can say who, not only when.
class SalaPronta extends SalaEstado {
  const SalaPronta(
    this.formacao,
    this.jogadores, {
    this.salvoEm,
    this.salvoPorEmail,
  });

  final FormacaoGuerra formacao;
  final List<Jogador> jogadores;
  final DateTime? salvoEm;
  final String? salvoPorEmail;

  /// Transcribed roster ids not yet placed in any group — the pool a staff
  /// member still has to drag from.
  List<String> get disponiveis =>
      formacao.disponiveis([for (final j in jogadores) j.id]);
}

class SalaFalha extends SalaEstado {
  const SalaFalha();
}
