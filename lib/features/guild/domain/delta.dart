import 'ficha.dart';

enum Rumo { subiu, desceu, igual }

class DeltaCampo {
  const DeltaCampo(this.de, this.para, this.rumo);
  final num? de;
  final num? para;
  final Rumo rumo;
}

/// Per-field change from the previous snapshot. Only numeric fields compare;
/// a field present now but absent before (or vice-versa) is skipped — we do
/// not invent a baseline. No previous snapshot → no deltas at all.
Map<String, DeltaCampo> deltaEntre(Ficha atual, Ficha? anterior) {
  if (anterior == null) return {};
  final out = <String, DeltaCampo>{};
  atual.dados.forEach((k, v) {
    final a = anterior.dados[k];
    if (v is num && a is num) {
      out[k] = DeltaCampo(a, v, v > a ? Rumo.subiu : (v < a ? Rumo.desceu : Rumo.igual));
    }
  });
  return out;
}
