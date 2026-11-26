import '../domain/jogador.dart';
import '../domain/papel.dart';

sealed class RosterState {
  const RosterState();
}

class RosterLoading extends RosterState {
  const RosterLoading();
}

class RosterPronto extends RosterState {
  const RosterPronto(this.jogadores, this.papel);
  final List<Jogador> jogadores;
  final Papel papel;
}

class RosterFalha extends RosterState {
  const RosterFalha();
}
