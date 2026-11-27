import '../domain/delta.dart';
import '../domain/ficha.dart';
import '../domain/jogador.dart';

/// The player detail screen, as a sealed state.
sealed class DetalheEstado {
  const DetalheEstado();
}

class DetalheCarregando extends DetalheEstado {
  const DetalheCarregando();
}

/// The player has never had a sheet transcribed — a state of its own and
/// not `DetalheFalha`, the same distinction `GuildSemAcesso` draws from
/// `GuildDeslogado`: an empty history is a fact about the roster, not an
/// error reading it.
class DetalheSemFicha extends DetalheEstado {
  const DetalheSemFicha(this.jogador);
  final Jogador jogador;
}

class DetalhePronto extends DetalheEstado {
  const DetalhePronto(this.jogador, this.atual, this.delta);
  final Jogador jogador;
  final Ficha atual;

  /// Per-field change against the ficha before [atual] — empty when this is
  /// the only ficha on record, since there is nothing to compare against.
  final Map<String, DeltaCampo> delta;
}

class DetalheFalha extends DetalheEstado {
  const DetalheFalha();
}
