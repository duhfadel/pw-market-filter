import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/registro_repository.dart';
import '../domain/registro.dart';
import '../domain/registro_filter.dart';
import 'registros_state.dart';

/// The screen's state. The ViewModel **is** the Cubit, as everywhere here.
class RegistrosViewModel extends Cubit<RegistrosState> {
  RegistrosViewModel(this._repository) : super(const RegistrosLoading());

  final RegistroRepository _repository;

  Future<void> load() async {
    final resultado = await _repository.load();

    emit(
      resultado.fold(
        (registros) => registros.isEmpty
            // An empty table is unreadable rather than "a screen with no
            // recipes": the NPC has 126 and a grid of nothing is a fault, not
            // an answer.
            ? const RegistrosUnreadable('a tabela voltou vazia')
            : RegistrosReady(
                todos: registros,
                // Opens on the first tab the NPC shows, not on whatever the
                // database happened to return first.
                query: RegistroQuery(aba: abasDe(registros).first),
                selecionado: null,
              ),
        (falha) => const RegistrosUnreadable('não deu para ler a tabela'),
      ),
    );
  }

  void abrirAba(String aba) {
    final pronto = state;
    if (pronto is! RegistrosReady) return;

    // The panel clears with the tab. Leaving a recipe from Área 1 open under
    // the Casal grid is a detail that no longer belongs to anything on screen.
    emit(
      pronto.copyWith(
        query: pronto.query.copyWith(aba: aba),
        limparSelecao: true,
      ),
    );
  }

  void selecionar(Registro registro) {
    final pronto = state;
    if (pronto is! RegistrosReady) return;
    emit(pronto.copyWith(selecionado: registro));
  }

  void alternarAtributo(RegistroAtributo atributo) {
    final pronto = state;
    if (pronto is! RegistrosReady) return;

    final atributos = {...pronto.query.atributos};
    if (!atributos.remove(atributo)) atributos.add(atributo);
    emit(pronto.copyWith(query: pronto.query.copyWith(atributos: atributos)));
  }

  void limparAtributos() {
    final pronto = state;
    if (pronto is! RegistrosReady) return;
    emit(pronto.copyWith(query: pronto.query.copyWith(atributos: const {})));
  }

  void ordenarPorAproveitamento(bool ligado) {
    final pronto = state;
    if (pronto is! RegistrosReady) return;
    emit(
      pronto.copyWith(query: pronto.query.copyWith(porAproveitamento: ligado)),
    );
  }
}
