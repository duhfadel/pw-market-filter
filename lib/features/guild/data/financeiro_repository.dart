import '../../../core/result/result.dart';
import '../../../core/supabase/cliente.dart';
import '../domain/financeiro/lancamento.dart';

/// The insert payload for a new lançamento: `toJson()` with the two keys the
/// database must decide for itself rather than the caller — `id` (its own
/// generator) and `data` (its own `default (now() at time zone
/// 'America/Sao_Paulo')::date`). Pulled out of [FinanceiroRepository.adicionar]
/// so the rule can be pinned by a plain unit test without touching the live
/// Supabase client, the way this project tests every other pure
/// transformation.
///
/// `data` matters here for the same reason `VisitRepository._today` already
/// subtracts three hours from UTC: the dialogs build `Lancamento.data` from
/// `DateTime.now()`, which is whichever day the caller's own browser clock
/// says. Sending that would make a non-Brazil staffer lançando near local
/// midnight record the wrong day — wrong month in the chart, wrong bucket
/// for `gastoFixoMensal`. Leaving the key out lets the column's own
/// Brazil-timezone default decide instead.
Map<String, dynamic> dadosParaInserir(Lancamento l) => l.toJson()
  ..remove('id')
  ..remove('data');

/// Reads and writes `lancamentos`, the guild's ledger of income, expenses,
/// staff payments and transfers between pots.
class FinanceiroRepository {
  Future<Result<List<Lancamento>>> lista() async {
    try {
      final linhas = await supa
          .from('lancamentos')
          .select()
          .order('data', ascending: false);
      return Success([for (final l in linhas) Lancamento.fromJson(l)]);
    } catch (_) {
      return const Failure(GuildFailure(GuildErro.carregar));
    }
  }

  Future<Result<void>> adicionar(Lancamento l) async {
    try {
      // 'lancado_por_email' is filled from the signed-in session rather
      // than trusted from the caller, so the audit trail cannot be forged
      // by whoever builds the entry. See [dadosParaInserir] for why 'id'
      // and 'data' are left out of the payload entirely.
      final dados = dadosParaInserir(l);
      dados['lancado_por_email'] = supa.auth.currentUser?.email;
      await supa.from('lancamentos').insert(dados);
      return const Success<void>(null);
    } catch (_) {
      return const Failure(GuildFailure(GuildErro.salvar));
    }
  }

  Future<Result<void>> remover(String id) async {
    try {
      await supa.from('lancamentos').delete().eq('id', id);
      return const Success<void>(null);
    } catch (_) {
      return const Failure(GuildFailure(GuildErro.salvar));
    }
  }
}
