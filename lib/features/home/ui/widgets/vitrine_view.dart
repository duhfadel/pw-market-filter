import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/theme/pw_theme.dart';
import '../../../../market/market_index.dart';
import '../../../../market/slot_names.dart';
import '../../domain/arte_da_classe.dart';
import '../../domain/vitrine.dart';

/// One weapon, read off [character]'s worn gear rather than off a class name.
///
/// The site's own trap — three weapons share a word and give 30, 40 and 70 —
/// applies here exactly as it does on the results card, so the label is built
/// the same way: the item's real name plus the number that decides its
/// price, never the name alone.
({int itemId, String nome, String detalhe})? _armaDe(
  MarketIndex index,
  MarketCharacter character,
) {
  final idAtaque = index.attributes.indexOf('Nível de Ataque');
  final idDefesa = index.attributes.indexOf('Nível de Defesa');

  for (final item in character.equipped) {
    if (item.slot != weaponSlot) continue;

    final nome = index.items[item.itemId]?.name ?? 'item ${item.itemId}';
    final ataque = idAtaque < 0 ? null : item.attributes[idAtaque];
    final defesa = idDefesa < 0 ? null : item.attributes[idDefesa];

    // The rare card carries the defensive tier, not the attack one, so
    // whichever attribute is actually present on the weapon wins — never a
    // fixed choice of "always Nível de Ataque".
    if (defesa != null && (ataque == null || defesa > ataque)) {
      return (
        itemId: item.itemId,
        nome: nome,
        detalhe: '+$defesa Nível de Defesa',
      );
    }
    if (ataque != null) {
      return (
        itemId: item.itemId,
        nome: nome,
        detalhe: '+$ataque Nível de Ataque',
      );
    }
    return (itemId: item.itemId, nome: nome, detalhe: '');
  }
  return null;
}

/// The front page's argument, made of three real people rather than a
/// sentence: the cheapest and the dearest wearing the same weapon, and —
/// when the market has one — somebody paying the same top tier in the other
/// currency.
///
/// Draws nothing when [vitrineDe] answers `null`: a market with fewer than
/// two carriers of the tier has no comparison to make, and printing a
/// heading over an empty row would be a claim with nothing behind it.
class VitrineView extends StatelessWidget {
  const VitrineView({
    required this.index,
    required this.wide,
    required this.aoTocar,
    super.key,
  });

  final MarketIndex index;

  /// Whether the page has room for the wide layout.
  final bool wide;

  /// Called with the character behind whichever card was tapped.
  final void Function(MarketCharacter) aoTocar;

  @override
  Widget build(BuildContext context) {
    final v = vitrineDe(index);
    if (v == null) return const SizedBox.shrink();

    // Computed, never written down: a hardcoded "60×" would be a lie the day
    // the market moves, which is every fifteen minutes.
    final mult = v.caro.price ~/ v.barato.price;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: wide ? 56 : 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'A mesma arma de 70',
            style: TextStyle(
              fontFamily: PWTheme.display,
              fontSize: wide ? 26 : 21,
              color: PWColors.papel,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            // Barato and caro are, by construction, exactly two carriers of
            // this weapon — never a guess, never the whole market's count,
            // which vitrineDe does not hand back.
            'Dois personagens escolheram a mesma arma de nível 70 — do mais '
            'barato ao mais caro, $mult× o preço.',
            style: const TextStyle(color: PWColors.apagado, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _Carta(
                  index: index,
                  character: v.barato,
                  rotulo: 'O MAIS BARATO',
                  aoTocar: aoTocar,
                ),
              ),
              _Multiplicador(mult: mult),
              Expanded(
                child: _Carta(
                  index: index,
                  character: v.caro,
                  rotulo: 'O MAIS CARO',
                  aoTocar: aoTocar,
                ),
              ),
              if (v.raro != null) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _Carta(
                    index: index,
                    character: v.raro!,
                    rotulo: 'O MAIS RARO',
                    aoTocar: aoTocar,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// The narrow column between the cheapest and the dearest card: a hairline,
/// the multiple in [PWColors.magenta], and another hairline.
class _Multiplicador extends StatelessWidget {
  const _Multiplicador({required this.mult});

  final int mult;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Hairline(),
          const SizedBox(height: 6),
          Text(
            '$mult×',
            style: const TextStyle(
              color: PWColors.magenta,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          const _Hairline(),
        ],
      ),
    ),
  );
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, width: 28, color: PWColors.filete);
}

/// One card: the class's own art fading into the panel, a corner label
/// naming the reason this person is here, then who they are and what they
/// wear.
class _Carta extends StatelessWidget {
  const _Carta({
    required this.index,
    required this.character,
    required this.rotulo,
    required this.aoTocar,
  });

  final MarketIndex index;
  final MarketCharacter character;
  final String rotulo;
  final void Function(MarketCharacter) aoTocar;

  @override
  Widget build(BuildContext context) {
    final arma = _armaDe(index, character);

    return Material(
      color: PWColors.painel,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => aoTocar(character),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Retrato(classe: character.characterClass, rotulo: rotulo),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    character.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'nv ${character.level} · ${character.characterClass}',
                    style: const TextStyle(
                      color: PWColors.textMuted,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (arma != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      arma.detalhe.isEmpty
                          ? arma.nome
                          : '${arma.nome} · ${arma.detalhe}',
                      style: const TextStyle(color: PWColors.ok, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${character.price} TCC',
                    style: const TextStyle(
                      color: PWColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The top of a card: the class's own portrait, cropped where the faces sit
/// and faded into [PWColors.painel] so the text below reads over solid
/// ground rather than over art.
class _Retrato extends StatelessWidget {
  const _Retrato({required this.classe, required this.rotulo});

  final String classe;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final arte = arteDaClasse(classe);

    return SizedBox(
      height: 90,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // A missing file leaves the plain panel rather than a broken box —
          // the same silent fallback `arteDaClasse` itself makes.
          if (arte != null)
            Image.asset(
              arte,
              fit: BoxFit.cover,
              // Not the centre: the class arts carry their faces about a
              // fifth of the way down, the same crop `Cartaz` uses.
              alignment: const Alignment(0, -0.6),
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [PWColors.painel.withValues(alpha: 0), PWColors.painel],
                stops: const [0.35, 1],
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: PWColors.noite.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                rotulo,
                style: const TextStyle(
                  color: PWColors.papel,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
