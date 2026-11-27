import 'package:flutter/material.dart';

import '../../../../../core/theme/pw_colors.dart';
import '../../../domain/financeiro/lancamento.dart';
import '../../../domain/jogador.dart';
import '../dinheiro.dart';
import '../rotulos_financeiro.dart';

String _data(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/'
    '${d.year}';

/// One row of the livro-caixa. The middle column is whatever names the
/// movement — a transferência has no categoria or descrição of its own, so
/// it reads as "Caixa → Reserva" instead; a pagamento staff resolves
/// `membro` to the player's name, because an id on screen tells a reader
/// nothing the market index's own naming rules do not already warn against.
class LinhaLancamento extends StatelessWidget {
  const LinhaLancamento({
    required this.lancamento,
    required this.jogadoresPorId,
    required this.onRemover,
    super.key,
  });

  final Lancamento lancamento;
  final Map<String, Jogador> jogadoresPorId;
  final VoidCallback onRemover;

  String get _meio {
    final l = lancamento;
    if (l.tipo == TipoLancamento.transferencia) {
      final destino = l.poteDestino;
      return destino == null
          ? rotuloPote(l.pote)
          : '${rotuloPote(l.pote)} → ${rotuloPote(destino)}';
    }
    final partes = <String>[];
    if (l.tipo == TipoLancamento.pagamentoStaff && l.membro != null) {
      partes.add(jogadoresPorId[l.membro]?.nome ?? 'Jogador removido');
    }
    if (l.categoria != null) partes.add(rotuloCategoria(l.categoria!));
    if (l.descricao != null && l.descricao!.isNotEmpty) {
      partes.add(l.descricao!);
    }
    if (partes.isEmpty) return '—';
    return partes.join(' · ');
  }

  String get _valorComSinal {
    switch (lancamento.tipo) {
      case TipoLancamento.entrada:
        return '+${tcc(lancamento.valor)}';
      case TipoLancamento.despesa:
      case TipoLancamento.pagamentoStaff:
        return '-${tcc(lancamento.valor)}';
      case TipoLancamento.transferencia:
        return tcc(lancamento.valor);
    }
  }

  Future<void> _confirmarRemocao(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: PWColors.surface,
        title: const Text(
          'Apagar lançamento?',
          style: TextStyle(color: PWColors.papel),
        ),
        content: Text(
          'Isso remove "$_meio" (${tcc(lancamento.valor)}) do livro-caixa.',
          style: const TextStyle(color: PWColors.apagado),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirmar_remocao'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: PWColors.danger),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (ok == true) onRemover();
  }

  @override
  Widget build(BuildContext context) {
    final l = lancamento;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PWColors.filete)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: corTipo(l.tipo).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              rotuloTipo(l.tipo),
              style: TextStyle(
                color: corTipo(l.tipo),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _meio,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(color: PWColors.papel, fontSize: 13),
                ),
                Row(
                  children: [
                    Text(
                      _data(l.data),
                      style: const TextStyle(
                        color: PWColors.apagado,
                        fontSize: 11,
                      ),
                    ),
                    if (l.fixo) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: PWColors.elevado,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'fixo',
                          style: TextStyle(
                            color: PWColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _valorComSinal,
            style: TextStyle(
              color: corTipo(l.tipo),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          IconButton(
            key: const Key('remover_lancamento'),
            onPressed: () => _confirmarRemocao(context),
            icon: const Icon(Icons.delete_outline, size: 18),
            color: PWColors.apagado,
            tooltip: 'Apagar',
          ),
        ],
      ),
    );
  }
}
