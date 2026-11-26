import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pw_market_filter/core/result/result.dart';
import 'package:pw_market_filter/features/guild/data/auth_repository.dart';
import 'package:pw_market_filter/features/guild/domain/papel.dart';
import 'package:pw_market_filter/features/guild/ui/guild_estado.dart';
import 'package:pw_market_filter/features/guild/ui/guild_view_model.dart';

class _FakeAuth implements AuthRepository {
  _FakeAuth({required this.logado, this.papel});
  bool logado;
  final Papel? papel;
  @override bool get temSessao => logado;
  @override Future<Papel?> meuPapel() async => papel;
  @override Future<Result<void>> entrar(String e, String s) async { logado = true; return const Success<void>(null); }
  @override Future<void> sair() async { logado = false; }
  @override Session? get sessao => null;
  @override Stream<AuthState> get mudancas => const Stream.empty();
}

void main() {
  test('no session resolves to logged out', () async {
    final vm = GuildViewModel(_FakeAuth(logado: false));
    await vm.resolver();
    expect(vm.state, isA<GuildDeslogado>());
  });

  test('session with a role resolves to logged in with that role', () async {
    final vm = GuildViewModel(_FakeAuth(logado: true, papel: Papel.admin));
    await vm.resolver();
    expect(vm.state, isA<GuildLogado>());
    expect((vm.state as GuildLogado).papel, Papel.admin);
  });

  test('session without a role resolves to no access', () async {
    final vm = GuildViewModel(_FakeAuth(logado: true, papel: null));
    await vm.resolver();
    expect(vm.state, isA<GuildSemAcesso>());
  });
}
