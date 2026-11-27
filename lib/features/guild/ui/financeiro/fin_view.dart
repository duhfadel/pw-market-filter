import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/pw_colors.dart';
import '../../../../core/theme/pw_theme.dart';
import '../../domain/jogador.dart';
import '../mensagens.dart';
import 'fin_estado.dart';
import 'fin_view_model.dart';
import 'widgets/cartoes_saldo.dart';
import 'widgets/dialogos_financeiro.dart';
import 'widgets/grafico_fin.dart';
import 'widgets/linha_lancamento.dart';

/// The financial panel: the guild's total and its two pots, the four ways
/// money moves, a month-by-month chart of entrada/despesa/staff against the
/// current gasto fixo, and the ledger of every movement so far.
class FinanceiroView extends StatelessWidget {
  const FinanceiroView({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<FinanceiroViewModel>()..carregar(),
    child: const _Tela(),
  );
}

class _Tela extends StatefulWidget {
  const _Tela();

  @override
  State<_Tela> createState() => _TelaState();
}

class _TelaState extends State<_Tela> {
  StreamSubscription<GuildFailure>? _sub;

  @override
  void initState() {
    super.initState();
    // Same one-shot-channel shape as `SalaGuerrasView._sub`: `falhas` never
    // replays, so the subscription has to exist before any write can land on
    // it rather than being created lazily inside `build`.
    _sub = context.read<FinanceiroViewModel>().falhas.listen((falha) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensagemDoGuildErro(falha.erro))));
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: PWColors.surface,
    appBar: AppBar(
      backgroundColor: PWColors.surface,
      title: const Text(
        'Financeiro',
        style: TextStyle(fontFamily: PWTheme.display, color: PWColors.papel),
      ),
    ),
    body: BlocBuilder<FinanceiroViewModel, FinEstado>(
      builder: (context, state) => switch (state) {
        FinCarregando() => const Center(
          child: CircularProgressIndicator(color: PWColors.accent),
        ),
        FinFalha() => const Center(
          child: Text(
            'Não deu para carregar o financeiro.',
            style: TextStyle(color: PWColors.textMuted),
          ),
        ),
        FinPronto() => _Pronta(state: state),
      },
    ),
  );
}

class _Pronta extends StatelessWidget {
  const _Pronta({required this.state});

  final FinPronto state;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<FinanceiroViewModel>();
    final jogadoresPorId = {for (final j in state.jogadores) j.id: j};
    final lancamentos = state.lancamentos;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CartoesSaldo(
                  total: state.totalGuild,
                  saldoCaixa: state.saldoCaixa,
                  saldoReserva: state.saldoReserva,
                ),
                const SizedBox(height: 20),
                _Acoes(vm: vm, jogadores: state.jogadores),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Entradas, despesas e staff por mês',
                    style: TextStyle(
                      color: PWColors.papel,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                GraficoFin(meses: state.meses, gastoFixo: state.gastoFixo),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Livro-caixa',
                    style: TextStyle(
                      color: PWColors.papel,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (lancamentos.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Nenhum lançamento ainda.',
                  style: TextStyle(color: PWColors.apagado),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.builder(
              itemCount: lancamentos.length,
              itemBuilder: (context, i) {
                final l = lancamentos[i];
                return LinhaLancamento(
                  key: ValueKey('lanc_${l.id}'),
                  lancamento: l,
                  jogadoresPorId: jogadoresPorId,
                  onRemover: () => vm.remover(l.id),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// The four buttons that open the lançamento dialogs — a [Wrap] rather than
/// a [Row] so a phone-width panel gives them a second line instead of
/// overflowing, the same guard `SalaGuerrasView._BarraSalvar` already uses
/// for its own bar.
class _Acoes extends StatelessWidget {
  const _Acoes({required this.vm, required this.jogadores});

  final FinanceiroViewModel vm;
  final List<Jogador> jogadores;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      OutlinedButton.icon(
        onPressed: () => mostrarDialogoEntrada(context, vm),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Adicionar dinheiro'),
      ),
      OutlinedButton.icon(
        onPressed: () => mostrarDialogoDespesa(context, vm),
        icon: const Icon(Icons.remove, size: 18),
        label: const Text('Adicionar despesa'),
      ),
      OutlinedButton.icon(
        onPressed: () => mostrarDialogoPagamentoStaff(context, vm, jogadores),
        icon: const Icon(Icons.groups_outlined, size: 18),
        label: const Text('Pagar staff'),
      ),
      OutlinedButton.icon(
        onPressed: () => mostrarDialogoTransferencia(context, vm),
        icon: const Icon(Icons.swap_horiz, size: 18),
        label: const Text('Transferir'),
      ),
    ],
  );
}
