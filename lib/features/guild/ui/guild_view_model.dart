import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/result.dart';
import '../data/auth_repository.dart';
import 'guild_estado.dart';

/// The guild panel's door: resolves a session into a [Papel] (or the lack of
/// one), and handles signing in and out.
class GuildViewModel extends Cubit<GuildEstado> {
  GuildViewModel(this._auth) : super(const GuildDeslogado());
  final AuthRepository _auth;

  Future<void> resolver() async {
    if (!_auth.temSessao) {
      emit(const GuildDeslogado());
      return;
    }
    emit(const GuildCarregando());
    final papel = await _auth.meuPapel();
    // A signed-in account with no role, or a role that cannot see the
    // roster, gets nothing — the door is the role, not the login, which is
    // why "no access" is a state of its own.
    emit(papel == null || !papel.podeVerJogadores
        ? const GuildSemAcesso()
        : GuildLogado(papel));
  }

  Future<Result<void>> entrar(String email, String senha) async {
    final r = await _auth.entrar(email, senha);
    await r.fold((_) => resolver(), (_) async {});
    return r;
  }

  Future<void> sair() async {
    await _auth.sair();
    emit(const GuildDeslogado());
  }
}
