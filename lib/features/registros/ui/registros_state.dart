import '../domain/registro.dart';
import '../domain/registro_filter.dart';

sealed class RegistrosState {
  const RegistrosState();
}

class RegistrosLoading extends RegistrosState {
  const RegistrosLoading();
}

/// The table could not be read. [detail] names what broke rather than saying
/// "erro", because the three causes need three different answers: offline,
/// the project paused, or the table gone.
class RegistrosUnreadable extends RegistrosState {
  const RegistrosUnreadable(this.detail);
  final String detail;
}

class RegistrosReady extends RegistrosState {
  const RegistrosReady({
    required this.todos,
    required this.query,
    required this.selecionado,
  });

  final List<Registro> todos;
  final RegistroQuery query;

  /// The slot whose numbers the panel is showing. `null` before the first
  /// click — the panel then invites one instead of standing empty.
  final Registro? selecionado;

  List<String> get abas => abasDe(todos);

  /// The recipes of the open tab, in slot order.
  List<Registro> get daAba => paraGrade(todos, query);

  /// The open tab laid out as the game lays it: one entry per cell, `null`
  /// where the window shows an empty frame.
  List<Registro?> get grade => emSlots(daAba);

  /// How many of the drawn slots the filter lights.
  int get acesos => daAba.where((r) => atende(r, query)).length;

  /// Which toggles still lead somewhere, read off the open tab.
  Set<RegistroAtributo> get disponiveis => atributosDisponiveis(daAba, query);

  /// Recipes still waiting for somebody to record what they grant. It is on
  /// screen because a gap nobody counts is a gap nobody fills.
  int get semDados => todos.where((r) => r.semDados).length;

  RegistrosReady copyWith({
    RegistroQuery? query,
    Registro? selecionado,
    bool limparSelecao = false,
  }) => RegistrosReady(
    todos: todos,
    query: query ?? this.query,
    selecionado: limparSelecao ? null : (selecionado ?? this.selecionado),
  );
}
