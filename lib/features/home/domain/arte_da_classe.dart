import 'package:flutter/material.dart';

import '../../../core/rotas.dart' as rotas;

import '../../../core/theme/pw_colors.dart';

/// The seventeen classes the market lists, mapped to the art that stands for
/// each and to the accent the page wears while showing it.
///
/// **The file names carry no accents and the class names do.** The index says
/// `Bárbaro` and `Místico`; the files are `barbaro.webp` and `mistico.webp`,
/// because a filename with an accent is a filename somebody eventually
/// mistypes — and the art arrives from a person, by hand, one file at a time.
///
/// The accent is **always one of two**, never [PWColors.accent]: gold is the
/// money colour, and an accent borrowing it breaks the page's one rule on the
/// screen where it is most visible. Each class is paired with whichever of the
/// two sits with its art; a class nobody has mapped falls back to violet
/// rather than guessing.
const _classes = <String, ({String arquivo, bool magenta})>{
  'Andarilho': (arquivo: 'andarilho', magenta: false),
  'Arcano': (arquivo: 'arcano', magenta: false),
  'Arqueiro': (arquivo: 'arqueiro', magenta: false),
  'Atiradora': (arquivo: 'atiradora', magenta: true),
  'Bárbaro': (arquivo: 'barbaro', magenta: false),
  'Bardo': (arquivo: 'bardo', magenta: false),
  'Ceifador': (arquivo: 'ceifador', magenta: true),
  'Espiritualista': (arquivo: 'espiritualista', magenta: true),
  'Feiticeira': (arquivo: 'feiticeira', magenta: true),
  'Guerreiro': (arquivo: 'guerreiro', magenta: true),
  'Mago': (arquivo: 'mago', magenta: true),
  'Mercenário': (arquivo: 'mercenario', magenta: false),
  'Místico': (arquivo: 'mistico', magenta: true),
  'Paladino': (arquivo: 'paladino', magenta: false),
  'Retalhador': (arquivo: 'retalhador', magenta: false),
  'Sacerdote': (arquivo: 'sacerdote', magenta: false),
  'Tormentador': (arquivo: 'tormentador', magenta: true),
};

/// Every class that has a file, in the order the map declares them.
const classesComArte = [
  'Andarilho',
  'Arcano',
  'Arqueiro',
  'Atiradora',
  'Bárbaro',
  'Bardo',
  'Ceifador',
  'Espiritualista',
  'Feiticeira',
  'Guerreiro',
  'Mago',
  'Mercenário',
  'Místico',
  'Paladino',
  'Retalhador',
  'Sacerdote',
  'Tormentador',
];

/// A largura em que a arte vertical existe, em píxeis.
///
/// **Era um par — 480 para cartões, 960 para o Cartaz — e os 480 saíram a
/// 10/11/2026, por decisão do dono.** Ficaram sem chamador quando os
/// Destaques passaram a desenhar [recorteDaClasse] sobre o degradê do
/// patamar, e eram 906 KB de ficheiros que a app não desenhava.
///
/// **Não se perdeu arte: eram a mesma cena, em metade do tamanho.** Medido
/// antes de apagar — reduzindo cada 960 para 480 e comparando píxel a píxel,
/// a diferença média é de **5,2 em 255**, com o pior caso no espiritualista
/// a 9,5. Isso é compressão, não um desenho diferente. Se um cartão voltar a
/// querer a cena pintada em pequeno, sai daqui com um `cwebp` e sem rede.
///
/// Fica como constante e não como enum de um valor só: o número é o que o
/// `arte_da_classe_test` lê do cabeçalho WebP de cada ficheiro, para que um
/// 480 guardado nesta pasta não sirva metade dos píxeis sob um nome que
/// promete o dobro.
const larguraDaArteVertical = 960;

/// The art for [classe] at the 2:3 crop, or `null` where none was ever
/// supplied.
///
/// `null` draws the plain ground — the same silent fallback `ItemIcon` makes.
/// A hero showing somebody else's face would be worse than a hero showing no
/// face at all.
///
/// **Um tamanho só, e um chamador só.** O [PalcoDeClasse] é quem a desenha —
/// no Cartaz e no herói da raiz — e é o único sítio do site que **amplia** a
/// arte: a caixa é da largura da página, portanto numa página de 1280 px uma
/// fonte de 480 seria esticada 2,67×, e 5,3× em `DPR 2`. É por isso que os
/// 960 ficaram e os 480 saíram, e não ao contrário.
///
/// This used to have a square 560 sibling, `arteDaClasse`, cropped to put the
/// face a fifth from the top for a half-width card. It was deleted on
/// 2026-10-01 once the Cartaz moved to this tall crop and nothing else ever
/// called the square one — kept alive only by its own test, which is the
/// inverse of the failure CLAUDE.md names when it says "a codec with no test
/// is where a field goes to die". `assets/images/classes/` went with it, and
/// `classes-verticais/480/` followed it a month later, for the same reason.
String? arteVerticalDaClasse(String classe) {
  final entrada = _classes[classe];
  return entrada == null
      ? null
      : 'assets/images/classes-verticais/$larguraDaArteVertical/'
            '${entrada.arquivo}.webp';
}

