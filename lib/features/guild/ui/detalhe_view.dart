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
import '../domain/runa.dart';
import 'detalhe_estado.dart';
import 'detalhe_view_model.dart';

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
  const DetalheView({required this.jogador, super.key});

  final Jogador jogador;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        DetalheViewModel(getIt<FichasRepository>(), jogador)..carregar(),
    child: const _Tela(),
  );
}

class _Tela extends StatelessWidget {
  const _Tela();

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
            style: const TextStyle(
              fontFamily: PWTheme.display,
              color: PWColors.papel,
            ),
          ),
        ),
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
            if (state.delta.isNotEmpty) ...[
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
    final atualizado = _rotuloAtualizado(j.atualizadoEm);

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

/// "atualizado há N dias", the date only — no author in this iteration, the
/// same call `roster_view.dart`'s own card already made and for the same
/// reason: this screen cannot resolve another staff member's uid to a name.
String? _rotuloAtualizado(DateTime? data) {
  if (data == null) return null;
  final dias = DateTime.now().difference(data).inDays;
  if (dias <= 0) return 'atualizado hoje';
  if (dias == 1) return 'atualizado há 1 dia';
  return 'atualizado há $dias dias';
}

/// "Desde a última imagem" — the attack level and crit changes, the two
/// numbers a guild officer actually scans for. Only drawn when there is a
/// previous ficha to compare against; `_Pronto` already guards that.
class _FaixaEvolucao extends StatelessWidget {
  const _FaixaEvolucao({required this.delta});

  final Map<String, DeltaCampo> delta;

  @override
  Widget build(BuildContext context) {
    final destaques = [
      if (delta['nivel_ataque'] != null)
        ('Nível de Ataque', delta['nivel_ataque']!),
      if (delta['critico'] != null) ('Crítico', delta['critico']!),
    ];
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
                  Text(
                    '${atual.dados[chave]}',
                    style: const TextStyle(
                      color: PWColors.papel,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
