import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/runas/domain/calculo.dart';

/// The other question, asked from the other end: not *what do I still need*
/// but *what can I already make*.
void main() {
  test('the owner\'s example: 100 level ones and 10 level twos', () {
    // 130 level-one units. A level 4 is 54 — so two of them, and 22 over.
    final f = maiorQueDa({1: 100, 2: 10});

    expect(f.nivel, 4);
    expect(f.quantos, 2);
    expect(f.sobra, 22);
  });

  test('it says how many, not just how big', () {
    // **Counting them is the whole correction.** Answering "one level 4" with
    // another whole level 4 buried in the leftover tells the truth in the
    // most awkward way available — the drawer makes two.
    final f = maiorQueDa({1: 100, 2: 10});

    expect(f.parcelasDaSobra, [
      const Parcela(nivel: 3, quantos: 2),
      const Parcela(nivel: 2, quantos: 1),
      const Parcela(nivel: 1, quantos: 1),
    ]);
  });

  test('exactly enough leaves nothing over', () {
    final f = maiorQueDa({1: 3});

    expect(f.nivel, 2);
    expect(f.quantos, 1);
    expect(f.sobra, 0);
  });

  test('a drawer too thin to fuse says level one and means it', () {
    // Two level ones cannot become anything: a level 2 wants three. The
    // screen has to say so rather than dress up what is already in the bag.
    final f = maiorQueDa({1: 2});

    expect(f.nivel, 1);
    expect(f.quantos, 2);
    expect(f.daParaFundir, isFalse);
  });

  test('anything that can climb says so', () {
    expect(maiorQueDa({1: 3}).daParaFundir, isTrue);
  });

  test('an empty drawer makes nothing', () {
    expect(maiorQueDa(const {}).nivel, isNull);
    expect(maiorQueDa(const {}).daParaFundir, isFalse);
  });

  test('it never claims past the top of the ladder', () {
    // Twice what a level 10 costs is two level 10s, not a level 11.
    final f = maiorQueDa({10: 2});

    expect(f.nivel, 10);
    expect(f.quantos, 2);
    expect(f.sobra, 0);
  });
}
