import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/pw_colors.dart';
import '../../search/ui/search_state.dart';
import '../../search/ui/search_view_model.dart';
import '../domain/tool.dart';
import 'widgets/market_pulse.dart';
import 'widgets/tool_card.dart';

/// The Portal's front page.
///
/// It loads the market index like the filter does, and for the same reason it
/// is worth the wait: the numbers on this page are the argument. "830 à venda,
/// 139 com arma de 70, o mais barato a 130 TCC" says what the site is for in a
/// way no tagline does — and it is only true because the index exists.
///
/// The cards do not wait for it. They are the menu, and a menu that appears a
/// second late is a page that looks broken.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  static const _wideEnough = 720.0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _wideEnough;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: ListView(
              // Shrink-wrapped so a short menu sits in the middle of the page
              // instead of clinging to the top with a screen of nothing under
              // it — and it still scrolls once the list outgrows the window.
              // The list is a handful of cards, so the cost is nil.
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 40 : 20,
                vertical: wide ? 56 : 32,
              ),
              children: [
                _Wordmark(wide: wide),
                SizedBox(height: wide ? 18 : 14),
                Text(
                  'Ferramentas para o mercado do The Classic PW 1.8.7.',
                  style: TextStyle(
                    color: PWColors.textMuted,
                    fontSize: wide ? 17 : 15,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: wide ? 36 : 26),
                BlocBuilder<SearchViewModel, SearchState>(
                  builder: (context, state) => MarketPulse(
                    state: state is SearchReady ? state : null,
                    wide: wide,
                  ),
                ),
                SizedBox(height: wide ? 40 : 30),
                for (final tool in tools) ...[
                  ToolCard(tool: tool, wide: wide),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 28),
                const _Footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: wide ? 46 : 38,
        height: wide ? 46 : 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PWColors.accent, width: 2),
        ),
        child: Icon(
          Icons.hexagon_outlined,
          size: wide ? 24 : 20,
          color: PWColors.accent,
        ),
      ),
      SizedBox(width: wide ? 16 : 12),
      Text(
        'PORTAL PW',
        style: TextStyle(
          fontSize: wide ? 38 : 28,
          fontWeight: FontWeight.w800,
          letterSpacing: wide ? 3 : 2,
          color: PWColors.text,
        ),
      ),
    ],
  );
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => const Text(
    'Projeto de fã, sem vínculo com o The Classic Games. Lê apenas páginas '
    'públicas do marketplace.',
    style: TextStyle(color: PWColors.textMuted, fontSize: 12, height: 1.5),
  );
}
