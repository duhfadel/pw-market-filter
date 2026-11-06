import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/widgets/game_icon.dart';
import '../../../../market/card_combos.dart';
import '../../../../market/slot_names.dart';
import '../../domain/combo_rebirth.dart';
import '../../domain/search_query.dart';
import '../search_state.dart';
import '../search_view_model.dart';
import 'section_header.dart';

/// Filters on the six War Avatar cards a character wears.
///
/// Two ways in, because the named combos are only as complete as a hand-written
/// table. `Combo` asks for a specific set; `Todas S` asks for six cards of a
/// rarity whatever the set is called, and that one keeps working for a combo
/// nobody has named yet.
class CardSection extends StatefulWidget {
  const CardSection({required this.state, required this.viewModel, super.key});

  final SearchReady state;
  final SearchViewModel viewModel;

  @override
  State<CardSection> createState() => _CardSectionState();
}

class _CardSectionState extends State<CardSection> {
  bool _open = false;

  SearchReady get state => widget.state;
  SearchViewModel get viewModel => widget.viewModel;

  /// How many of the three card conditions are in force. Same job as the count
  /// on a slot group: it is what lets the section be closed without hiding a
  /// filter that is quietly shaping the results.
  int get _active {
    final query = state.query;
    return (query.comboName != null ? 1 : 0) +
        (query.comboMinRebirth != null ? 1 : 0) +
        (query.cardRarity != null ? 1 : 0) +
        (query.cardsMaxed ? 1 : 0);
  }

