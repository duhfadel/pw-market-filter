import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/features/home/data/visit_memory.dart';
import 'package:pw_market_filter/features/home/data/visit_repository.dart';
import 'package:pw_market_filter/features/home/domain/visit_label.dart';

void main() {
  group('visitLabel', () {
    test('groups thousands the way Brazil writes them', () {
      expect(groupThousands(1), '1');
      expect(groupThousands(999), '999');
      expect(groupThousands(1000), '1.000');
      expect(groupThousands(1203), '1.203');
      expect(groupThousands(12034), '12.034');
      expect(groupThousands(999999), '999.999');
      expect(groupThousands(1000000), '1.000.000');
    });

    test('says visita once and visitas from two on', () {
      // The singular shows on day one and never again, so nobody would catch
      // "1 visitas" by looking.
      expect(visitLabel(1), '1 visita');
      expect(visitLabel(2), '2 visitas');
      expect(visitLabel(0), '0 visitas');
      expect(visitLabel(1203), '1.203 visitas');
    });
  });

  group('VisitRepository', () {
    /// Which function was asked for, which is the whole question: counting
    /// twice inflates the number, never counting freezes it.
    late List<String> called;
    late VisitMemory memory;

    setUp(() {
      called = [];
      memory = VisitMemory.platform();
    });

    /// One browser across reloads: the memory outlives the repository, the way
    /// localStorage outlives a page load.
    VisitRepository reload(Object body, {int status = 200}) => VisitRepository(
      memory: memory,
      client: MockClient((request) async {
        called.add(request.url.pathSegments.last);
        return http.Response('$body', status);
      }),
    );

    test('counts a browser it has not seen today', () async {
      expect(await reload(41).register(), 41);
      expect(called, ['register_visit']);
    });

    test('reads without counting when the same browser returns', () async {
      await reload(41).register();
      called.clear();

      // A reload, a trip to the filter and back — the number must still show,
      // and it must not go up.
      expect(await reload(41).register(), 41);
      expect(called, ['visit_total']);
    });

    test('counts again once the day has turned', () async {
      memory.write('1999-1-1');
      expect(await reload(42).register(), 42);
      expect(called, ['register_visit']);
    });

    test('answers null rather than throwing when the counter is down', () async {
      expect(await reload('', status: 503).register(), isNull);

      expect(
        await VisitRepository(
          memory: memory,
          client: MockClient((_) async => throw const _Offline()),
        ).register(),
        isNull,
      );

      // A body that is not a number must not reach the footer either.
      expect(await reload('"muitas"').register(), isNull);
    });

    test('does not mark the day when the call failed', () async {
      await reload('', status: 503).register();
      called.clear();

      // Otherwise one outage would silently drop that browser's visit for the
      // rest of the day — the bug that shipped when shared_preferences failed
      // quietly and every reload counted instead.
      await reload(1).register();
      expect(called, ['register_visit']);
    });
  });
}

class _Offline implements Exception {
  const _Offline();
}
