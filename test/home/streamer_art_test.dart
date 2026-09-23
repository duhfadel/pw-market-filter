import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/domain/canal_ao_vivo.dart';
import 'package:pw_market_filter/features/home/ui/widgets/ao_vivo_strip.dart';

/// A streamer's own art on their card.
///
/// **The file is named after the channel and nothing records it.** A column
/// saying `gsafoot.webp` beside a file called `gsafoot.webp` is one fact
/// written twice, and the two drift the day somebody renames one. The address
/// is derived, the way an item icon is derived from its id — and a channel
/// with no art gets no art, silently, exactly as a missing icon draws nothing.
CanalAoVivo _canal(String login) => CanalAoVivo(
  canal: login,
  nome: login,
  aoVivo: true,
  titulo: null,
  jogo: 'Perfect World',
  espectadores: 39,
  vistoEm: DateTime.utc(2026, 9, 23),
);

void main() {
  test('the address is built from the login', () {
    expect(
      arteDoStreamer('gsafoot'),
      'https://yadfbwsolmkcaylbxviw.supabase.co'
      '/storage/v1/object/public/streamers/gsafoot.webp',
    );
  });

  test('an upper-case login still finds its file', () {
    // Twitch answers with the display name — `PersyBR` — and the bucket holds
    // lower-case files, because that is what the login is.
    expect(arteDoStreamer('PersyBR'), contains('/persybr.webp'));
  });

  testWidgets('the card asks for the art of the channel it shows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CardDoStreamer(canal: _canal('gsafoot'), wide: true),
        ),
      ),
    );

    final imagens = tester
        .widgetList<Image>(find.byType(Image))
        .map((i) => (i.image as NetworkImage).url)
        .toList();
    expect(imagens, contains(arteDoStreamer('gsafoot')));
  });

  testWidgets('no arrow: the card is the target, and it leaves the site', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CardDoStreamer(canal: _canal('gsafoot'), wide: true),
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_forward), findsNothing);
  });
}
