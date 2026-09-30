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

/// The art for [classe], or `null` where none was ever supplied.
///
/// `null` draws the plain ground — the same silent fallback `ItemIcon` makes.
/// A hero showing somebody else's face would be worse than a hero showing no
/// face at all.
String? arteDaClasse(String classe) {
  final entrada = _classes[classe];
  return entrada == null
      ? null
      : 'assets/images/classes/${entrada.arquivo}.webp';
}

/// The accent the page wears while showing [classe].
Color acentoDaClasse(String classe) =>
    (_classes[classe]?.magenta ?? false) ? PWColors.magenta : PWColors.violeta;
