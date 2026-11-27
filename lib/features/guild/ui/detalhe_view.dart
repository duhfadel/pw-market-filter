import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/pw_colors.dart';
import '../../../core/theme/pw_theme.dart';
import '../../../core/widgets/game_icon.dart';
import '../../../market/ocupacoes.dart';
import '../data/fichas_repository.dart';
import '../domain/delta.dart';
import '../domain/ficha.dart';
import '../domain/jogador.dart';
import '../domain/papel.dart';
import '../domain/runa.dart';
import 'detalhe_estado.dart';
import 'detalhe_view_model.dart';
import 'roster_state.dart';
import 'roster_view_model.dart';
import 'tempo.dart';
import 'widgets/jogador_form.dart';

/// Which `dados` keys show under each group heading, and the label each one
/// prints — fixed here rather than derived from whatever a ficha happens to
/// carry, so the order on screen never depends on JSON key order. A key a
/// ficha does not have is simply skipped when the group is drawn; it is
/// never shown as zero or as a dash standing for "unknown", the same rule
/// `Jogador` already documents for an unread stat.
const _camposAtaque = [
  ('nivel_ataque', 'Nível de Ataque'),
  ('critico', 'Crítico'),
  ('ataque_fisico', 'Ataque Físico'),
  ('ataque_magico', 'Ataque Mágico'),
  ('acerto', 'Acerto'),
  ('penetracao_fisica', 'Penetração Física'),
  ('penetracao_magica', 'Penetração Mágica'),
  ('furia', 'Fúria'),
];

const _camposDefesa = [
  ('nivel_defesa', 'Nível de Defesa'),
  ('def_fisica', 'Defesa Física'),
  ('def_metal', 'Defesa de Metal'),
  ('def_madeira', 'Defesa de Madeira'),
  ('def_agua', 'Defesa de Água'),
  ('def_fogo', 'Defesa de Fogo'),
  ('def_terra', 'Defesa de Terra'),
  ('esquiva', 'Esquiva'),
  ('hp', 'HP'),
  ('mp', 'MP'),
];

const _camposOutros = [
  ('canalizacao', 'Canalização'),
  ('espirito', 'Espírito'),
  ('indice_dano', 'Índice de Dano'),
  ('sobrevivencia', 'Sobrevivência'),
];

/// One player's full page: identity, what changed since the last transcribed
/// sheet, every stat grouped, and the rune loadout. Opened from a tap on a
/// roster row.
class DetalheView extends StatelessWidget {
  const DetalheView({
    required this.jogador,
    required this.papel,
    required this.vm,
    super.key,
  });

  final Jogador jogador;

  /// Gates the "editar" entry — the same `podeEditarJogadores` the roster
  /// already uses to show or hide "Adicionar jogador", so a role that
  /// cannot touch the list cannot touch one player's page either.
  final Papel papel;

  /// The roster's own view model, passed down rather than re-created, so
  /// saving an edit here reloads the very list the visitor came from and
  /// goes back to on their own, instead of a second, disconnected copy of
  /// the roster's state.
  final RosterViewModel vm;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        DetalheViewModel(getIt<FichasRepository>(), jogador)..carregar(),
    child: _Tela(papel: papel, vm: vm),
  );
}

class _Tela extends StatelessWidget {
  const _Tela({required this.papel, required this.vm});

  final Papel papel;
  final RosterViewModel vm;