/// A capa: as dezassete artes de classe numa só imagem, de pé.
///
/// **Existe porque o herói deitava a arte e isso amolecia o rosto.** Uma cena
/// 960×1440 a cobrir uma faixa da largura da página é esticada *pela largura*
/// — 1,48× a 1420 e 2× a 1920, o que em píxeis de ecrã retina são 2,96× e 4×.
/// Não há arte maior publicada: procurou-se no oficial brasileiro (952×880,
/// menos do que já temos), no oficial chinês (outra arte, 800 px) e no site do
/// servidor (ícones de 36×36).
///
/// De pé, a mesma arte enche os 1520 px de altura da faixa a **1,06×**.
/// Dezassete lado a lado enchem a largura sem que nenhuma seja esticada — a
/// nitidez vem de usar a arte na orientação em que foi pintada.
///
/// Escrita por `tool/artes/capa.py`, que guarda o porquê de cada número.
const capaDasClasses = 'assets/images/capa-classes.webp';

/// O recorte da arte de [classe] — a figura sem fundo nenhum.
///
/// **É outra ilustração, e não a vertical sem fundo.** As verticais são cenas
/// pintadas: não têm canal alfa, os quatro cantos de cada uma discordam entre
/// si até 209 de 255, e em quinze das dezassete o efeito do próprio
/// personagem **é** o fundo — o gelo que envolve o Bardo, o fogo em volta da
/// Feiticeira. Ali «só o personagem» não tem fronteira definida, e qualquer
/// recorte ou come a magia dele ou traz um pedaço de céu junto. Estes vieram
/// recortados de origem, do marketplace deles, com 51% a 81% de transparência.
///
/// **Um endereço derivado da mesma tabela**, pela razão que
/// [arteVerticalDaClasse] já carrega: uma segunda lista de ficheiros é uma
/// segunda lista para divergir. Um tamanho só, 560 px: o maior cartão que o
/// desenha tem 330, pelo que ninguém o amplia, e um segundo tamanho seria
/// pagar píxeis que ninguém vê.
///
/// `null` para uma classe que nunca existiu, como a arte vertical: o chão
/// liso, nunca a cara de outra pessoa.
String? recorteDaClasse(String classe) {
  final entrada = _classes[classe];
  return entrada == null
      ? null
      : 'assets/images/classes-recorte/${entrada.arquivo}.webp';
}

/// The accent the page wears while showing [classe].
Color acentoDaClasse(String classe) =>
    (_classes[classe]?.magenta ?? false) ? PWColors.magenta : PWColors.violeta;

/// The 1.2.6 marketplace's own six classes — the classic ones, in the same
/// order [classesComArte] already lists them.
///
/// **Measured, not guessed: all six were checked one by one against
/// `assets/images/classes-verticais/` on 01/10/2026, and no new art was
/// needed.** [classeDoCartaz] takes this as its rotation pool for the 1.2.6
/// home, because rotating through the full seventeen there would eventually
/// land on a class — Andarilho, say — that game does not have, which is a
/// small lie told by the hero of the very page that introduces it.
const classesClassicasPw126 = [
  'Arqueiro',
  'Bárbaro',
  'Feiticeira',
  'Guerreiro',
  'Mago',
  'Sacerdote',
];

/// Que classe o Cartaz veste em cada mercado.
///
/// **Fixa por versão desde 10/11/2026, e era sorteada pela data da coleta.**
/// O argumento antigo era bom — duas visitas não abriam a mesma página — e o
/// dono trocou-o pelo mesmo que já tinha decidido para o herói da raiz: *«usa
/// a mesma imagem»*. Uma tela de mercado tem a cara dela, e quem volta
/// reconhece-a.
///
/// O que se perde é a rotação; o que se ganha é cada mercado passar a ser
/// reconhecível pela arte. E some junto a classe de pergunta que a rotação
/// obrigava a fazer — se a coleta muda a cara, um `--rebuild` muda a página
/// sem nada ter mudado no mercado.
///
/// **A escolha respeita o que cada jogo tem.** O 1.2.6 só tem as seis
/// clássicas, portanto leva o Guerreiro; pôr-lhe um Andarilho seria o herói
/// da página a prometer uma classe que aquele servidor não serve. Ver
/// [classesClassicasPw126].
///
/// Uma versão sem linha aqui cai no Guerreiro, que existe nas três — nunca
/// numa classe que possa não existir no mercado que a página apresenta.
String classeDoCartaz(String versao) => switch (versao) {
  rotas.pw187 => 'Andarilho',
  rotas.pw126 => 'Guerreiro',
  rotas.pw144 => 'Mercenário',
  _ => 'Guerreiro',
};
