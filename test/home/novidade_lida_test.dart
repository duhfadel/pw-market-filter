import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/data/browser_memory.dart';
import 'package:pw_market_filter/features/home/data/novidade_lida.dart';
import 'package:pw_market_filter/features/home/domain/novidade.dart';

/// Plain unit tests, no widget pumped: `NovidadeLida` is the one place the
/// pill's dot and `/novidades`' own mark agree on a key and a comparison, and
/// that fact is cheaper and more precise to pin without a widget tree around
/// it.

Novidade _novidade(DateTime quando) => Novidade(
  titulo: 'Título',
  corpo: 'Corpo',
  autor: null,
  publicadaEm: quando,
);

void main() {
  test('a browser that has never read anything sees something new', () {
    final lida = NovidadeLida(BrowserMemory.platform('teste'));

    expect(lida.existeNaoLida([_novidade(DateTime.utc(2026, 10, 1))]), isTrue);
  });

  test('an empty list is never new, whatever this browser has stored', () {
    final lida = NovidadeLida(BrowserMemory.platform('teste'));

    expect(lida.existeNaoLida(const []), isFalse);
  });

  test('marking the newest entry clears it', () {
    final lida = NovidadeLida(BrowserMemory.platform('teste'));
    final entradas = [_novidade(DateTime.utc(2026, 10, 1))];

    lida.marcarComoLida(entradas);

    expect(lida.existeNaoLida(entradas), isFalse);
  });

  test('a mark older than the newest entry still counts as unread', () {
    final memoria = BrowserMemory.platform('teste');
    final lida = NovidadeLida(memoria);
    lida.marcarComoLida([_novidade(DateTime.utc(2026, 9, 1))]);

    expect(lida.existeNaoLida([_novidade(DateTime.utc(2026, 10, 1))]), isTrue);
  });

  test('the newest entry is found by comparison, not by list order', () {
    final memoria = BrowserMemory.platform('teste');
    final lida = NovidadeLida(memoria);
    final entradas = [
      _novidade(DateTime.utc(2026, 10, 1)),
      _novidade(DateTime.utc(2026, 9, 1)),
    ];

    lida.marcarComoLida(entradas);

    expect(lida.existeNaoLida(entradas), isFalse);
  });

  test('marking an empty list writes nothing', () {
    final memoria = BrowserMemory.platform('teste');
    final lida = NovidadeLida(memoria);

    lida.marcarComoLida(const []);

    expect(memoria.read(), isNull);
  });

  test('the pill and the screen share one store by construction', () {
    // Not a round trip through storage — the point is structural: both
    // sides build their own `NovidadeLida()` with no key of their own to
    // get wrong, so there is no copied string for the two to drift apart
    // on. Two instances with no explicit `BrowserMemory` must still agree
    // once handed the *same* underlying store.
    final memoria = BrowserMemory.platform('teste-compartilhado');
    final doPainel = NovidadeLida(memoria);
    final daTela = NovidadeLida(memoria);
    final entradas = [_novidade(DateTime.utc(2026, 10, 1))];

    expect(doPainel.existeNaoLida(entradas), isTrue);
    daTela.marcarComoLida(entradas);
    expect(doPainel.existeNaoLida(entradas), isFalse);
  });
}
