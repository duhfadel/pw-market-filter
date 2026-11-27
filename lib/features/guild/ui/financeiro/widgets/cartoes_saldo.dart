import 'package:flutter/material.dart';

import '../../../../../core/theme/pw_colors.dart';
import '../dinheiro.dart';

/// The top of the financial panel: the guild's single figure, then the two
/// pots it is made of. A [Wrap] rather than a fixed [Row] — on a phone the
/// two cards stack, and nothing here has to know the screen width to make
/// that decision.
class CartoesSaldo extends StatelessWidget {
  const CartoesSaldo({
    required this.total,
    required this.saldoCaixa,
    required this.saldoReserva,
    super.key,
  });

  final int total;
  final int saldoCaixa;
  final int saldoReserva;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Total da guild',
          style: TextStyle(color: PWColors.apagado, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          tcc(total),
          style: const TextStyle(
            color: PWColors.papel,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _CartaoPote(
              rotulo: 'Caixa (operacional)',
              valor: saldoCaixa,
              icone: Icons.payments_outlined,
            ),
            _CartaoPote(
              rotulo: 'Reserva',
              valor: saldoReserva,
              icone: Icons.savings_outlined,
            ),
          ],
        ),
      ],
    );
  }
}

class _CartaoPote extends StatelessWidget {
  const _CartaoPote({
    required this.rotulo,
    required this.valor,
    required this.icone,
  });

  final String rotulo;
  final int valor;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PWColors.painel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PWColors.filete),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 18, color: PWColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rotulo,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(color: PWColors.apagado, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tcc(valor),
            style: const TextStyle(
              color: PWColors.papel,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
