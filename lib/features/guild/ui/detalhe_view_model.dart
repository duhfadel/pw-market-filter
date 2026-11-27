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
  final Jogador _jogador;

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
}
