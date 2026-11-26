import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/jogadores_repository.dart';
import '../domain/jogador.dart';
import '../domain/papel.dart';
import 'roster_state.dart';

class RosterViewModel extends Cubit<RosterState> {
  RosterViewModel(this._repo, this._papel) : super(const RosterLoading());
  final JogadoresRepository _repo;
  final Papel _papel;

  Future<void> carregar() async {
    emit(const RosterLoading());
    final r = await _repo.lista();
    r.fold((lista) => emit(RosterPronto(lista, _papel)), (_) => emit(const RosterFalha()));
  }

  /// True if the player was saved. A role that may not edit never reaches the
  /// repository — defence in depth beside the RLS.
  Future<bool> adicionar(Jogador j) async {
    if (!_papel.podeEditarJogadores) return false;
    final r = await _repo.criar(j);
    final ok = r.fold((_) => true, (_) => false);
    if (ok) await carregar();
    return ok;
  }
}
