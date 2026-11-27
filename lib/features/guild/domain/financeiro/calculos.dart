import 'lancamento.dart';

/// The totals of a single calendar month, bucketed by entry type.
class MesFinanceiro {
  final int ano;
  final int mes;
  final int entrada;
  final int despesa;
  final int staff;

  MesFinanceiro({
    required this.ano,
    required this.mes,
    required this.entrada,
    required this.despesa,
    required this.staff,
  });
}

/// The balance of one pot, summing every lançamento that touches it.
///
/// `entrada` adds to its own pot; `despesa` and `pagamentoStaff` subtract
/// from theirs; a `transferencia` subtracts from its `pote` (the origin) and
/// adds to its `poteDestino`.
int saldoDoPote(List<Lancamento> lancamentos, Pote p) {
  var saldo = 0;
  for (final l in lancamentos) {
    switch (l.tipo) {
      case TipoLancamento.entrada:
        if (l.pote == p) saldo += l.valor;
      case TipoLancamento.despesa:
      case TipoLancamento.pagamentoStaff:
        if (l.pote == p) saldo -= l.valor;
      case TipoLancamento.transferencia:
        if (l.pote == p) saldo -= l.valor;
        if (l.poteDestino == p) saldo += l.valor;
    }
  }
  return saldo;
}

/// The sum of both pots. A transfer moves money between them and therefore
/// never changes this number.
int total(List<Lancamento> lancamentos) {
  return saldoDoPote(lancamentos, Pote.caixa) +
      saldoDoPote(lancamentos, Pote.reserva);
}

/// The sum of `fixo` lançamentos' `valor` in the most recent calendar month
/// that has any — 0 if none exist.
int gastoFixoMensal(List<Lancamento> lancamentos) {
  final fixos = lancamentos.where((l) => l.fixo).toList();
  if (fixos.isEmpty) return 0;

  (int, int) chave(Lancamento l) => (l.data.year, l.data.month);
  final maisRecente = fixos
      .map(chave)
      .reduce((a, b) {
        if (a.$1 != b.$1) return a.$1 > b.$1 ? a : b;
        return a.$2 > b.$2 ? a : b;
      });

  var soma = 0;
  for (final l in fixos) {
    if (chave(l) == maisRecente) soma += l.valor;
  }
  return soma;
}

/// Buckets lançamentos by (ano, mes), summing entrada/despesa/staff per
/// month, ordered chronologically.
List<MesFinanceiro> porMes(List<Lancamento> lancamentos) {
  final buckets = <(int, int), (int, int, int)>{};
  for (final l in lancamentos) {
    final chave = (l.data.year, l.data.month);
    final atual = buckets[chave] ?? (0, 0, 0);
    switch (l.tipo) {
      case TipoLancamento.entrada:
        buckets[chave] = (atual.$1 + l.valor, atual.$2, atual.$3);
      case TipoLancamento.despesa:
        buckets[chave] = (atual.$1, atual.$2 + l.valor, atual.$3);
      case TipoLancamento.pagamentoStaff:
        buckets[chave] = (atual.$1, atual.$2, atual.$3 + l.valor);
      case TipoLancamento.transferencia:
        buckets[chave] = atual;
    }
  }

  final chaves = buckets.keys.toList()
    ..sort((a, b) {
      if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
      return a.$2.compareTo(b.$2);
    });

  return chaves.map((chave) {
    final v = buckets[chave]!;
    return MesFinanceiro(
      ano: chave.$1,
      mes: chave.$2,
      entrada: v.$1,
      despesa: v.$2,
      staff: v.$3,
    );
  }).toList();
}
