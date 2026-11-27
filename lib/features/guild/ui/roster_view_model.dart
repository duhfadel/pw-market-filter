import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/jogadores_repository.dart';
import '../domain/jogador.dart';
import '../domain/papel.dart';
import 'roster_filtro.dart';
import 'roster_state.dart';

class RosterViewModel extends Cubit<RosterState> {
  RosterViewModel(this._repo, this._papel) : super(const RosterLoading());
  final JogadoresRepository _repo;
  final Papel _papel;

  // 512 KB, the same cap the streamer art bucket already enforces.
  static const int _limiteBytes = 512 * 1024;

  /// The search/filter/sort currently in force. It lives here and not in
  /// [RosterState] — it is a view concern over an already-loaded roster,
  /// never something a repository could fail to fetch.
  RosterFiltro _filtro = const RosterFiltro();
  RosterFiltro get filtro => _filtro;

  /// The loaded roster with [_filtro] applied — what the screen actually
  /// draws. Empty while the roster itself has not loaded, since there is
  /// nothing yet to filter.
  List<Jogador> get jogadoresVisiveis {
    final s = state;
    return s is RosterPronto ? _filtro.aplicar(s.jogadores) : const [];
  }

  Future<void> carregar() async {
    emit(const RosterLoading());
    final r = await _repo.lista();
    r.fold((lista) => emit(RosterPronto(lista, _papel)), (_) => emit(const RosterFalha()));
  }

  void setBusca(String busca) => _atualizarFiltro(_filtro.comBusca(busca));

  void setClasse(String? classe) => _atualizarFiltro(_filtro.comClasse(classe));

  void setStatus(String? status) => _atualizarFiltro(_filtro.comStatus(status));

  void setOrdem(OrdemColuna? ordem) => _atualizarFiltro(_filtro.comOrdem(ordem));

  /// Re-emits the current state so `BlocBuilder` rebuilds — [_filtro] is
  /// applied by [jogadoresVisiveis] at read time, so the roster itself never
  /// changes, only the state's identity, which is what a `Cubit` compares to
  /// decide whether to notify.
  void _atualizarFiltro(RosterFiltro novo) {
    _filtro = novo;
    final s = state;
    if (s is RosterPronto) emit(RosterPronto(s.jogadores, s.papel));
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