  @override
  Widget build(BuildContext context) {
    final query = state.query;
    final anyCards = state.index.characters.any((c) => c.cards.isNotEmpty);
    // An index collected before cards existed has none. Offering the filter
    // then would return zero for everything, which reads like a broken market.
    if (!anyCards) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        if (_open) ...[
          const SizedBox(height: 10),
          _comboField(query.comboName),
          if (query.comboName != null) _renascimentos(query),
          const SizedBox(height: 10),
          _rarityField(query.cardRarity),
          CheckboxListTile(
            value: query.cardsMaxed,
            onChanged: (v) => viewModel.setCardsMaxed(v ?? false),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: PWColors.accent,
            checkColor: PWColors.background,
            title: const Text(
              'Todas no nível máximo',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }

  Widget _header() => InkWell(
    onTap: () => setState(() => _open = !_open),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SectionHeader(
        title: 'Cartas',
        emblem: cardsEmblem,
        badge: _active,
        expanded: _open,
      ),
    ),
  );

  Widget _comboField(String? value) {
    // How many characters wear each combo, so a filter that will return three
    // results says so before it is applied.
    // Counted over the characters that pass every other filter, so with
    // Guerreiro chosen the combo list says how many Guerreiros wear each — not
    // how many exist in the market.
    final scope = state.facetsFor(FacetDimension.cards).scope;
    final wearers = {
      for (final combo in cardCombos)
        combo.name: scope
            .where(
              (c) => c.cards
                  .map((card) => card.cardId)
                  .toSet()
                  .containsAll(combo.cardIds),
            )
            .length,
    };

    // The table is written by hand and the market is not, so a combo can be
    // real and have nobody selling it today — *Corona* had exactly one owner
    // and he delisted. The list therefore offers what the market has, which is
    // the rule every other control here already follows.
    final byName = {for (final combo in cardCombos) combo.name: combo};
    final offered = [
      for (final combo in cardCombos)
        if ((wearers[combo.name] ?? 0) > 0) combo.name,
    ];
    // Whatever is chosen stays on the list even when nobody wears it: a
    // month-old link names a combo this collection has none of, and a
    // DropdownButton whose value is absent from its own items throws. The same
    // guard the class and item lists carry, reached by a different door — and
    // a name from outside that no table knows still has to be removable.
    if (value != null && !offered.contains(value)) offered.insert(0, value);

    return DropdownButtonFormField<String?>(
      initialValue: value,
      isExpanded: true,
      itemHeight: 58,
      decoration: const InputDecoration(labelText: 'Combo completo'),
      dropdownColor: PWColors.surfaceRaised,
      selectedItemBuilder: (_) => [
        const Align(alignment: Alignment.centerLeft, child: Text('Qualquer')),
        for (final name in offered)
          Align(alignment: Alignment.centerLeft, child: Text(name)),
      ],
      items: [
        const DropdownMenuItem(value: null, child: Text('Qualquer')),
        for (final name in offered)
          DropdownMenuItem(
            value: name,
            child: _comboEntry(byName[name], name, wearers[name] ?? 0),
          ),
      ],
      onChanged: viewModel.setCombo,
    );
  }

  /// Quantos renascimentos cada carta do combo tem de ter.
  ///
  /// **Aparece só com um combo escolhido**, porque é dele que a pergunta
  /// fala: «renascidas 2» sem conjunto nomeado não é pergunta nenhuma, já
  /// que as seis cartas de alguém podem não formar combo algum.
  ///
  /// **O nível é o da pior carta das seis**, que é a regra que o dono
  /// descreveu nos mesmos termos do conjunto de pedras: quem tem quatro
  /// renascidas 2 e duas renascidas 1 aparece em *1+* e não em *2+*. E como
  /// é um mínimo, quem tem as seis em 2 também responde a *1+* — seria
  /// absurdo dizer a quem procura renascidas 1 que o combo melhor não serve.
  Widget _renascimentos(SearchQuery query) {
    final combo = cardCombos
        .where((c) => c.name == query.comboName)
        .firstOrNull;
    // Um nome vindo de um link antigo que nenhuma tabela conhece: não há
    // conjunto para medir renascimento nenhum, e o combo em si já tem saída
    // própria pelo chip de filtro activo.
    if (combo == null) return const SizedBox.shrink();

    // Contado no escopo que exclui as cartas, como todo o resto do painel:
    // senão escolher *2+* faria os outros chips contarem só dentro de quem já
    // tem 2+, e a volta para trás ficaria sem números.
    final niveis = <int>[];
    for (final c in state.facetsFor(FacetDimension.cards).scope) {
      final nivel = comboRebirthLevel(c, combo);
      if (nivel != null) niveis.add(nivel);
    }
    int quantos(int pedido) => niveis.where((n) => n >= pedido).length;

    // Um e dois são sempre oferecidos, porque são os dois degraus que o jogo
    // tem hoje e um chip apagado diz mais do que um chip ausente. Acima
    // disso, só o que o mercado mostrar — se um dia aparecer um 3, o controlo
    // cresce sozinho em vez de esconder o topo.
    final maximo = niveis.isEmpty
        ? 2
        : niveis.reduce((a, b) => a > b ? a : b).clamp(2, 9);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Renascimento das seis cartas — conta pela pior delas, então uma '
            'carta sem renascer deixa o combo fora.',
            style: TextStyle(color: PWColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chipDeRenascimento(
                rotulo: 'Sem exigir',
                nivel: null,
                escolhido: query.comboMinRebirth == null,
                vazio: false,
              ),
              for (var nivel = 1; nivel <= maximo; nivel++)
                _chipDeRenascimento(
                  rotulo: 'Renascidas $nivel+',
                  nivel: nivel,
                  escolhido: query.comboMinRebirth == nivel,
                  vazio: quantos(nivel) == 0,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipDeRenascimento({
    required String rotulo,
    required int? nivel,
    required bool escolhido,
    required bool vazio,
  }) => ChoiceChip(
    label: Text(
      rotulo,
      style: TextStyle(
        fontSize: 12,
        color: escolhido
            ? PWColors.background
            : vazio
            ? PWColors.textMuted
            : PWColors.text,
      ),
    ),
    selected: escolhido,
    // Um nível que ninguém tem fica apagado em vez de sumir — a ausência é
    // informação, e um chip que desaparece quando o escopo muda lê como erro.
    // É a mesma escolha dos conjuntos de pedras, e aqui ela ganha peso: até
    // à recolha que trouxe o campo, nenhum personagem tem renascimento
    // nenhum, portanto *todos* os chips nascem apagados e o painel explica-se
    // em vez de ficar vazio.
    onSelected: vazio && !escolhido
        ? null
        : (liga) => viewModel.setComboMinRebirth(liga ? nivel : null),
    selectedColor: PWColors.accent,
    backgroundColor: PWColors.surfaceRaised,
    showCheckmark: false,
  );

  /// One row of the combo list: the art of its first cards, the name, and what
  /// it costs in results.
  ///
  /// [combo] is null only for a name that came from outside and no table
  /// knows — then there is nothing true to draw beside it, so the row is the
  /// name alone rather than an invented picture.
  Widget _comboEntry(CardCombo? combo, String name, int wearers) {
    if (combo == null) return Text(name, overflow: TextOverflow.ellipsis);

    return Row(
      children: [
        for (final id in combo.cardIds.take(3)) ...[
          ItemIcon(id, size: 20),
          const SizedBox(width: 2),
        ],
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, overflow: TextOverflow.ellipsis),
              Text(
                '${combo.cardIds.length} cartas ${combo.rarity}'
                '  ·  $wearers personagens',
                style: const TextStyle(fontSize: 11, color: PWColors.ok),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rarityField(String? value) => DropdownButtonFormField<String?>(
    initialValue: value,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Raridade das seis'),
    dropdownColor: PWColors.surfaceRaised,
    items: const [
      DropdownMenuItem(value: null, child: Text('Qualquer')),
      DropdownMenuItem(value: 'S', child: Text('Todas S')),
      DropdownMenuItem(value: 'A', child: Text('Todas A')),
      DropdownMenuItem(value: 'B', child: Text('Todas B')),
    ],
    onChanged: viewModel.setCardRarity,
  );
}
