import '../../../core/result/result.dart';
import '../../../core/supabase/cliente.dart';
import '../domain/financeiro/lancamento.dart';

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
      // Does not send 'id': the database generates it. 'lancado_por_email'
      // is filled from the signed-in session rather than trusted from the
      // caller, so the audit trail cannot be forged by whoever builds the
      // entry.
      final dados = l.toJson()..remove('id');
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
