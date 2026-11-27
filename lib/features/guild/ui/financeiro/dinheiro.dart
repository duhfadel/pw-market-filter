import '../../../home/domain/visit_label.dart' show groupThousands;

/// A TCC figure, grouped by thousands and never set in [PWTheme.display] —
/// every number here is money somebody is deciding on, the same rule the
/// market side of this app already follows for a price or a count.
///
/// Reuses the visit counter's own grouping rather than a second hand-rolled
/// loop — the off-by-one at each thousand boundary is exactly the kind of
/// bug `visit_label.dart`'s own doc comment warns a fresh implementation
/// would reintroduce.
String tcc(int valor) => '${groupThousands(valor)} TCC';
