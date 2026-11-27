import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guild/domain/financeiro/lancamento.dart';
import 'package:pw_market_filter/features/guild/domain/financeiro/calculos.dart';

Lancamento l(TipoLancamento t, Pote p, int v, {Pote? dest, bool fixo = false, DateTime? data}) =>
  Lancamento(id: 'x', tipo: t, pote: p, poteDestino: dest, valor: v, fixo: fixo,
    data: data ?? DateTime(2026, 11, 1));

void main() {
  test('saldo adds entradas and subtracts despesas/staff', () {
    final ls = [l(TipoLancamento.entrada, Pote.caixa, 100),
      l(TipoLancamento.despesa, Pote.caixa, 30),
      l(TipoLancamento.pagamentoStaff, Pote.caixa, 20)];
    expect(saldoDoPote(ls, Pote.caixa), 50);
  });
  test('a transfer moves between potes and does not change the total', () {
    final ls = [l(TipoLancamento.entrada, Pote.caixa, 100),
      l(TipoLancamento.transferencia, Pote.caixa, 40, dest: Pote.reserva)];
    expect(saldoDoPote(ls, Pote.caixa), 60);
    expect(saldoDoPote(ls, Pote.reserva), 40);
    expect(total(ls), 100);
  });
  test('gastoFixoMensal sums only fixo of the latest month with any', () {
    final ls = [l(TipoLancamento.pagamentoStaff, Pote.caixa, 8, fixo: true, data: DateTime(2026, 11, 1)),
      l(TipoLancamento.pagamentoStaff, Pote.caixa, 8, fixo: true, data: DateTime(2026, 11, 20)),
      l(TipoLancamento.despesa, Pote.caixa, 50, fixo: false, data: DateTime(2026, 11, 5))];
    expect(gastoFixoMensal(ls), 16);
  });
  test('porMes buckets by month and type', () {
    final ls = [l(TipoLancamento.entrada, Pote.caixa, 100, data: DateTime(2026, 10, 2)),
      l(TipoLancamento.despesa, Pote.caixa, 30, data: DateTime(2026, 11, 2))];
    final m = porMes(ls);
    expect(m.firstWhere((x) => x.mes == 10).entrada, 100);
    expect(m.firstWhere((x) => x.mes == 11).despesa, 30);
  });
  test('round-trips through json', () {
    final x = l(TipoLancamento.entrada, Pote.caixa, 100);
    expect(Lancamento.fromJson(x.toJson()).valor, 100);
  });
}
