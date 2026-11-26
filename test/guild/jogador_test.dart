import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guild/domain/jogador.dart';

void main() {
  test('round-trips the fields the character sheet prints', () {
    const json = {
      'id': 'abc', 'nome': 'Mozaum', 'cla': 'Ragnarok', 'classe': 'Retalhador',
      'nivel': 105, 'despertares': 2, 'cultivo': 'Alma Celestial',
      'limite': 'Céu Soberano IV', 'hp': 59225, 'nivel_ataque': 428,
      'critico': '74%', 'status': 'transcrito',
    };
    final j = Jogador.fromJson(json);
    expect(j.nome, 'Mozaum');
    expect(j.nivelAtaque, 428);
    expect(j.hp, 59225);
    expect(j.transcrito, isTrue);
    expect(j.toJson().containsKey('mp'), isFalse);
  });

  test('pending is the honest state of a player whose print was not read yet', () {
    final j = Jogador.fromJson(const {'id': 'x', 'nome': 'Fulano', 'status': 'pendente'});
    expect(j.transcrito, isFalse);
    expect(j.nivelAtaque, isNull);
  });
}
