import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/pw_colors.dart';
import '../domain/search_query.dart';
import 'search_state.dart';
import 'search_view_model.dart';
import 'widgets/character_card.dart';
import 'widgets/filter_panel.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  /// Below this the two columns do not both fit, and the filter moves into a
  /// drawer instead of squeezing the cards to nothing.
  static const _twoColumnWidth = 900.0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchViewModel, SearchState>(
      builder: (context, state) => switch (state) {
        SearchLoading() => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        SearchNoIndex(:final command) => _Message(
          icon: Icons.download_outlined,
          title: 'Nenhuma coleta ainda',
          body:
              'O índice do mercado é gerado fora do app. Rode o comando abaixo '
              'e recarregue — leva uns 40 minutos, e pode ser interrompido e '
              'retomado.',
          code: command,
        ),
        SearchUnreadable(:final field, :final detail) => _Message(
          icon: Icons.error_outline,
          title: 'O índice não pôde ser lido',
          body:
              'O campo "$field" veio fora do esperado: $detail\n\n'
              'Refaça a coleta. Se o erro voltar, o HTML do site provavelmente '
              'mudou — rode os testes do parser.',
          isError: true,
        ),
        SearchReady() => _Results(state: state),
      },
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.state});

  final SearchReady state;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<SearchViewModel>();
    final wide = MediaQuery.sizeOf(context).width >= SearchView._twoColumnWidth;

    final panel = FilterPanel(state: state, viewModel: viewModel);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: PWColors.surface,
        titleSpacing: wide ? null : 8,
        // On a phone the bar holds a menu button, the count and the ordering,
        // and something has to give. It is not the count: "830 de 830" is the
        // answer to the question the whole screen exists to ask, and it was
        // the part being ellipsized to "83…".
        title: Text(
          wide
              ? '${state.results.length} de ${state.total} personagens'
              : '${state.results.length} de ${state.total}',
          overflow: TextOverflow.ellipsis,
        ),
        titleTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: PWColors.text,
        ),
        actions: [
          if (!wide)
            Builder(
              builder: (context) => IconButton(
                onPressed: Scaffold.of(context).openDrawer,
                icon: const Icon(Icons.tune, size: 20),
                color: PWColors.text,
                tooltip: 'Filtros',
              ),
            ),
          _OrderPicker(state: state, viewModel: viewModel, compact: !wide),
          if (wide) ...[
            const SizedBox(width: 20),
            _CollectedAt(state: state),
          ],
          const SizedBox(width: 12),
        ],
        // The collection date matters too much to drop — a stale index looks
        // exactly like a fresh one — so on a phone it moves to its own line
        // instead of fighting for the bar.
        bottom: wide
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(30),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 16, bottom: 10),
                  alignment: Alignment.centerLeft,
                  child: _CollectedAt(state: state),
                ),
              ),
      ),
      // The back arrow owns the leading slot, so the drawer needs its own way
      // in — an icon on the right rather than the hamburger Scaffold would
      // otherwise put where the way home belongs.
      drawer: wide
          ? null
          : Drawer(
              backgroundColor: PWColors.background,
              child: SafeArea(child: panel),
            ),
      body: Row(
        children: [
          if (wide) ...[
            SizedBox(width: 340, child: panel),
            const VerticalDivider(width: 1),
          ],
          Expanded(child: _Grid(state: state)),
        ],
      ),
    );
  }
}

/// Cheapest first by default. Knowing who owns the weapon is half the answer;
/// which of them costs least is the other half.
class _OrderPicker extends StatelessWidget {
  const _OrderPicker({
    required this.state,
    required this.viewModel,
    this.compact = false,
  });

  final SearchReady state;
  final SearchViewModel viewModel;

  /// On a phone the label is dropped and only the icon remains: the ordering
  /// is worth one tap to check, and the count is worth more than it is.
  final bool compact;

