import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/pw_colors.dart';
import '../../../core/theme/pw_theme.dart';
import '../../ads/ad_slot.dart';
import '../../home/domain/community.dart';
import 'registros_state.dart';
import 'registros_view_model.dart';
import 'widgets/atributo_filtros.dart';
import 'widgets/plano_resumo.dart';
import 'widgets/registro_panel.dart';
import 'widgets/slot_grid.dart';

/// The NPC's *Fabricar* window, on the web.
///
/// The game trades Páginas de Registro: Assimilação for permanent stats, and
/// hides everything that matters about the trade: thirty-two identical icons
/// per tab, the stats living on titles the window never sums, and a cost that
/// runs from one page to a hundred with no relation to the reward. The best
/// trade in the table gives 118 points a page and the worst gives 0,9.
class RegistrosView extends StatelessWidget {
  const RegistrosView({super.key});

  /// Below this the slots get tighter — but never fewer. Eight columns is the
  /// game's window, and matching it is the point.
  static const _telaEstreita = 620.0;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<RegistrosViewModel>()..load(),
    child: const _Tela(),
  );
}

class _Tela extends StatelessWidget {
  const _Tela();

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final compacto = largura < RegistrosView._telaEstreita;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registros de Assimilação',
          style: TextStyle(fontFamily: PWTheme.display, fontSize: 19),
        ),
      ),
      body: BlocBuilder<RegistrosViewModel, RegistrosState>(
        builder: (context, state) => switch (state) {
          RegistrosLoading() => const Center(
            child: CircularProgressIndicator(color: PWColors.accent),
          ),
          RegistrosUnreadable(:final detail) => _Falha(detail: detail),
          RegistrosReady() => _Pronto(state: state, compacto: compacto),
        },
      ),
    );
  }
}

class _Falha extends StatelessWidget {
  const _Falha({required this.detail});

  final String detail;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 40,
            color: PWColors.textMuted,
          ),
          const SizedBox(height: 14),
          Text(
            'Não deu para carregar os registros — $detail.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: PWColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tente de novo em alguns minutos.',
            style: TextStyle(color: PWColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}

class _Pronto extends StatelessWidget {
  const _Pronto({required this.state, required this.compacto});

  final RegistrosReady state;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<RegistrosViewModel>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            compacto ? 10 : 16,
            8,
            compacto ? 10 : 16,
            28,
          ),
          children: [
            const _Explicacao(),
            const SizedBox(height: 18),
            _Abas(state: state, aoTrocar: vm.abrirAba),
            const SizedBox(height: 16),
            AtributoFiltros(
              query: state.query,
              disponiveis: state.disponiveis,
              acesos: state.acesos,
              total: state.daAba.length,
              aoAlternar: vm.alternarAtributo,
              aoLimpar: vm.limparAtributos,
            ),
            const SizedBox(height: 16),
            SlotGrid(
              slots: state.grade,
              query: state.query,
              selecionado: state.selecionado,
              marcados: state.marcados,
              aoTocar: vm.selecionar,
              compacto: compacto,
            ),
            const SizedBox(height: 16),
            RegistroPanel(
              registro: state.selecionado,
              marcado:
                  state.selecionado != null &&
                  state.marcados.contains(state.selecionado!.chave),
              aoMarcar: () {
                final escolhido = state.selecionado;
                if (escolhido != null) vm.alternarMarca(escolhido);
              },
            ),
            const SizedBox(height: 14),
            PlanoResumo(
              plano: state.plano,
              temQueMarcar: state.temQueMarcar,
              aoMarcarAba: vm.marcarAba,
              aoLimpar: vm.limparMarcas,
            ),
            const SizedBox(height: 16),
            _Creditos(semDados: state.semDados),
            const AdSlot(compact: true),
          ],
        ),
      ),
    );
  }
}

/// What the mechanic is, in three lines, for somebody who found the page
/// before finding the NPC.
class _Explicacao extends StatelessWidget {
  const _Explicacao();

