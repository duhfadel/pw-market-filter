import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/pw_colors.dart';
import '../../../market/slot_names.dart';
import '../domain/search_query.dart';
import 'search_state.dart';
import 'search_view_model.dart';
import 'widgets/character_card.dart';
import 'widgets/filter_panel.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key, this.arriving});

  /// The search the address bar arrived with, if any.
  ///
  /// It is asked for once, on the way in, and never again: after that the form
  /// owns the query, and re-applying this on every rebuild would undo the
  /// visitor's next click.
  final SearchQuery? arriving;

  /// Below this the two columns do not both fit, and the filter moves into a
  /// drawer instead of squeezing the cards to nothing.
  static const _twoColumnWidth = 900.0;

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  @override
  void initState() {
    super.initState();

    final arriving = widget.arriving;
    if (arriving != null && !arriving.isEmpty) {
      context.read<SearchViewModel>().request(arriving);
    }
  }

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
        // Taller than the default 56 only where the mark is shown. At 30 px
        // the logo is a dark smudge — it is a wordmark over an ornate globe
        // and it needs height before it is anything at all. Twelve pixels of
        // chrome is what it costs to have it legible.
        toolbarHeight: wide ? 68 : null,
        titleSpacing: wide ? null : 8,
        // Declared, never implied. `automaticallyImplyLeading` gives the
        // drawer's hamburger priority over the back arrow, so on a phone —
        // where the filter lives in a drawer — the way home silently vanished
        // and the drawer had two entrances instead of one. The comment that
        // used to sit here claimed the opposite.
        leading: _HomeButton(wide: wide),
        leadingWidth: wide ? null : 44,
        title: Row(
          children: [
            // Desktop only, and it is not about space. Tried at 26 px on a
            // phone and it came out a red smudge — the third time this logo
            // has been asked to work small and the third time it refused. It
            // is a wordmark over an ornate globe; below about 40 px there is
            // nothing left to read. The arrow beside it is the part that had
            // to be on every width, and it is.
            if (wide) ...[
              const _HomeMark(height: 46),
              const SizedBox(width: 14),
            ],
            // On a phone the bar holds the way home, the mark, the count, the
            // ordering and the filters, and something has to give. It is not
            // the count: "830 de 830" is the answer to the question the whole
            // screen exists to ask, and it was the part being ellipsized to
            // "83…". So the word "personagens" is what goes.
            Flexible(
              child: Text(
                wide
                    ? '${state.results.length} de ${state.total} personagens'
                    : '${state.results.length} de ${state.total}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
          if (wide) ...[const SizedBox(width: 20), _CollectedAt(state: state)],
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
      // The filters open from the icon in `actions`, not from a hamburger in
      // the leading slot — that slot is the way home.
      drawer: wide
          ? null
          : Drawer(
              backgroundColor: PWColors.background,
              child: SafeArea(child: panel),
            ),
      body: Column(
        children: [
          const _Disclaimer(),
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                if (wide) ...[
                  SizedBox(width: 340, child: panel),
                  const VerticalDivider(width: 1),
                ],
                Expanded(child: _Grid(state: state)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Says what this screen is, and what it is not.
///
/// The screen shows other people's characters with prices next to them, which
/// is exactly what a shop looks like. Somebody arriving from a search has no
/// way to tell that this is a reader over a marketplace someone else runs, and
/// the honest reading of a price list is "these are for sale here". So it is
/// stated on the screen itself rather than in a footer nobody scrolls to.
///
/// It sits above the filter and the results, on both layouts, and it stays —
/// a notice that can be dismissed is a notice most visitors never see.
class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: PWColors.surface,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 15, color: PWColors.textMuted),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Não somos donos do marketplace e não vendemos nada. Este é um '
            'projeto de fã: só lemos as páginas públicas para facilitar a '
            'busca e ajudar a comunidade.',
            style: TextStyle(
              color: PWColors.textMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

/// The way back to the front page, and the only one this screen has.
///
/// It pops when there is something to pop, and goes home when there is not —
/// which is the case that matters, because a link shared in the game's chat
/// opens straight into the filter with an empty history. Popping nothing would
/// leave the visitor stuck, and "stuck" on a page with no way out is how a
/// visitor stops being one.
class _HomeButton extends StatelessWidget {
  const _HomeButton({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    color: PWColors.text,
    iconSize: wide ? 24 : 20,
    tooltip: 'Voltar ao Portal',
    onPressed: () {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        navigator.pushNamedAndRemoveUntil('/', (route) => false);
      }
    },
  );
}

/// The Portal's mark in the filter's bar, clickable like every logo is.
///
/// It is small — the logo is a wordmark over an ornate globe and an app bar
/// has no height to give — so it is not carrying the branding on its own. What
/// it does is say which site this screen belongs to, which a bare count and an
/// arrow do not.
class _HomeMark extends StatelessWidget {
  const _HomeMark({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () =>
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false),
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Image.asset(
        'assets/images/portal-pw-logo.webp',
        height: height,
        filterQuality: FilterQuality.medium,
        // The bar must not break over a missing file, and the arrow beside it
        // already answers "how do I leave".
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    ),
  );
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
    // Local time, so the hour reads as the visitor's own clock. The index
    // stores UTC because the collection runs on a machine that knows no other
    // timezone.
    final date = state.index.collectedAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    // The hour matters as much as the day. Prices move through the afternoon,
    // and "collected today" covers everything from a minute ago to twenty-three
    // hours ago — which is the difference between a live price and a guess.
    final text =
        'coletado em ${two(date.day)}/${two(date.month)}/${date.year} '
        'às ${two(date.hour)}:${two(date.minute)}';

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
    // The weapon is always drawn, asked about or not, so its block is always
    // reserved. When the query does pick a weapon it is the same block — which
    // is exactly why this is a set and not a count.
    final slots = <int>{weaponSlot, ...state.query.itemBySlot.keys};
    var anySlotCriteria = 0;
    for (final criterion in state.query.criteria) {
      if (criterion.slot == null) {
        anySlotCriteria++;
      } else {
        slots.add(criterion.slot!);
      }
    }

    final blocks = slots.length + anySlotCriteria;
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
