import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/pw_colors.dart';
import '../../search/ui/search_state.dart';
import '../../search/ui/search_view_model.dart';
import '../domain/tool.dart';
import 'widgets/market_pulse.dart';
import 'widgets/tool_card.dart';

/// The Portal's front page: the mark, what the place is, live numbers, and the
/// menu.
///
/// It loads the market index like the filter does, and for the same reason it
/// is worth the wait: the numbers here are the argument. "830 à venda, 205 com
/// arma de 70, o mais barato a 120 TCC" says what the site is for in a way no
/// tagline does — and it is only true because the index exists.
///
/// The cards do not wait for it. They are the menu, and a menu that appears a
/// second late is a page that looks broken.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  /// Below this the grid becomes a column.
  static const _twoColumnWidth = 680.0;

  /// Above this the page is not competing for space, and holding the layout at
  /// its tablet size leaves the mark reading as a small card adrift in black —
  /// on a 1920 monitor the logo was 18% of the width. Everything grows a step.
  static const _largeWidth = 1280.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= _twoColumnWidth;
    final large = width >= _largeWidth;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: large ? 900 : 780),
            child: ListView(
              // Shrink-wrapped so a short menu sits in the middle of the page
              // instead of clinging to the top with a screen of nothing under
              // it — and it still scrolls once the list outgrows the window.
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 40 : 20,
                vertical: wide ? 44 : 28,
              ),
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/portal-pw-logo.webp',
                    width: large ? 440 : (wide ? 340 : 260),
                    filterQuality: FilterQuality.medium,
                    // The logo is the one asset whose absence would be
                    // baffling rather than cosmetic, so it falls back to the
                    // name rather than to a gap.
                    errorBuilder: (_, _, _) => Text(
                      'PORTAL PW',
                      style: TextStyle(
                        fontSize: wide ? 34 : 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: wide ? 6 : 4),
                Center(
                  child: Text(
                    'Ferramentas para o mercado do The Classic PW 1.8.7',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: PWColors.textMuted,
                      fontSize: large ? 17 : (wide ? 15 : 13),
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: large ? 34 : (wide ? 26 : 20)),
                BlocBuilder<SearchViewModel, SearchState>(
                  builder: (context, state) => MarketPulse(
                    state: state is SearchReady ? state : null,
                    wide: wide,
                    large: large,
                  ),
                ),
                SizedBox(height: large ? 38 : (wide ? 30 : 22)),
                _Menu(wide: wide),
                SizedBox(height: wide ? 28 : 22),
                const _Footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two per row when there is room, one when there is not.
///
/// A grid rather than a list because the menu is meant to be scanned, not read:
/// four tools side by side answer "what is here?" in one glance, where four
/// full-width rows answer it in four.
class _Menu extends StatelessWidget {
  const _Menu({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return Column(
        children: [
          for (final tool in tools)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ToolCard(tool: tool, wide: false),
            ),
        ],
      );
    }

    return Column(
      children: [
        for (var i = 0; i < tools.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            // `stretch` needs a bounded height to stretch to, and inside a
            // shrink-wrapped list there is none: the cards were handed an
            // infinite height and stopped painting their own background.
            // IntrinsicHeight measures the taller card first, which is also
            // what makes a pair line up when their taglines differ in length.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: ToolCard(tool: tools[i], wide: true)),
                  const SizedBox(width: 14),
                  // An odd number of tools leaves a hole rather than a card
                  // stretched to twice the width of its neighbours.
                  Expanded(
                    child: i + 1 < tools.length
                        ? ToolCard(tool: tools[i + 1], wide: true)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => const Text(
    'Projeto de fã, sem vínculo com o The Classic Games. Lê apenas páginas '
    'públicas do marketplace.',
    textAlign: TextAlign.center,
    style: TextStyle(color: PWColors.textMuted, fontSize: 12, height: 1.5),
  );
}
