import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/collect.dart';

/// A well-formed index the collector could genuinely publish, encoded as the
/// site would serve it.
String _indexBody({String? historyFrom}) => jsonEncode({
  'formatVersion': 2,
  'server': 'pw187',
  'collectedAt': '2026-09-30T12:00:00Z',
  'attributes': <String>[],
  'items': <String, dynamic>{},
  'characters': <dynamic>[],
  'historyFrom': ?historyFrom,
});

/// [parsePublishedIndex] is the pure seam `_fetchPublishedIndex` reduces to
/// once the network is out of the way — see the finding this fixes: a missing
/// or unreadable published index used to be indistinguishable from a genuine
/// "nobody has ever been seen", and `--rebuild` or a flaky fetch would erase
/// every character's price history in one run. These are the two cases this
/// function exists to tell apart, without a single HTTP request.
void main() {
  test('a 200 with no historyFrom is a genuine first run, not a failure', () {
    final index = parsePublishedIndex(200, _indexBody());
    expect(index.historyFrom, isNull);
  });

  test('a 200 with a historyFrom parses it back', () {
    final index = parsePublishedIndex(
      200,
      _indexBody(historyFrom: '2026-09-15T00:00:00Z'),
    );
    expect(index.historyFrom, DateTime.utc(2026, 9, 15));
  });

  test('a non-200 status is a failure, never a fresh start', () {
    expect(
      () => parsePublishedIndex(500, ''),
      throwsA(isA<PublishedIndexUnavailable>()),
    );
  });

  test('a 200 whose body will not parse is a failure', () {
    expect(
      () => parsePublishedIndex(200, 'not json'),
      throwsA(isA<PublishedIndexUnavailable>()),
    );
  });

  test(
    'a 200 whose body is valid JSON but not a readable index is a failure',
    () {
      expect(
        () => parsePublishedIndex(200, jsonEncode({'formatVersion': 999})),
        throwsA(isA<PublishedIndexUnavailable>()),
      );
    },
  );

  // BLOCKER A in the final review: a 404 is the bootstrap case — this
  // version has never published an index — and it must be the ONE failure
  // `notFound` marks. Every other failure below must leave it false, because
  // the caller (`main` and `_carryForward`) reads this field to decide
  // whether to carry on without history or abort the whole run.
  group('404 is a bootstrap, not an outage — everything else still is', () {
    test('a 404 throws with notFound set', () {
      try {
        parsePublishedIndex(404, '');
        fail('should have thrown');
      } on PublishedIndexUnavailable catch (e) {
        expect(e.notFound, isTrue);
      }
    });

    test('a 500 throws without notFound set', () {
      try {
        parsePublishedIndex(500, '');
        fail('should have thrown');
      } on PublishedIndexUnavailable catch (e) {
        expect(e.notFound, isFalse);
      }
    });

    test('a 200 with an unparseable body throws without notFound set', () {
      try {
        parsePublishedIndex(200, 'not json');
        fail('should have thrown');
      } on PublishedIndexUnavailable catch (e) {
        expect(e.notFound, isFalse);
      }
    });

    test('a 200 with valid JSON that is not a readable index throws without '
        'notFound set', () {
      try {
        parsePublishedIndex(200, jsonEncode({'formatVersion': 999}));
        fail('should have thrown');
      } on PublishedIndexUnavailable catch (e) {
        expect(e.notFound, isFalse);
      }
    });
  });
}