  /// Opens the edit dialog for [jogador] and, once it closes, brings this
  /// page back in sync on both halves of the player. `editar` and
  /// `trocarImagem` already call `carregar()` on the roster side, so [vm]
  /// is never stale — `atualizarJogador` pulls this player's
  /// freshly-reloaded row back out of it for the header. But a hand
  /// correction also merges into the latest `fichas` row now (see
  /// `RosterViewModel.editar`), and `DetalheViewModel` holds its own copy of
  /// that history — reading [vm] again says nothing about it. So the stat
  /// groups below the header need their own reload, which is why this calls
  /// `DetalheViewModel.carregar()` too, rather than relying on a pop-and-reopen
  /// of this same page to pick the new ficha up.
  Future<void> _abrirEdicao(BuildContext context, Jogador jogador) async {
    final detalheVm = context.read<DetalheViewModel>();
    await showDialog<void>(
      context: context,
      builder: (_) => JogadorForm(vm: vm, inicial: jogador),
    );
    final s = vm.state;
    if (s is RosterPronto) {
      for (final j in s.jogadores) {
        if (j.id == jogador.id) {
          detalheVm.atualizarJogador(j);
          break;
        }
      }
    }
    await detalheVm.carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PWColors.surface,
      appBar: AppBar(
        backgroundColor: PWColors.surface,
        title: BlocBuilder<DetalheViewModel, DetalheEstado>(
          builder: (context, state) => Text(
            switch (state) {
              DetalhePronto(jogador: final j) => j.nome,
              DetalheSemFicha(jogador: final j) => j.nome,
              _ => '',
            },
            // The "editar" action now shares this bar with the name, so a
            // long nickname on a narrow phone needs somewhere to give —
            // never the action beside it.
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              fontFamily: PWTheme.display,
              color: PWColors.papel,
            ),
          ),
        ),
        actions: !papel.podeEditarJogadores
            ? null
            : [
                BlocBuilder<DetalheViewModel, DetalheEstado>(
                  builder: (context, state) {
                    final j = switch (state) {
                      DetalhePronto(jogador: final j) => j,
                      DetalheSemFicha(jogador: final j) => j,
                      _ => null,
                    };
                    if (j == null) return const SizedBox.shrink();
                    return TextButton.icon(
                      onPressed: () => _abrirEdicao(context, j),
                      style: TextButton.styleFrom(
                        foregroundColor: PWColors.accent,
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('editar'),
                    );
                  },
                ),
              ],
      ),
      body: BlocBuilder<DetalheViewModel, DetalheEstado>(
        builder: (context, state) => switch (state) {
          DetalheCarregando() => const Center(
            child: CircularProgressIndicator(color: PWColors.accent),
          ),
          DetalheFalha() => const Center(
            child: Text(
              'Não deu para carregar a ficha.',
              style: TextStyle(color: PWColors.textMuted),
            ),
          ),
          DetalheSemFicha() => const Center(
            child: Text(
              'Ainda não há ficha transcrita para este jogador.',
              style: TextStyle(color: PWColors.textMuted),
            ),
          ),
          DetalhePronto() => _Pronto(state: state),
        },
      ),
    );
  }
}

class _Pronto extends StatelessWidget {
  const _Pronto({required this.state});

  final DetalhePronto state;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Cabecalho(jogador: state.jogador),
            const SizedBox(height: 16),
            // Gated on the same two fields `_FaixaEvolucao` draws, not on
            // `delta.isNotEmpty` — a delta can be non-empty over fields
            // neither of these name (e.g. only `hp` moved) and the banner
            // then renders nothing, which used to leave this 16px spacer
            // floating above the Ataque group with no banner above it.
            if (_destaquesEvolucao(state.delta).isNotEmpty) ...[
              _FaixaEvolucao(delta: state.delta),
              const SizedBox(height: 16),
            ],
            _GrupoAtributos(
              titulo: 'Ataque',
              campos: _camposAtaque,
              atual: state.atual,
              delta: state.delta,
            ),
            const SizedBox(height: 16),
            _GrupoAtributos(
              titulo: 'Defesa',
              campos: _camposDefesa,
              atual: state.atual,
              delta: state.delta,
            ),
            const SizedBox(height: 16),
            _GrupoAtributos(
              titulo: 'Outros',
              campos: _camposOutros,
              atual: state.atual,
              delta: state.delta,
            ),
            const SizedBox(height: 16),
            _GrupoRunas(runas: state.atual.runas),
          ],
        ),
      ),
    ),
  );
}

