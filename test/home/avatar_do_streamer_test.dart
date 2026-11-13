import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/domain/canal_ao_vivo.dart';
import 'package:pw_market_filter/features/home/ui/widgets/ao_vivo_strip.dart';

import '../support/load_fonts.dart';

/// A foto de perfil do canal, no card de quem não enviou arte própria.
///
/// **A regra que estes testes guardam é a divisão**, não o desenho: avatar
/// para quem não tem arte, arte para quem tem, nunca os dois. Duas imagens da
/// mesma pessoa a 90 px uma da outra fariam a autoral — desenhada para esta
/// caixa — perder para a redonda só por estar mais perto do nome.
///
/// O caso «tem arte» não se monta aqui: `_temArte` só fica verdadeiro quando
/// um frame da imagem do balde decodifica, e `flutter_test` não vai à rede
/// por princípio (ver `streamer_art_test`). O que se crava é o lado que um
/// teste pode ver — sem avatar não há círculo, com avatar há exactamente um —
/// e `card_do_streamer_test` continua a cobrir o resto do card.
const _foto =
    'https://static-cdn.jtvnw.net/jtv_user_pictures/'
    'abc-profile_image-300x300.png';

CanalAoVivo _canal({String? avatar}) => CanalAoVivo(
  canal: 'babymda',
  nome: 'babymda',
  aoVivo: true,
  titulo: 'The Classic PW 1.8.7',
  jogo: 'Perfect World',
  espectadores: 7,
  vistoEm: DateTime.now(),
  avatar: avatar,
);

Future<void> _pump(
  WidgetTester tester, {
  required CanalAoVivo canal,
  bool wide = true,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: wide ? 560 : 360,
          child: CardDoStreamer(canal: canal, wide: wide),
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(loadAppFonts);

  test('vazio é ausente, e não um endereço', () {
    // Uma coluna que existe e não foi preenchida não é uma imagem. A Twitch
    // devolve `""` para quem nunca pôs foto, e gravar isso daria um
    // `Image.network('')` — o buraco que o `errorBuilder` existe para evitar.
    expect(
      CanalAoVivo.fromJson({'canal': 'x', 'avatar': ''}).avatar,
      isNull,
      reason: 'string vazia não é endereço',
    );
    expect(CanalAoVivo.fromJson({'canal': 'x'}).avatar, isNull);
    expect(CanalAoVivo.fromJson({'canal': 'x', 'avatar': _foto}).avatar, _foto);
  });

  testWidgets('sem foto, o card é o de sempre', (tester) async {
    // O caso de hoje para dez em dez canais, e tem de continuar a desenhar
    // sem reservar espaço nenhum: espaço guardado para uma imagem que nunca
    // vem foi o defeito que cortou `7 assistindo` fora de um telemóvel.
    await _pump(tester, canal: _canal());

    expect(find.byType(ClipOval), findsNothing);
    expect(find.text('babymda'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('com foto, desenha um círculo e o card continua inteiro', (
    tester,
  ) async {
    await _pump(tester, canal: _canal(avatar: _foto));

    expect(find.byType(ClipOval), findsOneWidget);
    expect(find.text('babymda'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a foto fica à esquerda do nome', (tester) async {
    // É identidade ao lado do nome e não uma segunda ilustração: posta à
    // direita, competiria com o placar, que é o outro extremo que o card
    // existe para ancorar.
    await _pump(tester, canal: _canal(avatar: _foto));

    final foto = tester.getTopLeft(find.byType(ClipOval)).dx;
    final nome = tester.getTopLeft(find.text('babymda')).dx;
    expect(foto, lessThan(nome));
  });

  testWidgets('no telemóvel encolhe e nada transborda', (tester) async {
    await _pump(tester, canal: _canal(avatar: _foto), wide: false);

    final lado = tester.getSize(find.byType(ClipOval));
    expect(lado.width, lado.height, reason: 'redondo, não oval');
    expect(lado.width, lessThan(56), reason: 'menor do que no largo');
    expect(tester.takeException(), isNull);
  });
}
