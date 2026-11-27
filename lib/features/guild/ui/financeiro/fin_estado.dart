import '../../domain/financeiro/calculos.dart';
import '../../domain/financeiro/lancamento.dart';
import '../../domain/jogador.dart';

/// The financial panel's state. `FinPronto` carries the raw ledger and
/// roster, and exposes the derived totals as getters over the pure
/// functions in `calculos.dart` — there is one place that adds these
/// numbers up, and the screen never recomputes them on its own.
sealed class FinEstado {
  const FinEstado();
}

class FinCarregando extends FinEstado {
  const FinCarregando();
}

class FinPronto extends FinEstado {
  const FinPronto(this.lancamentos, this.jogadores);

  final List<Lancamento> lancamentos;
  final List<Jogador> jogadores;

  int get saldoCaixa => saldoDoPote(lancamentos, Pote.caixa);

  int get saldoReserva => saldoDoPote(lancamentos, Pote.reserva);

  int get totalGuild => total(lancamentos);

  List<MesFinanceiro> get meses => porMes(lancamentos);

  int get gastoFixo => gastoFixoMensal(lancamentos);
}

class FinFalha extends FinEstado {
  const FinFalha();
}
