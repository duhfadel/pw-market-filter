import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/pw_colors.dart';
import '../../../../core/theme/pw_theme.dart';
import '../../domain/guerra/formacao_guerra.dart';
import '../../domain/jogador.dart';
import '../mensagens.dart';
import 'sala_estado.dart';
import 'sala_view_model.dart';
import 'widgets/cartao_pt.dart';
import 'widgets/chip_jogador.dart';

/// Below this width the two columns stack — the available pool on top, the
/// pts below — the same breakpoint shape `RosterView` already uses for its
/// table-versus-cards switch, chosen the same way: by what fits, not by a
/// device category.
const double _larguraDuasColunas = 760;

/// The pt column's width — both the pool column on the left and every pt
/// card on the right in the wide layout, which is why `_Pronta` reads this
/// constant for the left column instead of its own literal `300`: the two
/// sides of the board are meant to line up, and a resize that touched only
/// one would quietly break that. On the right it also doubles as the
/// minimum before a card gives up and matches the available width instead,
/// the guard that keeps a 300px card from overflowing a phone narrower than
/// that.
const double _larguraCartaoPt = 300;

/// "salvo há N min · quem" from [SalaPronta.salvoEm] and
/// [SalaPronta.salvoPorEmail] — a finer grain than `rotuloAtualizado` in
/// `tempo.dart` on purpose: that one tracks a sheet correction, read in
/// days, while a board save happens minute to minute during a single
/// editing session. The author is appended only when known — both a save
/// made before this column existed and one read back anonymously still owe
/// nobody a name — and the label is what the author rides in on, since
/// [salvoEm] is read from the server now and not only from this session's
/// own save, so a teammate's save shows up here too.
String _rotuloSalvo(DateTime? salvoEm, String? salvoPorEmail) {
  if (salvoEm == null) return 'ainda não salvo';
  final diff = DateTime.now().difference(salvoEm);
  final quando = diff.inMinutes < 1
      ? 'salvo agora'
      : diff.inMinutes < 60
      ? 'salvo há ${diff.inMinutes} min'
      : 'salvo há ${diff.inHours} h';
  if (salvoPorEmail == null || salvoPorEmail.isEmpty) return quando;
  return '$quando · $salvoPorEmail';
}

/// The war room: the roster not yet placed on one side, the pts on the
/// other. A chip moves between the two by its grab handle
/// (`ChipJogador`'s `_Pega`): dragged onto a pt it calls `vm.mover(id, i)`,
/// dragged onto the pool it calls `vm.mover(id, null)`.
class SalaGuerrasView extends StatelessWidget {
  const SalaGuerrasView({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<SalaGuerrasViewModel>()..carregar(),
    child: const _Tela(),
  );
}

class _Tela extends StatefulWidget {
  const _Tela();

  @override
  State<_Tela> createState() => _TelaState();
}

class _TelaState extends State<_Tela> {
  final _buscaController = TextEditingController();
  String _busca = '';
  StreamSubscription<GuildFailure>? _sub;

  @override
  void initState() {
    super.initState();
    // Listened to here, once, rather than re-subscribed on every rebuild —
    // `falhasSalvar` is a one-shot channel the view model never replays, so
    // a subscription created inside `build` would miss whatever fired
    // between two builds.
    _sub = context.read<SalaGuerrasViewModel>().falhasSalvar.listen((falha) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensagemDoGuildErro(falha.erro))));
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: PWColors.surface,
    appBar: AppBar(
      backgroundColor: PWColors.surface,
      title: const Text(
        'Sala de guerras',
        style: TextStyle(fontFamily: PWTheme.display, color: PWColors.papel),
      ),
    ),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Divider(height: 1),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: BlocBuilder<SalaGuerrasViewModel, SalaEstado>(
            builder: (context, state) => _BarraSalvar(state: state),
          ),
        ),
        Expanded(
          child: BlocBuilder<SalaGuerrasViewModel, SalaEstado>(
            builder: (context, state) => switch (state) {
              SalaCarregando() => const Center(
                child: CircularProgressIndicator(color: PWColors.accent),
              ),
              SalaFalha() => const Center(
                child: Text(
                  'Não deu para carregar a sala de guerras.',
                  style: TextStyle(color: PWColors.textMuted),
                ),
              ),
              SalaPronta() => _Pronta(
                state: state,
                busca: _busca,
                controller: _buscaController,
                onBuscaChange: (v) => setState(() => _busca = v),
              ),
            },
          ),
        ),
      ],
    ),
  );
}

/// The save button and its "last saved" label. A [Wrap] rather than a [Row]
/// — this bar sits above everything else and, on a narrow screen, a row
/// that does not fit would overflow exactly the way the sibling iteration's
/// AppBar once did; wrapping to a second line costs nothing a board this
/// small cannot spare.
class _BarraSalvar extends StatelessWidget {
  const _BarraSalvar({required this.state});

