import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../data/financeiro_repository.dart';
import '../../data/jogadores_repository.dart';
import '../../domain/financeiro/lancamento.dart';
import 'fin_estado.dart';

/// The financial panel's view model: loads the ledger together with the
/// roster it needs to name a `membro` and feed the staff-payment picker,
/// and writes new or removed entries by reloading afterwards — the same
/// "write then refetch" the roster view model already follows, so the
/// derived totals in [FinPronto] are never computed from a stale list.
///
/// A failed write never lands in [state]: [state] says what the ledger
/// looks like, and a write that failed to persist does not change what is
/// on screen, only whether it reached the server. That goes out on
/// [falhas] instead, the same one-shot channel the war room's own
/// `SalaGuerrasViewModel.falhasSalvar` already uses for its saves.
class FinanceiroViewModel extends Cubit<FinEstado> {
  FinanceiroViewModel(this._financeiroRepo, this._jogadoresRepo)
    : super(const FinCarregando());

  final FinanceiroRepository _financeiroRepo;
  final JogadoresRepository _jogadoresRepo;

  final _falhas = StreamController<GuildFailure>.broadcast();

  /// Write failures only — a signal for a snackbar, not a replacement for
  /// [state]. Nothing else is published on it.
  Stream<GuildFailure> get falhas => _falhas.stream;

  @override
  Future<void> close() {
    unawaited(_falhas.close());
    return super.close();
  }

  /// Loads the ledger and the roster together. Either failing leaves the
  /// whole screen without an honest answer, so both are required.
  Future<void> carregar() async {
    emit(const FinCarregando());
    final rLancamentos = await _financeiroRepo.lista();
    final rJogadores = await _jogadoresRepo.lista();

    final lancamentos = rLancamentos.fold((ls) => ls, (_) => null);
    final jogadores = rJogadores.fold((js) => js, (_) => null);
    if (lancamentos == null || jogadores == null) {
      emit(const FinFalha());
      return;
    }

    emit(FinPronto(lancamentos, jogadores));
  }

  /// Adds a new lançamento. On success, reloads so the new entry and its
  /// effect on every derived total show up; on failure the typed error
  /// goes out on [falhas] and [state] is left exactly as it was.
  Future<void> adicionar(Lancamento l) async {
    final r = await _financeiroRepo.adicionar(l);
    await r.fold((_) => carregar(), (falha) => _reportar(falha));
  }

  /// Removes a lançamento by id. Same shape as [adicionar]: success
  /// reloads, failure is surfaced on [falhas] without touching [state].
  Future<void> remover(String id) async {
    final r = await _financeiroRepo.remover(id);
    await r.fold((_) => carregar(), (falha) => _reportar(falha));
  }

  Future<void> _reportar(AppFailure falha) async {
    _falhas.add(falha as GuildFailure);
  }
}
