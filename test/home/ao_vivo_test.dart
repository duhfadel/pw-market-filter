import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/domain/canal_ao_vivo.dart';

/// Who from the community is streaming right now.
///
/// The whole risk here is saying somebody is live when they are not: a viewer
/// who clicks and lands on an offline channel stops believing the strip, and
/// one wrong badge costs more than the feature earns.

CanalAoVivo _canal({
  String canal = 'persybr',
  String nome = 'PersyBR',
  bool aoVivo = true,
  int espectadores = 21,
  Object? vistoEm = _padrao,
}) => CanalAoVivo(
  canal: canal,
  nome: nome,
  aoVivo: aoVivo,
  titulo: 'The Classic PW 1.8.7',
  jogo: 'Perfect World',
  espectadores: espectadores,
  // `Object?` com sentinela, e não `DateTime?` com `??`: o teste do canal
  // nunca conferido precisa passar null de verdade, e `??` o trocaria pelo
  // padrão — o teste passaria sem testar nada.
  vistoEm: identical(vistoEm, _padrao)
      ? DateTime.utc(2026, 9, 20, 18, 0)
      : vistoEm as DateTime?,
);

const _padrao = Object();

void main() {
  final agora = DateTime.utc(2026, 9, 20, 18, 3);

  group('who counts as live', () {
    test('somebody the worker just saw live is live', () {
      expect(aoVivoAgora([_canal()], agora), hasLength(1));
    });

    test('somebody marked offline is not shown', () {
      expect(aoVivoAgora([_canal(aoVivo: false)], agora), isEmpty);
    });

    test('a reading older than the window counts as unknown, not as live', () {
      // The failure this exists for: the worker dies — token expired, cron
      // off — and the last row keeps saying "live" for days. Stale is not the
      // same as live, and a strip announcing a stream that ended on Tuesday
      // is worse than no strip.
      final velho = _canal(vistoEm: DateTime.utc(2026, 9, 20, 17, 30));

      expect(aoVivoAgora([velho], agora), isEmpty);
    });

    test('a channel never checked is not live either', () {
      expect(aoVivoAgora([_canal(vistoEm: null)], agora), isEmpty);
    });

    test('the busiest goes first, so one streamer is not always the face', () {
      final poucos = _canal(canal: 'a', nome: 'A', espectadores: 3);
      final muitos = _canal(canal: 'b', nome: 'B', espectadores: 300);

      expect(aoVivoAgora([poucos, muitos], agora).map((c) => c.nome), [
        'B',
        'A',
      ]);
    });
  });

  group('reading a row', () {
    test('an absent viewer count is not zero viewers', () {
      final c = CanalAoVivo.fromJson(const {
        'canal': 'persybr',
        'nome': 'PersyBR',
        'ao_vivo': true,
        'espectadores': null,
      });

      expect(c.espectadores, isNull);
    });

    test('the display name falls back to the login, never to empty', () {
      // The name comes from Twitch and only after the first successful check.
      // A strip reading "está ao vivo" with nobody's name in front of it is a
      // sentence about nothing.
      final c = CanalAoVivo.fromJson(const {'canal': 'persybr', 'nome': null});

      expect(c.nome, 'persybr');
    });
  });
}
