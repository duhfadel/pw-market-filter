import '../domain/plano.dart';
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
    this.marcados = const {},
  });

  final List<Registro> todos;
  final RegistroQuery query;

  /// The slot whose numbers the panel is showing. `null` before the first
  /// click — the panel then invites one instead of standing empty.
  final Registro? selecionado;

  /// What the visitor has marked to do, by [Registro.chave].
  ///
  /// It spans tabs on purpose: somebody planning does not stop at Área 1, and
  /// a total that resets when you look at Coletar would answer a question
  /// nobody asked.
  final Set<String> marcados;

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

  /// The bill for what is marked, across every tab.
  Plano get plano => planoDe(todos, marcados);

  /// Whether the open tab still has a lit slot left to mark.
  ///
  /// It drives the label on the button: once everything visible is marked,
  /// offering to mark it again is a control that does nothing.
  bool get temQueMarcar =>
      daAba.any((r) => atende(r, query) && !marcados.contains(r.chave));

  RegistrosReady copyWith({
    RegistroQuery? query,
    Registro? selecionado,
    Set<String>? marcados,
    bool limparSelecao = false,
  }) => RegistrosReady(
    todos: todos,
    query: query ?? this.query,
    selecionado: limparSelecao ? null : (selecionado ?? this.selecionado),
    marcados: marcados ?? this.marcados,
  );
}