  @override
  Widget build(BuildContext context) => const Text(
    'Cada receita troca Páginas de Registro: Assimilação por atributos '
    'permanentes. O jogo não soma o que cada uma dá, e o custo vai de 1 a 100 '
    'páginas — então a melhor troca rende mais de cem vezes a pior.',
    style: TextStyle(color: PWColors.textMuted, fontSize: 13, height: 1.55),
  );
}

class _Abas extends StatelessWidget {
  const _Abas({required this.state, required this.aoTrocar});

  final RegistrosReady state;
  final void Function(String) aoTrocar;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final aba in state.abas) ...[
          _Aba(
            nome: aba,
            aberta: aba == state.query.aba,
            aoTocar: () => aoTrocar(aba),
          ),
          const SizedBox(width: 7),
        ],
      ],
    ),
  );
}

class _Aba extends StatelessWidget {
  const _Aba({required this.nome, required this.aberta, required this.aoTocar});

  final String nome;
  final bool aberta;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Material(
    color: aberta ? PWColors.surfaceRaised : Colors.transparent,
    borderRadius: BorderRadius.circular(9),
    child: InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: aoTocar,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: aberta ? PWColors.accent : PWColors.border),
        ),
        child: Text(
          nome,
          style: TextStyle(
            fontSize: 13,
            color: aberta ? PWColors.accent : PWColors.textMuted,
            fontWeight: aberta ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    ),
  );
}

/// Where the numbers came from, and what to do when one is wrong.
///
/// **The gaps and the errors ask the same favour**, so they are one block and
/// not two: a page saying "me avisa no Discord" twice, three lines apart,
/// reads as nagging rather than asking.
///
/// The credit is unresolved on purpose. Somebody built the table and the
/// owner does not know who; saying so and offering to name them is more
/// honest than a silence that reads as authorship.
class _Creditos extends StatelessWidget {
  const _Creditos({required this.semDados});

  final int semDados;

  /// The spreadsheet the 126 recipes were read from, once.
  ///
  /// Linked even though it is no longer the source — the Supabase table is —
  /// because this is a credit, not a data path. Whoever wants to check a
  /// number against where it came from should be able to.
  static const _tabela =
      'https://docs.google.com/spreadsheets/d/'
      '1nN0cUkxMXS3eOP8ajNpGJjGZWDAgXP3VJLD7LwV-IOA/edit';

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: PWColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: PWColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AGRADECIMENTOS',
          style: TextStyle(
            color: PWColors.textMuted,
            fontSize: 10,
            letterSpacing: 1.3,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Os números vêm desta '),
              _link('tabela', _tabela),
              const TextSpan(
                text:
                    ', e eu não sei quem a montou. Se for sua, me diz que '
                    'eu credito.',
              ),
            ],
          ),
          style: const TextStyle(
            color: PWColors.textMuted,
            fontSize: 13,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 9),
        Text.rich(
          TextSpan(
            children: [
              if (semDados > 0)
                TextSpan(
                  text:
                      '$semDados registros ainda estão sem bônus. Achou '
                      'algum errado, ou sabe o que falta? ',
                )
              else
                const TextSpan(text: 'Achou algum número errado? '),
              _link('Me avisa no Discord', discordInvite),
              const TextSpan(text: ' que eu corrijo.'),
            ],
          ),
          style: const TextStyle(
            color: PWColors.textMuted,
            fontSize: 13,
            height: 1.55,
          ),
        ),
      ],
    ),
  );

  /// A word that opens something.
  ///
  /// Underlined as well as coloured: colour alone is the whole message, and
  /// somebody who does not see it has nothing to fall back on.
  static TextSpan _link(String texto, String url) => TextSpan(
    text: texto,
    style: const TextStyle(
      color: PWColors.accent,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: PWColors.accent,
    ),
    recognizer: TapGestureRecognizer()
      ..onTap = () => unawaited(
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      ),
  );
}
