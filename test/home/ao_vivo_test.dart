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
  String? titulo = 'The Classic PW 1.8.7',
  String? jogo = 'Perfect World',
  Object? vistoEm = _padrao,
}) => CanalAoVivo(
  canal: canal,
  nome: nome,
  aoVivo: aoVivo,
  titulo: titulo,
  jogo: jogo,
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

  group('playing something else is not live either', () {
    final agora = DateTime.utc(2026, 9, 20, 18, 5);

    test('the Twitch category alone is enough', () {
      final canal = _canal(jogo: 'Perfect World', titulo: 'bom dia');
      expect(aoVivoAgora([canal], agora), hasLength(1));
    });

    test('the title alone is enough, because the category is often wrong', () {
      // Somebody who never changed the category off Just Chatting still
      // writes the game in the title. Demanding both would hide most of them.
      final canal = _canal(jogo: 'Just Chatting', titulo: 'PERFECT WORLD TW');
      expect(aoVivoAgora([canal], agora), hasLength(1));
    });

    test('another game is dropped, however live it is', () {
      final canal = _canal(
        jogo: 'League of Legends',
        titulo: 'ranked ate subir',
      );
      expect(aoVivoAgora([canal], agora), isEmpty);
    });

    test('saying nothing is not a yes', () {
      // No category and no title is not evidence of this game, and announcing
      // it costs the same trust as announcing a stream that already ended.
      expect(aoVivoAgora([_canal(jogo: null, titulo: null)], agora), isEmpty);
    });

    test('`PW` alone does not count, on purpose', () {
      // Two letters match a nickname, a guild tag, a word like `pwzinho`.
      // Showing somebody playing another game is the failure this rule exists
      // to prevent, so the loose match is refused and the cost — a stream
      // titled only `PW` going unshown — is accepted.
      final canal = _canal(jogo: 'Just Chatting', titulo: 'live de PW hoje');
      expect(aoVivoAgora([canal], agora), isEmpty);
    });

    test(
      'a channel playing another game does not displace one that is not',
      () {
        final fora = _canal(canal: 'outro', jogo: 'Dota 2', espectadores: 900);
        final dentro = _canal(canal: 'pavaotv', espectadores: 7);
        expect(aoVivoAgora([fora, dentro], agora).map((c) => c.canal), [
          'pavaotv',
        ]);
      },
    );
  });
}
