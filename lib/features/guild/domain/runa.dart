/// A rune's level (1..10). 10 is the diamond frame; 9/8/7 differ only by the
/// centre symbol — read by hand from the sheet, stored here as a number.
enum NivelRuna {
  nv1(1),
  nv2(2),
  nv3(3),
  nv4(4),
  nv5(5),
  nv6(6),
  nv7(7),
  nv8(8),
  nv9(9),
  nv10(10);

  const NivelRuna(this.numero);
  final int numero;
  static NivelRuna doNumero(int n) =>
      NivelRuna.values.firstWhere((e) => e.numero == n);
}

/// One equipped rune: a family (its colour/name) and a level. The colour does
/// not affect anything but identity; the level is what matters.
class Runa {
  const Runa({required this.familia, required this.nivel});
  final String familia;
  final NivelRuna nivel;
  factory Runa.fromJson(Map<String, dynamic> j) => Runa(
    familia: j['familia'] as String,
    nivel: NivelRuna.doNumero(j['nivel'] as int),
  );
  Map<String, dynamic> toJson() => {'familia': familia, 'nivel': nivel.numero};
}
