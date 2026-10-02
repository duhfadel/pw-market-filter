import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/market/index_repository.dart';

void main() {
  group('fileName', () {
    test('pw187 resolves to the file already live on the site', () {
      // Pinned byte for byte: this file is in the air right now, and
      // changing its name breaks the deploy that ships this change.
      expect(
        IndexRepository(null, IndexRepository.pw187).fileName,
        'market_index.json',
      );
    });

    test('pw126 resolves to its own, separate file', () {
      expect(
        IndexRepository(null, IndexRepository.pw126).fileName,
        'market_index_126.json',
      );
    });

    test('the default server, with no argument, is still pw187', () {
      // Every call site written before the second marketplace existed reads
      // `IndexRepository(client)` with no server at all — this is what keeps
      // every one of them reading the same file as before.
      expect(IndexRepository().fileName, 'market_index.json');
    });

    test('an unknown server is refused rather than guessed', () {
      expect(
        () => IndexRepository(null, 'pw999').fileName,
        throwsArgumentError,
      );
    });
  });

  group('load', () {
    Uri? requestedUri;

    http.Client recordingClient(String body) => MockClient((request) async {
      requestedUri = request.url;
      return http.Response.bytes(utf8.encode(body), 200);
    });

    setUp(() {
      requestedUri = null;
    });

    test(
      'pw187 fetches market_index.json with the cache-busting timestamp',
      () async {
        final repository = IndexRepository(
          recordingClient('{"formatVersion": 1}'),
          IndexRepository.pw187,
        );

        await repository.load();

        expect(requestedUri, isNotNull);
        expect(requestedUri!.path, endsWith('market_index.json'));
        expect(requestedUri!.queryParameters.keys, contains('t'));
        expect(int.tryParse(requestedUri!.queryParameters['t']!), isNotNull);
      },
    );

    test('pw126 fetches its own file, same cache-busting timestamp', () async {
      final repository = IndexRepository(
        recordingClient('{"formatVersion": 1}'),
        IndexRepository.pw126,
      );

      await repository.load();

      expect(requestedUri, isNotNull);
      expect(requestedUri!.path, endsWith('market_index_126.json'));
      expect(requestedUri!.queryParameters.keys, contains('t'));
      expect(int.tryParse(requestedUri!.queryParameters['t']!), isNotNull);
    });
  });
}
