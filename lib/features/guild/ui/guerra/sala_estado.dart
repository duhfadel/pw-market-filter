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
/// the server — it is set right after a successful `salvar()` and nowhere
/// else, so it never claims a save happened when it did not.
class SalaPronta extends SalaEstado {
  const SalaPronta(this.formacao, this.jogadores, {this.salvoEm});

  final FormacaoGuerra formacao;
  final List<Jogador> jogadores;
  final DateTime? salvoEm;

  /// Transcribed roster ids not yet placed in any group — the pool a staff
  /// member still has to drag from.
  List<String> get disponiveis =>
      formacao.disponiveis([for (final j in jogadores) j.id]);
}

class SalaFalha extends SalaEstado {
  const SalaFalha();
}
