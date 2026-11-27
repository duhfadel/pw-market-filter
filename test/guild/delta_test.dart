import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guild/domain/ficha.dart';
import 'package:pw_market_filter/features/guild/domain/delta.dart';

void main() {
  Ficha f(int na) =>
      Ficha(jogadorId: 'j', dados: {'nivel_ataque': na, 'hp': 1000}, runas: []);

  test('rising attack level reads as subiu', () {
    final d = deltaEntre(f(428), f(396));
    expect(d['nivel_ataque']!.rumo, Rumo.subiu);
    expect(d['nivel_ataque']!.para, 428);
  });

  test('no previous ficha means no delta', () {
    expect(deltaEntre(f(428), null), isEmpty);
  });

  test('equal value reads as igual', () {
    expect(deltaEntre(f(428), f(428))['nivel_ataque']!.rumo, Rumo.igual);
  });
}
