import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/fichas_repository.dart';
import '../domain/delta.dart';
import '../domain/jogador.dart';
import 'detalhe_estado.dart';

/// The player detail screen: the full stack of transcribed sheets for one
/// player, read down to "what changed since the last one".
class DetalheViewModel extends Cubit<DetalheEstado> {
  DetalheViewModel(this._repo, this._jogador)
    : super(const DetalheCarregando());
  final FichasRepository _repo;
  Jogador _jogador;

  Future<void> carregar() async {
    emit(const DetalheCarregando());
    final r = await _repo.historico(_jogador.id);
    r.fold((historico) {
      if (historico.isEmpty) {
        emit(DetalheSemFicha(_jogador));
        return;
      }
      // `historico` comes back newest first (see FichasRepository), so the
      // first entry is the current sheet and the second — when there is
      // one — is what the delta compares it against.
      final atual = historico.first;
      final anterior = historico.length > 1 ? historico[1] : null;
      emit(DetalhePronto(_jogador, atual, deltaEntre(atual, anterior)));
    }, (_) => emit(const DetalheFalha()));
  }

  /// Lets the page reflect a just-saved edit without re-fetching the whole
  /// ficha history — the player's own columns (`classe`, `limite`, `nivel`…)
  /// changed, not the transcribed stats, so only the state's `jogador`
  /// needs replacing. A state the edit cannot reach — mid-load, or a read
  /// that already failed — is left alone; there is nothing to graft it onto.
  void atualizarJogador(Jogador jogador) {
    _jogador = jogador;
    final s = state;
    switch (s) {
      case DetalhePronto(atual: final atual, delta: final delta):
        emit(DetalhePronto(jogador, atual, delta));
      case DetalheSemFicha():
        emit(DetalheSemFicha(jogador));
      case DetalheCarregando():
      case DetalheFalha():
        break;
    }
  }
}
