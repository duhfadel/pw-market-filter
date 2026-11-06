import 'package:flutter/material.dart';

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

/// Os dois tamanhos em que a arte vertical existe, em píxeis de largura.
///
/// **São duas pastas e uma regra de endereço, não duas listas de ficheiros.**
/// A classe é o facto; a pasta é escolhida por quem desenha, conforme a caixa
/// que vai preencher. É o mesmo arranjo do ícone de item, derivado do id, e é
/// por isso que acrescentar um terceiro tamanho não toca em [_classes].
enum TamanhoDaArte {
  /// Para cartões: os Destaques a seis colunas dão ~120 px cada, e as Portas
  /// menos ainda. Aqui 480 já é quatro vezes o que o ecrã mostra.
  cartao(480),

  /// Para o Cartaz, que é o único sítio que **amplia** a arte: a caixa é da
  /// largura da página por 360 px de altura, com `BoxFit.cover`, portanto numa
  /// página de 1280 px uma fonte de 480 é esticada 2,67× — 5,3× em `DPR 2`.
  /// Medido a 06/11/2026: as artes de 960 trazem **1,94×** mais energia de
  /// borda do que as de 480 ampliadas para o mesmo tamanho, o que as prova
  /// fonte verdadeira e não um upscale, que daria 1,00×.
  cartaz(960);

  const TamanhoDaArte(this.largura);

  final int largura;
}

/// The art for [classe] at the 2:3 crop, or `null` where none was ever
/// supplied.
///
/// `null` draws the plain ground — the same silent fallback `ItemIcon` makes.
/// A hero showing somebody else's face would be worse than a hero showing no
/// face at all.
///
/// **[tamanho] existe porque só um chamador amplia.** Servir 960 a todos
/// custaria 600 KB a mais em cada abertura da home — a visita busca sete
/// ficheiros, uma classe para o Cartaz e seis para os Destaques — e seis
/// desses sete já recebem mais píxeis do que desenham. O valor por omissão é
/// o do cartão, que é o caso comum.
///
/// This used to have a square 560 sibling, `arteDaClasse`, cropped to put the
/// face a fifth from the top for a half-width card. It was deleted on
/// 2026-10-01 once the Cartaz moved to this tall crop and nothing else ever
/// called the square one — kept alive only by its own test, which is the
/// inverse of the failure CLAUDE.md names when it says "a codec with no test
/// is where a field goes to die". `assets/images/classes/` went with it.
String? arteVerticalDaClasse(
  String classe, {
  TamanhoDaArte tamanho = TamanhoDaArte.cartao,
}) {
  final entrada = _classes[classe];
  return entrada == null
      ? null
      : 'assets/images/classes-verticais/${tamanho.largura}/'
            '${entrada.arquivo}.webp';
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

/// Which class the Cartaz wears for a collection made at [collectedAt].
///
/// Derived from the collection's own timestamp — never `Random()`, never the
/// wall clock. The same collection has to draw the same page, or a rebuild
/// reads as a slot machine instead of a site. `null` (no collection loaded
/// yet) opens on the first class of [classes] rather than waiting to show any
/// art at all.
///
/// [classes] defaults to [classesComArte], the 1.8.7 pool of seventeen. The
/// 1.2.6 home passes [classesClassicasPw126] instead — the smaller pool is
/// what keeps the hero honest about which game it is rotating through.
///
/// Lifted out of `home_view.dart` so a test can call it directly rather than
/// only through the assembled page — a regression to `DateTime.now()` here
/// would otherwise stay invisible to every widget test, since none of them
/// pump the same index twice in the same run.
String classeDoCartaz(
  DateTime? collectedAt, {
  List<String> classes = classesComArte,
}) {
  if (classes.isEmpty) return classesComArte.first;
  if (collectedAt == null) return classes.first;
  final posicao = collectedAt.millisecondsSinceEpoch % classes.length;
  return classes[posicao];
}