/// Identity, which lives in the header and never inside a stat group —
/// `classe`, `cla`, `cultivo`, `limite`, `nivel` and `despertares` describe
/// who the character is, not a stat that a new sheet could raise or lower.
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.jogador});

  final Jogador jogador;

  @override
  Widget build(BuildContext context) {
    final j = jogador;
    final ocupacao = j.classe == null ? null : ocupacaoDaClasse[j.classe];
    final identidade = [
      if (j.classe != null) j.classe!,
      if (j.cla != null) j.cla!,
      if (j.cultivo != null) j.cultivo!,
      if (j.limite != null) j.limite!,
      if (j.nivel != null) 'nível ${j.nivel}',
      if (j.despertares != null)
        '${j.despertares} despertar${j.despertares == 1 ? '' : 'es'}',
    ].join(' · ');
    final atualizado = rotuloAtualizado(j.atualizadoEm);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ocupacao != null) ...[
          ClassIcon(ocupacao, size: 56),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                j.nome,
                style: const TextStyle(
                  fontFamily: PWTheme.display,
                  color: PWColors.papel,
                  fontSize: 22,
                ),
              ),
              if (identidade.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    identidade,
                    style: const TextStyle(
                      color: PWColors.apagado,
                      fontSize: 13,
                    ),
                  ),
                ),
              if (atualizado != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    atualizado,
                    style: const TextStyle(
                      color: PWColors.apagado,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The two fields `_FaixaEvolucao` actually highlights — shared with
/// `_Pronto`'s own gate, so the banner and the spacer above the Ataque
/// group agree on whether there is anything to show. `delta.isNotEmpty`
/// alone is not that answer: a ficha missing `nivel_ataque` with `critico`
/// never delta-ing (it is free text) can leave `delta` non-empty while
/// naming neither field this banner draws, which used to reserve the
/// banner's `SizedBox` for a `_FaixaEvolucao` that rendered nothing.
List<(String, DeltaCampo)> _destaquesEvolucao(Map<String, DeltaCampo> delta) {
  return [
    if (delta['nivel_ataque'] != null)
      ('Nível de Ataque', delta['nivel_ataque']!),
    if (delta['critico'] != null) ('Crítico', delta['critico']!),
  ];
}

/// "Desde a última imagem" — the attack level and crit changes, the two
/// numbers a guild officer actually scans for. Only drawn when there is a
/// previous ficha to compare against; `_Pronto` already guards that.
class _FaixaEvolucao extends StatelessWidget {
  const _FaixaEvolucao({required this.delta});

  final Map<String, DeltaCampo> delta;

  @override
  Widget build(BuildContext context) {
    final destaques = _destaquesEvolucao(delta);
    if (destaques.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PWColors.elevado,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PWColors.violeta),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Desde a última imagem',
            style: TextStyle(
              color: PWColors.apagado,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 18,
            runSpacing: 6,
            children: [
              for (final (rotulo, d) in destaques)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$rotulo ',
                      style: const TextStyle(
                        color: PWColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${d.de} → ${d.para}',
                      style: const TextStyle(
                        color: PWColors.papel,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _SetaRumo(d.rumo),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The ↑/↓/— chip that marks a field's direction against the previous
/// ficha. Shared between the banner and every stat row, so the three
/// symbols always mean the same thing wherever they show up.
class _SetaRumo extends StatelessWidget {
  const _SetaRumo(this.rumo);

  final Rumo rumo;

  @override
  Widget build(BuildContext context) {
    final (icone, cor) = switch (rumo) {
      Rumo.subiu => (Icons.arrow_upward, PWColors.ok),
      Rumo.desceu => (Icons.arrow_downward, PWColors.danger),
      Rumo.igual => (Icons.remove, PWColors.apagado),
    };
    return Icon(icone, size: 14, color: cor);
  }
}

class _GrupoAtributos extends StatelessWidget {
  const _GrupoAtributos({
    required this.titulo,
    required this.campos,
    required this.atual,
    required this.delta,
  });

  final String titulo;
  final List<(String, String)> campos;
  final Ficha atual;
  final Map<String, DeltaCampo> delta;

  @override
  Widget build(BuildContext context) {
    final presentes = [
      for (final c in campos)
        if (atual.dados.containsKey(c.$1)) c,
    ];
    if (presentes.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PWColors.painel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PWColors.filete),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: PWColors.apagado,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          for (final (chave, rotulo) in presentes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rotulo,
                      style: const TextStyle(
                        color: PWColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      '${atual.dados[chave]}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PWColors.papel,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (delta[chave] != null) ...[
                    const SizedBox(width: 8),
                    _SetaRumo(delta[chave]!.rumo),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A family's tile colour. Only the five known fusion families
/// (`lib/features/runas/domain/runa.dart`) get a colour of their own; any
/// other string reads as a plain, neutral tile rather than guessing — the
/// rune's number is what matters, and a wrong colour would lie about a fact
/// nobody confirmed.
const _corDaFamilia = <String, Color>{
  'Verdejante': PWColors.defenceTier,
  'Escarlate': PWColors.danger,
  'Celeste': PWColors.male,
  'Áurea': PWColors.accent,
  'Argêntea': PWColors.apagado,
};

class _GrupoRunas extends StatelessWidget {
  const _GrupoRunas({required this.runas});

  final List<Runa> runas;

  @override
  Widget build(BuildContext context) {
    if (runas.isEmpty) {
      return const Text(
        'Nenhuma runa registrada.',
        style: TextStyle(color: PWColors.textMuted),
      );
    }

    final porNivel = <int, int>{};
    for (final r in runas) {
      porNivel[r.nivel.numero] = (porNivel[r.nivel.numero] ?? 0) + 1;
    }
    final niveis = porNivel.keys.toList()..sort((a, b) => b.compareTo(a));
    final maior = niveis.first;
    final resumo = [
      'Maior nível: $maior',
      for (final n in niveis) '${porNivel[n]} nv$n',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PWColors.painel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PWColors.filete),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Runas',
            style: TextStyle(
              color: PWColors.apagado,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final r in runas) _TilRuna(r)],
          ),
          const SizedBox(height: 10),
          Text(
            resumo,
            style: const TextStyle(color: PWColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TilRuna extends StatelessWidget {
  const _TilRuna(this.runa);

  final Runa runa;

  @override
  Widget build(BuildContext context) {
    final cor = _corDaFamilia[runa.familia] ?? PWColors.apagado;
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: PWColors.elevado,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor, width: 2),
      ),
      child: Text(
        '${runa.nivel.numero}',
        style: TextStyle(color: cor, fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }
}
