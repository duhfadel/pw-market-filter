import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/domain/arte_da_classe.dart';

/// A pasta que as páginas estáticas da Saga do Herói servem.
///
/// Derivada e não a fonte: `tool/sagas/pagina.py` escreve-a a partir de
/// `assets/`, e o teste abaixo é o que impede as duas de divergirem.
const _copiaDaSaga = 'web/guias/saga-do-heroi/img';

void main() {
  test('toda a classe com arte tem recorte', () {
    // **O endereço é derivado da mesma tabela que a arte vertical**, portanto
    // um ficheiro em falta não é erro de compilação: o `errorBuilder` do card
    // engole o 404 e desenha o chão, que é o comportamento certo e é também o
    // que torna a falta invisível.
    for (final classe in classesComArte) {
      final caminho = recorteDaClasse(classe)!;
      expect(
        File(caminho).existsSync(),
        isTrue,
        reason: '$classe: falta $caminho',
      );
    }
  });

  test('uma classe que nunca existiu não inventa um ficheiro', () {
    expect(recorteDaClasse('Necromante'), isNull);
  });

  test('o recorte e a arte vertical são ficheiros diferentes', () {
    // São duas ilustrações e não a mesma com e sem fundo. As verticais são
    // cenas pintadas — os quatro cantos de cada uma discordam entre si até
    // 209 de 255 — e em quinze das dezassete o efeito do próprio personagem
    // *é* o fundo. Confundi-las levaria alguém a "arrumar" apagando uma.
    for (final classe in classesComArte) {
      expect(recorteDaClasse(classe), isNot(arteVerticalDaClasse(classe)));
    }
  });

  test('a cópia que as páginas da Saga servem é byte a byte a mesma', () {
    // **O mesmo ficheiro em dois sítios sem guarda é como a arte do Ceifador
    // se perdeu nas Sagas.** A casa é `assets/`; esta pasta é escrita por
    // `tool/sagas/pagina.py`. Sem este teste, substituir uma das duas deixa a
    // página e o card a mostrar artes diferentes da mesma classe, e nada o
    // diz — as duas carregam sem erro nenhum.
    for (final classe in classesComArte) {
      final casa = File(recorteDaClasse(classe)!);
      final copia = File('$_copiaDaSaga/${casa.uri.pathSegments.last}');

      expect(copia.existsSync(), isTrue, reason: '$classe: falta $copia');
      expect(
        copia.readAsBytesSync(),
        casa.readAsBytesSync(),
        reason: '$classe: a cópia da Saga divergiu de assets/',
      );
    }
  });
}
