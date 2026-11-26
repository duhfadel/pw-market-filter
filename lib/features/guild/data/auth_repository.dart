import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/result/result.dart';
import '../../../core/supabase/cliente.dart';
import '../domain/papel.dart';

/// The guild panel's door. Wraps Supabase Auth; the session and its refresh
/// are the SDK's job, which is the whole reason the dependency was approved.
class AuthRepository {
  Session? get sessao => supa.auth.currentSession;
  Stream<AuthState> get mudancas => supa.auth.onAuthStateChange;

  /// Whether there is a session at all — distinct from having a [Papel]. The
  /// view-model needs this without constructing a [Session], which a test
  /// cannot do.
  bool get temSessao => supa.auth.currentSession != null;

  Future<Result<void>> entrar(String email, String senha) async {
    try {
      await supa.auth.signInWithPassword(email: email.trim(), password: senha);
      return const Success<void>(null);
    } on AuthException {
      // Tipada e genérica de propósito: a tela não revela se o e-mail existe.
      return const Failure(GuildFailure(GuildErro.credenciais));
    } catch (_) {
      return const Failure(GuildFailure(GuildErro.conexao));
    }
  }

  Future<void> sair() => supa.auth.signOut();

  /// O papel do usuário logado, lido de `perfis`. `null` se não há sessão ou
  /// a conta não tem papel — e sem papel não se faz nada.
  Future<Papel?> meuPapel() async {
    final uid = sessao?.user.id;
    if (uid == null) return null;
    try {
      final linha =
          await supa.from('perfis').select('papel').eq('id', uid).maybeSingle();
      return Papel.doBanco(linha?['papel'] as String?);
    } catch (_) {
      return null;
    }
  }
}
