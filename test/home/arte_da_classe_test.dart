import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_colors.dart';
import 'package:pw_market_filter/features/home/domain/arte_da_classe.dart';

/// A largura que o cabeçalho do WebP declara.
///
/// Um WebP arranca com `RIFF....WEBP` e um bloco; o `VP8L` e o `VP8 ` guardam
/// a largura em sítios diferentes, portanto o que se lê aqui é o `VP8X` ou o
/// `VP8L`, que é o que o `cwebp` destes ficheiros escreveu.
int _larguraWebp(List<int> bytes) {
  final dados = Uint8List.fromList(bytes);
  final visao = ByteData.sublistView(dados);
  final formato = String.fromCharCodes(dados.sublist(12, 16));
  return switch (formato) {
    // VP8L: 14 bits de largura menos um, a começar no bit 5 do corpo.
    'VP8L' => (visao.getUint32(21, Endian.little) & 0x3FFF) + 1,
    // VP8X: 24 bits de largura menos um.
    'VP8X' => (visao.getUint32(24, Endian.little) & 0xFFFFFF) + 1,
    // VP8 simples: a largura fica 6 bytes depois do início do bloco.
    _ => visao.getUint16(26, Endian.little) & 0x3FFF,
  };
}

void main() {
  test('every class the market lists has art', () {
    // Seventeen files shipped in assets/images/classes-verticais/ on
    // 30/09/2026, one per class the collected market names. A class with no
    // art would draw an empty hero, which is worse than drawing somebody
    // else's.
    expect(classesComArte, hasLength(17));
  });

  test('the accent is only ever one of the two', () {
    // Never `accent`: that is the money colour, and an accent borrowing it
    // breaks the page's one rule on the screen where it shows most.
    for (final classe in classesComArte) {
      expect(
        acentoDaClasse(classe),
        anyOf(PWColors.violeta, PWColors.magenta),
        reason: classe,
      );
    }
  });

  test('an unmapped class falls back rather than guessing', () {
    expect(acentoDaClasse('Necromante'), PWColors.violeta);
  });

  test('both accents are actually used', () {
    // A map that answered violeta for all seventeen would pass the test above
    // and make the rotation a lie.
    final usados = classesComArte.map(acentoDaClasse).toSet();

    expect(usados, hasLength(2));
  });

  test('the same collection always wears the same class', () {
    // Finding 4 of the 2026-09-30 review: nothing pinned this, so a slide
    // back to `DateTime.now()` — the likelier accident, since it would look
    // like "rotate the hero" — would keep every existing test green. Same
    // `collectedAt` in, same class out, twice, is what a regression to the
    // wall clock cannot survive.
    final quando = DateTime.utc(2026, 8, 9, 12, 30);

    expect(classeDoCartaz(quando), classeDoCartaz(quando));
  });

  test('a different collection can wear a different class', () {
    // Guards the other half: a `classeDoCartaz` that ignored its argument
    // entirely (always returning `classesComArte.first`) would also pass the
    // determinism test above without ever actually reading the collection.
    final a = classeDoCartaz(DateTime.utc(2026, 8, 9));
    final b = classeDoCartaz(DateTime.utc(2026, 9, 30));

    expect(a, isNot(b));
  });

  test('no collection loaded yet opens on the first class', () {
    expect(classeDoCartaz(null), classesComArte.first);
  });

  test('every class in the rotation has vertical art', () {
    // The 2:3 crop for the tall cards, shipped 01/10/2026.
    for (final classe in classesComArte) {
      expect(arteVerticalDaClasse(classe), isNotNull, reason: classe);
      expect(arteVerticalDaClasse(classe), contains('classes-verticais'));
    }
  });

  test(
    'cada arte que uma classe declara existe em disco, nos dois tamanhos',
    () {
      // **O endereço é derivado, portanto um ficheiro em falta não é erro de
      // compilação — é uma caixa vazia na página.** `errorBuilder` engole o
      // 404 de propósito, para que uma classe sem arte desenhe o chão em vez
      // de uma caixa partida, e é exactamente isso que torna a falta
      // invisível: a mesma razão por que `paginas_html_test` passou a exigir
      // que toda a imagem que uma página pede exista em disco.
      //
      // Pega o caso que importa: as 480 foram movidas para a sua pasta e as
      // 960 chegaram com nomes `pw-01..17`. Um emparelhamento errado entre as
      // duas listas não se vê de outra forma.
      for (final classe in classesComArte) {
        for (final tamanho in TamanhoDaArte.values) {
          final caminho = arteVerticalDaClasse(classe, tamanho: tamanho)!;
          expect(
            File(caminho).existsSync(),
            isTrue,
            reason: '$classe em ${tamanho.largura}: falta $caminho',
          );
        }
      }
    },
  );

  test('cada tamanho tem a largura que o nome promete', () {
    // Um ficheiro de 480 guardado na pasta 960 serviria metade dos píxeis
    // sob um nome que promete o dobro — e nada na página diria, porque
    // `BoxFit.cover` estica o que lhe derem. O cabeçalho WebP é a prova.
    for (final classe in classesComArte) {
      for (final tamanho in TamanhoDaArte.values) {
        final caminho = arteVerticalDaClasse(classe, tamanho: tamanho)!;
        expect(
          _larguraWebp(File(caminho).readAsBytesSync()),
          tamanho.largura,
          reason: '$classe em ${tamanho.largura}',
        );
      }
    }
  });

  test('só o palco pede o tamanho grande, e ele é um só', () {
    // Servir 960 a todos custaria 600 KB a mais em cada abertura da home, e
    // seis dos sete ficheiros que a visita busca já recebem mais píxeis do
    // que desenham. Se um segundo chamador passar a pedir `cartaz`, que seja
    // uma decisão e não um descuido.
    //
    // **E foi decisão, a 09/11/2026.** O ficheiro mudou de `cartaz.dart`
    // para `palco_de_classe.dart` porque a raiz ganhou um herói e as duas
    // telas passaram a partilhar o dispositivo em vez de o copiar. O número
    // de chamadores não subiu: continua a ser **um**, e é esse o facto que
    // este teste guarda. Dois sítios a pedir 960 seria o descuido.
    final pedem = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f.readAsStringSync().contains('TamanhoDaArte.cartaz'))
        .map((f) => f.uri.pathSegments.last)
        .toList();

    expect(pedem, ['palco_de_classe.dart']);
  });

  test('a class nobody has art for draws nothing', () {
    // Silent, like ItemIcon's empty box. A hero with a missing image must
    // fall back to the plain ground, never to a broken box or somebody
    // else's face.
    expect(arteVerticalDaClasse('Necromante'), isNull);
  });
}
