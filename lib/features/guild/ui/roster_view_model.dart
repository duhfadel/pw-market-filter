import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/jogadores_repository.dart';
import '../domain/jogador.dart';
import '../domain/papel.dart';
import 'roster_state.dart';

class RosterViewModel extends Cubit<RosterState> {
  RosterViewModel(this._repo, this._papel) : super(const RosterLoading());
  final JogadoresRepository _repo;
  final Papel _papel;

  // 512 KB, the same cap the streamer art bucket already enforces.
  static const int _limiteBytes = 512 * 1024;

  Future<void> carregar() async {
    emit(const RosterLoading());
    final r = await _repo.lista();
    r.fold((lista) => emit(RosterPronto(lista, _papel)), (_) => emit(const RosterFalha()));
  }

  /// True if the player was saved. A role that may not edit never reaches the
  /// repository — defence in depth beside the RLS.
  ///
  /// [print], when given, is uploaded before the player is created — a
  /// player row with a print path nobody could upload would be an orphan
  /// pointing at nothing, so a failed upload never reaches `criar`.
  Future<bool> adicionar(Jogador j, {Uint8List? print, String? nomeArquivo}) async {
    if (!_papel.podeEditarJogadores) return false;
    if (print != null && print.length > _limiteBytes) return false;
    var dados = j;
    if (print != null) {
      final up = await _repo.subirPrint(print, nomeArquivo!);
      final caminho = up.fold((p) => p, (_) => null);
      if (caminho == null) return false; // upload falhou: não cria órfão sem print
      dados = j.comPrintUrl(caminho);
    }
    final r = await _repo.criar(dados);
    final ok = r.fold((_) => true, (_) => false);
    if (ok) await carregar();
    return ok;
  }
}
