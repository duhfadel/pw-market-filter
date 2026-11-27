import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/fichas_repository.dart';
import '../data/jogadores_repository.dart';
import '../domain/jogador.dart';
import '../domain/papel.dart';
import 'roster_filtro.dart';
import 'roster_state.dart';

/// Audit columns a hand correction stamps on `jogadores` — never part of a
/// ficha's `dados`, which only holds the character's own attributes.
const _camposDeAuditoria = {'atualizado_por', 'atualizado_em'};

class RosterViewModel extends Cubit<RosterState> {
  RosterViewModel(this._repo, this._fichasRepo, this._papel)
    : super(const RosterLoading());
  final JogadoresRepository _repo;
  final FichasRepository _fichasRepo;
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
    r.fold(
      (lista) => emit(RosterPronto(lista, _papel)),
      (_) => emit(const RosterFalha()),
    );
  }

  void setBusca(String busca) => _atualizarFiltro(_filtro.comBusca(busca));

  void setClasse(String? classe) => _atualizarFiltro(_filtro.comClasse(classe));

  void setStatus(String? status) => _atualizarFiltro(_filtro.comStatus(status));

  void setOrdem(OrdemColuna? ordem) =>
      _atualizarFiltro(_filtro.comOrdem(ordem));

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
  Future<bool> adicionar(
    Jogador j, {
    Uint8List? print,
    String? nomeArquivo,
  }) async {
    if (!_papel.podeEditarJogadores) return false;
    if (print != null && print.length > _limiteBytes) return false;
    var dados = j;
    if (print != null) {
      final up = await _repo.subirPrint(print, nomeArquivo!);
      final caminho = up.fold((p) => p, (_) => null);
      // upload falhou: não cria órfão sem print
      if (caminho == null) return false;
      dados = j.comPrintUrl(caminho);
    }
    final r = await _repo.criar(dados);
    final ok = r.fold((_) => true, (_) => false);
    if (ok) await carregar();
    return ok;
  }

  /// Hand correction: staff typed a stat directly instead of waiting for a
  /// fresh print to be read. [campos] carries only what changed, by column
  /// name — never the whole player, which would also resend an audit stamp
  /// nobody asked to change.
  ///
  /// `jogadores` is not the only copy of these stats — the detail screen
  /// reads them from the newest `fichas` row — so once the roster PATCH
  /// lands, the same attribute fields (minus the audit stamp, which belongs
  /// to `jogadores` alone) are merged into that ficha too. A correction that
  /// updated the roster and left the ficha behind would make the two
  /// screens disagree about the same player.
  Future<bool> editar(String id, Map<String, dynamic> campos) async {
    if (!_papel.podeEditarJogadores) return false;
    if (campos.isEmpty) return true; // nothing to save, nothing to reload
    final r = await _repo.editar(id, campos);
    final ok = r.fold((_) => true, (_) => false);
    if (ok) {
      final camposDados = Map<String, dynamic>.from(campos)
        ..removeWhere((chave, _) => _camposDeAuditoria.contains(chave));
      if (camposDados.isNotEmpty) {
        await _fichasRepo.corrigirUltima(id, camposDados);
      }
      await carregar();
    }
    return ok;
  }

  /// Re-transcription: a new print replaces the old one and the player goes
  /// back to `pendente` until someone reads it — the same upload path
  /// [adicionar] uses, except the id is preserved rather than a second row
  /// being created.
  Future<bool> trocarImagem(
    String id,
    Uint8List bytes,
    String nomeArquivo,
  ) async {
    if (!_papel.podeEditarJogadores) return false;
    if (bytes.length > _limiteBytes) return false;
    final up = await _repo.subirPrint(bytes, nomeArquivo);
    final caminho = up.fold((p) => p, (_) => null);
    if (caminho == null) return false;
    final r = await _repo.editar(id, {
      'print_url': caminho,
      'status': 'pendente',
    });
    final ok = r.fold((_) => true, (_) => false);
    if (ok) await carregar();
    return ok;
  }
}
