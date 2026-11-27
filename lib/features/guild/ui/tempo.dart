/// "Atualizado há N dias" from a row's `atualizadoEm` — the date only.
/// **Not** who touched it: no screen in this feature can resolve another
/// staff member's uid to a name, and a wrong or missing name would be worse
/// than no byline at all.
///
/// Shared between `roster_view.dart` (the card and the table's own column)
/// and `detalhe_view.dart` (the header): both read the exact same field off
/// the exact same kind of row, and a second hand-copy of this body is how
/// the two would drift the day only one of them is edited.
String? rotuloAtualizado(DateTime? data) {
  if (data == null) return null;
  final dias = DateTime.now().difference(data).inDays;
  if (dias <= 0) return 'atualizado hoje';
  if (dias == 1) return 'atualizado há 1 dia';
  return 'atualizado há $dias dias';
}
