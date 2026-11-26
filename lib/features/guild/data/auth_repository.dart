import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/result/result.dart';
import '../../../core/supabase/cliente.dart';
import '../domain/papel.dart';

/// The guild panel's door. Wraps Supabase Auth; the session and its refresh
/// are the SDK's job, which is the whole reason the dependency was approved.
class AuthRepository {
  Session? get sessao => supa.auth.currentSession;

  /// Whether there is a session at all — distinct from having a [Papel]. The
  /// view-model needs this without constructing a [Session], which a test
  /// cannot do.
  bool get temSessao => supa.auth.currentSession != null;

  Future<Result<void>> entrar(String email, String senha) async {
    try {
      await supa.auth.signInWithPassword(email: email.trim(), password: senha);
      return const Success<void>(null);
    } on AuthException {
      // Typed and generic on purpose: the screen never reveals whether the e-mail exists.
      return const Failure(GuildFailure(GuildErro.credenciais));
    } catch (_) {
      return const Failure(GuildFailure(GuildErro.conexao));
    }
  }

  Future<void> sair() => supa.auth.signOut();

  /// The logged-in user's role, read from `perfis`. `null` if there is no
  /// session or the account has no role — and with no role, nothing happens.
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
