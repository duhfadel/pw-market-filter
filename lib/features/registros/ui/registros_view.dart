import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/pw_colors.dart';
import '../../../core/theme/pw_theme.dart';
import '../../ads/ad_slot.dart';
import 'registros_state.dart';
import 'registros_view_model.dart';
import 'widgets/atributo_filtros.dart';
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
              acesos: state.acesos,
              total: state.grade.length,
              aoAlternar: vm.alternarAtributo,
              aoLimpar: vm.limparAtributos,
            ),
            const SizedBox(height: 16),
            SlotGrid(
              slots: state.grade,
              query: state.query,
              selecionado: state.selecionado,
              aoTocar: vm.selecionar,
              compacto: compacto,
            ),
            const SizedBox(height: 16),
            RegistroPanel(registro: state.selecionado),
            const SizedBox(height: 14),
            _Ordenacao(
              ligado: state.query.porAproveitamento,
              aoTrocar: vm.ordenarPorAproveitamento,
            ),
            if (state.semDados > 0) ...[
              const SizedBox(height: 10),
              _Lacunas(quantas: state.semDados),
            ],
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

/// The one control that breaks the grid's fidelity, and says so.
class _Ordenacao extends StatelessWidget {
  const _Ordenacao({required this.ligado, required this.aoTrocar});

  final bool ligado;
  final void Function(bool) aoTrocar;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    value: ligado,
    onChanged: (v) => aoTrocar(v ?? false),
    dense: true,
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    activeColor: PWColors.accent,
    checkColor: PWColors.background,
    title: const Text(
      'Ordenar por aproveitamento',
      style: TextStyle(fontSize: 13),
    ),
    subtitle: const Text(
      'Sai da ordem do NPC e põe a melhor troca primeiro.',
      style: TextStyle(color: PWColors.textMuted, fontSize: 12),
    ),
  );
}

/// The gaps, counted. A gap nobody counts is a gap nobody fills.
class _Lacunas extends StatelessWidget {
  const _Lacunas({required this.quantas});

  final int quantas;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 2),
        child: Icon(Icons.help_outline, size: 15, color: PWColors.textMuted),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          '$quantas registros ainda sem bônus conhecido. Se você souber o que '
          'algum deles dá, me conta no Discord que eu coloco aqui.',
          style: const TextStyle(
            color: PWColors.textMuted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ),
    ],
  );
}
