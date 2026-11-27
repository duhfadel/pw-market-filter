import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guild/domain/runa.dart';

void main() {
  test('runa round-trips by family and level', () {
    final r = Runa(familia: 'Áurea', nivel: NivelRuna.nv10);
    final back = Runa.fromJson(r.toJson());
    expect(back.familia, 'Áurea');
    expect(back.nivel, NivelRuna.nv10);
  });
  test('level 10 is the top of the ladder', () {
    expect(NivelRuna.nv10.numero, 10);
    expect(NivelRuna.nv7.numero, 7);
  });
}
