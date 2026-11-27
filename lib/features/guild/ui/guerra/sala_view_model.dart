import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../data/formacao_repository.dart';
import '../../data/jogadores_repository.dart';
import '../../domain/guerra/formacao_guerra.dart';
import '../../domain/guerra/grupo_guerra.dart';
import 'sala_estado.dart';

/// The war room's view model: loads the board together with the roster it
/// is pruned against, keeps every mutation as a model-level rebuild (never
/// a mutation in place — `FormacaoGuerra` and `GrupoGuerra` are both
/// immutable), and saves on demand.
///
/// A failed save never lands in [state] — [state] says what the board looks
/// like, and a save that failed to persist does not change what is on
/// screen, only whether it has reached the server. That goes out on
/// [falhasSalvar] instead, a one-shot channel the view listens to for a
/// snackbar, so a lost save is never swallowed quietly.
class SalaGuerrasViewModel extends Cubit<SalaEstado> {
  SalaGuerrasViewModel(this._formacaoRepo, this._jogadoresRepo)
    : super(const SalaCarregando());

  final FormacaoRepository _formacaoRepo;
  final JogadoresRepository _jogadoresRepo;

  final _falhasSalvar = StreamController<GuildFailure>.broadcast();

  /// Save failures only — a signal for a snackbar, not a replacement for
  /// [state]. Nothing else is published on it.
  Stream<GuildFailure> get falhasSalvar => _falhasSalvar.stream;

  @override
  Future<void> close() {
    unawaited(_falhasSalvar.close());
    return super.close();
  }

  /// Loads the board and the roster together. Only `transcrito` players
  /// count as the roster here — a `pendente` entry has no stats to show
  /// beside a name in a group. The board is pruned against that roster on
  /// arrival (`FormacaoGuerra.podada`), dropping anyone who left the guild
  /// or was never transcribed — a ghost member nobody could identify on
  /// screen otherwise.
  Future<void> carregar() async {
    emit(const SalaCarregando());
    final rFormacao = await _formacaoRepo.carregar();
    final rJogadores = await _jogadoresRepo.lista();

    final formacao = rFormacao.fold((f) => f, (_) => null);
    final jogadores = rJogadores.fold((js) => js, (_) => null);
    if (formacao == null || jogadores == null) {
      emit(const SalaFalha());
      return;
    }

    final transcritos = jogadores.where((j) => j.transcrito).toList();
    final podada = formacao.podada({for (final j in transcritos) j.id});
    emit(SalaPronta(podada, transcritos));
  }

  void mover(String jogadorId, int? destino) =>
      _atualizarFormacao((f) => f.moverMembro(jogadorId, destino));

  void alternarLider(int grupo, String jogadorId) =>
      _atualizarGrupo(grupo, (g) => g.alternarLider(jogadorId));

  void renomear(int grupo, String nome) =>
      _atualizarGrupo(grupo, (g) => g.renomear(nome));

  void recolorir(int grupo, String cor) =>
      _atualizarGrupo(grupo, (g) => g.recolorir(cor));

  /// Adds an empty group with a default name and colour — the staff member
  /// renames and recolours afterwards, the same two-step the roster's own
  /// "add player then correct" already follows. `FormacaoGuerra.comGrupo`
  /// is what enforces the twenty-group cap; past it this is a no-op.
  void novaPt() => _atualizarFormacao(
    (f) => f.comGrupo(
      'Pt ${f.grupos.length + 1}',
      _coresPadrao[f.grupos.length % _coresPadrao.length],
    ),
  );

  void removerPt(int grupo) => _atualizarFormacao((f) => f.semGrupo(grupo));

  /// A small rotation of `PWColors.gradeColors`-family hexes, cycled by the
  /// group's position — a new party is never born the same colour as its
  /// immediate neighbour. The staff member can always recolour afterwards.
  static const _coresPadrao = [
    '#56A8F5',
    '#6FCF97',
    '#FFB454',
    '#B57BEE',
    '#E8707C',
  ];

  /// Persists the board as it stands. On success, [state] is re-emitted
  /// with [SalaPronta.salvoEm] set to now; on failure the typed error goes
  /// out on [falhasSalvar] and [state] is left exactly as it was — the
  /// board on screen is still correct, it simply has not reached the
  /// server yet.
  Future<void> salvar() async {
    final s = state;
    if (s is! SalaPronta) return;
    final r = await _formacaoRepo.salvar(s.formacao);
    r.fold(
      (_) => emit(SalaPronta(s.formacao, s.jogadores, salvoEm: DateTime.now())),
      (falha) => _falhasSalvar.add(falha as GuildFailure),
    );
  }

  void _atualizarFormacao(FormacaoGuerra Function(FormacaoGuerra) mudar) {
    final s = state;
    if (s is! SalaPronta) return;
    emit(SalaPronta(mudar(s.formacao), s.jogadores));
  }

  void _atualizarGrupo(int grupo, GrupoGuerra Function(GrupoGuerra) mudar) {
    _atualizarFormacao((f) {
      if (grupo < 0 || grupo >= f.grupos.length) return f;
      return FormacaoGuerra(
        grupos: [
          for (var i = 0; i < f.grupos.length; i++)
            if (i == grupo) mudar(f.grupos[i]) else f.grupos[i],
        ],
      );
    });
  }
}
