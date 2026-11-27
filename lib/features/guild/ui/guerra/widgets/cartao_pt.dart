import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/pw_colors.dart';
import '../../../domain/guerra/formacao_guerra.dart';
import '../../../domain/guerra/grupo_guerra.dart';
import '../../../domain/jogador.dart';
import '../sala_view_model.dart';
import 'chip_jogador.dart';

/// A small, fixed palette for a group's colour — hexes drawn straight from
/// [PWColors.gradeColors] rather than a free colour picker. The swatch and
/// the leader crown are the one place in this screen a colour other than
/// `PWColors` is allowed to draw, and even there it has to come from this
/// list rather than from anywhere the game itself did not already define.
const _paletaCores = <String>[
  '#B9C0D4',
  '#6FCF97',
  '#56A8F5',
  '#B57BEE',
  '#FFB454',
  '#FF8C42',
  '#FF5C5C',
];

/// Parses a group's stored hex (`#56A8F5`) into a [Color]. A string that
/// fails to parse — nothing in this screen writes one — falls back to
/// [PWColors.apagado] rather than crashing the card over a bad value.
Color _corDeHex(String hex) {
  final limpo = hex.replaceFirst('#', '');
  final valor = int.tryParse(limpo, radix: 16);
  return valor == null ? PWColors.apagado : Color(0xFF000000 | valor);
}

/// One party's card: its name, colour, member count and roster — tap-only
/// for now, drag lands in the next task. `grupoIndex` is this group's
/// position in `FormacaoGuerra.grupos`, which is what every call back into
/// [SalaGuerrasViewModel] is keyed on.
class CartaoPt extends StatelessWidget {
  const CartaoPt({
    required this.grupoIndex,
    required this.grupo,
    required this.jogadoresPorId,
    super.key,
  });

  final int grupoIndex;
  final GrupoGuerra grupo;

  /// Looked up once by the view and handed down, rather than rebuilt per
  /// card — the whole roster, not just this group's members.
  final Map<String, Jogador> jogadoresPorId;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<SalaGuerrasViewModel>();
    final cor = _corDeHex(grupo.cor);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PWColors.painel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PWColors.filete),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Swatch(
                key: ValueKey('swatch_pt_$grupoIndex'),
                cor: cor,
                onTap: () => _abrirPaleta(context, vm),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  grupo.nome,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    color: PWColors.papel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _IconeBotao(
                icon: Icons.edit_outlined,
                cor: PWColors.apagado,
                tooltip: 'Renomear',
                onTap: () => _abrirRenomear(context, vm),
              ),
              const SizedBox(width: 6),
              Text(
                '${grupo.membros.length}/${FormacaoGuerra.maxMembros}',
                style: const TextStyle(color: PWColors.apagado, fontSize: 12),
              ),
              _IconeBotao(
                icon: Icons.delete_outline,
                cor: PWColors.danger,
                tooltip: 'Remover pt',
                onTap: () => vm.removerPt(grupoIndex),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (grupo.membros.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Arraste jogadores para cá.',
                  style: TextStyle(color: PWColors.apagado, fontSize: 12),
                ),
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final m in grupo.membros)
                  // A member id with no matching Jogador is never drawn —
                  // `FormacaoGuerra.podada` already prunes this on load, but
                  // a card that trusted the id blindly would crash the one
                  // time the two disagree instead of just skipping a chip.
                  if (jogadoresPorId[m.jogadorId] case final j?)
                    ChipJogador(
                      key: ValueKey('membro_${grupoIndex}_${m.jogadorId}'),
                      jogador: j,
                      corGrupo: cor,
                      lider: m.lider,
                      onAlternarLider: () =>
                          vm.alternarLider(grupoIndex, m.jogadorId),
                      onRemover: () => vm.mover(m.jogadorId, null),
                    ),
              ],
            ),
        ],
      ),
    );
  }

  void _abrirRenomear(BuildContext context, SalaGuerrasViewModel vm) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _DialogoRenomear(
        nomeAtual: grupo.nome,
        onConfirmar: (novoNome) => vm.renomear(grupoIndex, novoNome),
      ),
    );
  }

  void _abrirPaleta(BuildContext context, SalaGuerrasViewModel vm) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: PWColors.surface,
        title: const Text('Cor da pt', style: TextStyle(color: PWColors.papel)),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final hex in _paletaCores)
              InkWell(
                key: ValueKey('cor_$hex'),
                onTap: () {
                  vm.recolorir(grupoIndex, hex);
                  Navigator.of(dialogContext).pop();
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _corDeHex(hex),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hex == grupo.cor
                          ? PWColors.papel
                          : PWColors.filete,
                      width: hex == grupo.cor ? 2 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.cor, required this.onTap, super.key});

  final Color cor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Trocar cor',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: cor,
          shape: BoxShape.circle,
          border: Border.all(color: PWColors.filete),
        ),
      ),
    ),
  );
}

class _IconeBotao extends StatelessWidget {
  const _IconeBotao({
    required this.icon,
    required this.cor,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color cor;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(icon, size: 16, color: cor),
    tooltip: tooltip,
    onPressed: onTap,
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    padding: EdgeInsets.zero,
  );
}

/// The rename dialog — a plain [AlertDialog] with one [TextField], the
/// field's own state held locally since nothing about a half-typed name
/// belongs in [SalaEstado].
class _DialogoRenomear extends StatefulWidget {
  const _DialogoRenomear({required this.nomeAtual, required this.onConfirmar});

  final String nomeAtual;
  final ValueChanged<String> onConfirmar;

  @override
  State<_DialogoRenomear> createState() => _DialogoRenomearState();
}

class _DialogoRenomearState extends State<_DialogoRenomear> {
  late final _controller = TextEditingController(text: widget.nomeAtual);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    final nome = _controller.text.trim();
    if (nome.isEmpty) return;
    widget.onConfirmar(nome);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: PWColors.surface,
    title: const Text('Renomear pt', style: TextStyle(color: PWColors.papel)),
    content: TextField(
      controller: _controller,
      autofocus: true,
      style: const TextStyle(color: PWColors.papel),
      decoration: const InputDecoration(labelText: 'Nome da pt'),
      onSubmitted: (_) => _confirmar(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _confirmar, child: const Text('Salvar')),
    ],
  );
}