  @override
  Widget build(BuildContext context) => DropdownButtonHideUnderline(
    child: DropdownButton<ResultOrder>(
      value: state.query.order,
      selectedItemBuilder: compact
          ? (_) => [for (final _ in ResultOrder.values) const SizedBox.shrink()]
          : null,
      dropdownColor: PWColors.surfaceRaised,
      borderRadius: BorderRadius.circular(8),
      style: const TextStyle(color: PWColors.text, fontSize: 13),
      icon: const Icon(Icons.sort, size: 18, color: PWColors.textMuted),
      items: [
        for (final order in ResultOrder.values)
          DropdownMenuItem(value: order, child: Text(order.label)),
      ],
      onChanged: (order) {
        if (order != null) viewModel.setOrder(order);
      },
    ),
  );
}

class _CollectedAt extends StatelessWidget {
  const _CollectedAt({required this.state});

  final SearchReady state;

  @override
  Widget build(BuildContext context) {
    final stale = state.isStale(DateTime.now().toUtc());
    final date = state.index.collectedAt.toLocal();
    final text =
        'coletado em ${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Row(
      children: [
        if (stale) ...[
          const Icon(Icons.schedule, size: 15, color: PWColors.danger),
          const SizedBox(width: 6),
        ],
        Text(
          stale ? '$text — desatualizado' : text,
          style: TextStyle(
            fontSize: 12,
            color: stale ? PWColors.danger : PWColors.textMuted,
            fontWeight: stale ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.state});

  final SearchReady state;

  /// Name, price and the stat line, plus one block per criterion: the item's
  /// name and the slot-attribute line beneath it.
  static const _headerHeight = 78.0;
  static const _matchLineHeight = 42.0;
  static const _dividerHeight = 21.0;

  /// One block per **item** the card will name, not per condition asked.
  ///
  /// Conditions that land on the same piece — a weapon chosen from the
  /// dropdown and a criterion on the weapon slot — share one block, so
  /// counting conditions reserves room for a line that never appears. Two
  /// conditions naming the same slot are therefore counted once here.
  ///
  /// A criterion with no slot can also collapse into an existing block, but
  /// only for characters where it happens to land on the same piece. It counts
  /// as its own block, which can leave a little air at the bottom of a card —
  /// the safe direction, since the alternative clips the line off.
  double get _cardHeight {
    final slots = <int>{...state.query.itemBySlot.keys};
    var anySlotCriteria = 0;
    for (final criterion in state.query.criteria) {
      if (criterion.slot == null) {
        anySlotCriteria++;
      } else {
        slots.add(criterion.slot!);
      }
    }

    final blocks = slots.length + anySlotCriteria;
    if (blocks == 0) return _headerHeight;
    return _headerHeight + _dividerHeight + blocks * _matchLineHeight;
  }

  @override
  Widget build(BuildContext context) {
    if (state.results.isEmpty) return const _NoMatches();

    // Two columns on a 390 px phone leaves 179 px a card, which truncates the
    // nickname and wraps the stat line onto a third row. One column reads.
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 600;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: narrow ? double.infinity : 300,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        // The grid needs one height for every tile, and the card cannot ask
        // for its own — so the height follows the criteria in force. Fixing it
        // at the tallest case leaves a card with no matched items sitting in a
        // block of empty space three times its content.
        mainAxisExtent: _cardHeight,
      ),
      itemCount: state.results.length,
      itemBuilder: (context, i) => CharacterCard(
        character: state.results[i],
        index: state.index,
        query: state.query,
      ),
    );
  }
}

/// Matching nobody is an answer, and often the valuable one. It gets no error
/// colour and no warning icon.
class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 40, color: PWColors.textMuted),
          SizedBox(height: 14),
          Text(
            'Ninguém no mercado atende a esses critérios.',
            style: TextStyle(color: PWColors.text, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          Text(
            'Baixe algum mínimo, ou tire um critério.',
            style: TextStyle(color: PWColors.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.code,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? code;
  final bool isError;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 34,
                color: isError ? PWColors.danger : PWColors.accent,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                body,
                style: const TextStyle(
                  color: PWColors.textMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (code != null) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: PWColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PWColors.border),
                  ),
                  child: SelectableText(
                    code!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: PWColors.accent,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
