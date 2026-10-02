import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/core/result/result.dart';
import 'package:pw_market_filter/market/versoes.dart';
import 'package:pw_market_filter/market/versoes_repository.dart';

void main() {
  group('carregar', () {
    test('reads versoes.json with the cache-busting timestamp', () async {
      Uri? pedida;
      final client = MockClient((request) async {
        pedida = request.url;
        return http.Response('{}', 200);
      });

      await VersoesRepository(client).carregar();

      expect(pedida, isNotNull);
      expect(pedida!.path, endsWith('versoes.json'));
      expect(pedida!.queryParameters.keys, contains('t'));
      expect(int.tryParse(pedida!.queryParameters['t']!), isNotNull);
    });

    test('decodes one row per version', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'pw187': VersaoResumo(
              chave: 'pw187',
              nome: '1.8.7',
              personagens: 1715,
              coletadoEm: DateTime.utc(2026, 10, 2),
            ).toJson(),
          }),
          200,
        ),
      );

      final result = await VersoesRepository(client).carregar();

      final versoes = result.fold((v) => v, (_) => null);
      expect(versoes, isNotNull);
      expect(versoes!.keys, {'pw187'});
      expect(versoes['pw187']!.personagens, 1715);
    });

    test(
      '404 is "nobody has ever collected" — not a failure to read',
      () async {
        final client = MockClient((_) async => http.Response('', 404));

        final result = await VersoesRepository(client).carregar();

        expect(
          result.fold((_) => null, (failure) => failure),
          isA<IndexMissingFailure>(),
        );
      },
    );

    test('a body that is not a JSON object is a read failure', () async {
      final client = MockClient((_) async => http.Response('[1, 2, 3]', 200));

      final result = await VersoesRepository(client).carregar();

      expect(
        result.fold((_) => null, (failure) => failure),
        isA<IndexUnreadableFailure>(),
      );
    });

    test('a non-200, non-404 response is a read failure', () async {
      final client = MockClient((_) async => http.Response('', 500));

      final result = await VersoesRepository(client).carregar();

      expect(
        result.fold((_) => null, (failure) => failure),
        isA<IndexUnreadableFailure>(),
      );
    });

    test(
      'a client that throws is a read failure, not an uncaught exception',
      () async {
        final client = MockClient((_) async => throw Exception('rede fora'));

        final result = await VersoesRepository(client).carregar();

        expect(
          result.fold((_) => null, (failure) => failure),
          isA<IndexUnreadableFailure>(),
        );
      },
    );
  });
}