  final SalaEstado state;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<SalaGuerrasViewModel>();
    final pronta = state is SalaPronta ? state as SalaPronta : null;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      spacing: 12,
      runSpacing: 8,
      children: [
        // Bounded so a long institutional email ellipsizes instead of
        // pushing the save button off a narrow screen — a `Wrap` gives each
        // child its own intrinsic width, which for a bare `Text` is however
        // long the string is.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Text(
            _rotuloSalvo(pronta?.salvoEm, pronta?.salvoPorEmail),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(color: PWColors.apagado, fontSize: 12),
          ),
        ),
        FilledButton.icon(
          onPressed: pronta == null ? null : vm.salvar,
          icon: const Icon(Icons.save_outlined, size: 18),
          label: const Text('Salvar formação'),
        ),
      ],
    );
  }
}

class _Pronta extends StatelessWidget {
  const _Pronta({
    required this.state,
    required this.busca,
    required this.controller,
    required this.onBuscaChange,
  });

  final SalaPronta state;
  final String busca;
  final TextEditingController controller;
  final ValueChanged<String> onBuscaChange;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<SalaGuerrasViewModel>();
    final jogadoresPorId = {for (final j in state.jogadores) j.id: j};

    // `state.disponiveis` is the raw id list, sorted by nothing in
    // particular — resolved and alphabetised here, on the screen, which is
    // where "how the pool looks" belongs rather than in the model.
    final disponiveis = [
      for (final id in state.disponiveis) ?jogadoresPorId[id],
    ]..sort((a, b) => a.nome.compareTo(b.nome));

    final filtro = busca.trim().toLowerCase();
    final filtrados = filtro.isEmpty
        ? disponiveis
        : disponiveis
              .where((j) => j.nome.toLowerCase().contains(filtro))
              .toList();

    final esquerda = _Disponiveis(
      jogadores: filtrados,
      total: disponiveis.length,
      controller: controller,
      onBuscaChange: onBuscaChange,
    );
    final direita = _GradePts(
      formacao: state.formacao,
      jogadoresPorId: jogadoresPorId,
      onNovaPt: vm.novaPt,
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth > _larguraDuasColunas) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: _larguraCartaoPt, child: esquerda),
                const SizedBox(width: 16),
                Expanded(child: direita),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [esquerda, const SizedBox(height: 16), direita],
          ),
        );
      },
    );
  }
}

/// The left column: search plus the unplaced roster, as chips with no leader
/// crown and no remove cross — there is nothing to toggle or send back from
/// the pool itself. The whole column is a `DragTarget<String>`: dropping a
/// dragged `jogadorId` here calls `vm.mover(id, null)`, which is simply
/// "remove from every group" — there is no destination of its own to
/// refuse, unlike a pt, which can be full.
class _Disponiveis extends StatelessWidget {
  const _Disponiveis({
    required this.jogadores,
    required this.total,
    required this.controller,
    required this.onBuscaChange,
  });

  final List<Jogador> jogadores;
  final int total;
  final TextEditingController controller;
  final ValueChanged<String> onBuscaChange;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<SalaGuerrasViewModel>();
    return DragTarget<String>(
      onAcceptWithDetails: (details) => vm.mover(details.data, null),
      builder: (context, candidatos, rejeitados) {
        final recebendo = candidatos.isNotEmpty;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: recebendo ? PWColors.surfaceRaised : PWColors.painel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: recebendo ? PWColors.accent : PWColors.filete,
              width: recebendo ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Disponíveis ($total)',
                style: const TextStyle(
                  color: PWColors.papel,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('busca_disponiveis'),
                controller: controller,
                onChanged: onBuscaChange,
                style: const TextStyle(color: PWColors.papel),
                decoration: const InputDecoration(
                  hintText: 'Buscar jogador…',
                  prefixIcon: Icon(Icons.search, color: PWColors.apagado),
                ),
              ),
              const SizedBox(height: 10),
              if (jogadores.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Nenhum jogador disponível.',
                    style: TextStyle(color: PWColors.apagado, fontSize: 12),
                  ),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final j in jogadores)
                      ChipJogador(key: ValueKey('disp_${j.id}'), jogador: j),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The right column: every pt plus the "+ nova pt" card, both the same
/// fixed-ish width so they flow in a [Wrap] rather than a [GridView] — a
/// pt's height depends on how many members it holds, and a `GridView`'s
/// single `mainAxisExtent` cannot follow that, the exact trap this
/// repository's own notes warn against.
class _GradePts extends StatelessWidget {
  const _GradePts({
    required this.formacao,
    required this.jogadoresPorId,
    required this.onNovaPt,
  });

  final FormacaoGuerra formacao;
  final Map<String, Jogador> jogadoresPorId;
  final VoidCallback onNovaPt;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final largura = c.maxWidth < _larguraCartaoPt
          ? c.maxWidth
          : _larguraCartaoPt;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (var i = 0; i < formacao.grupos.length; i++)
            SizedBox(
              width: largura,
              child: CartaoPt(
                key: ValueKey('pt_$i'),
                grupoIndex: i,
                grupo: formacao.grupos[i],
                jogadoresPorId: jogadoresPorId,
              ),
            ),
          if (formacao.grupos.length < FormacaoGuerra.maxGrupos)
            SizedBox(
              width: largura,
              child: _CartaoNovaPt(onTap: onNovaPt),
            ),
        ],
      );
    },
  );
}

class _CartaoNovaPt extends StatelessWidget {
  const _CartaoNovaPt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const Key('nova_pt'),
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: PWColors.elevado.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PWColors.filete),
      ),
      child: const Text(
        '+ nova pt',
        style: TextStyle(color: PWColors.apagado, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
