import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guild/domain/ficha.dart';
import 'package:pw_market_filter/features/guild/domain/runa.dart';

void main() {
  test('ficha round-trips stats and runes', () {
    final f = Ficha(
      jogadorId: 'j1',
      dados: {'nivel_ataque': 428, 'critico': '74%'},
      runas: [Runa(familia: 'Áurea', nivel: NivelRuna.nv10)],
    );
    final back = Ficha.fromJson(f.toJson());
    expect(back.dados['nivel_ataque'], 428);
    expect(back.runas.single.nivel, NivelRuna.nv10);
  });
}
