import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/pw_colors.dart';
import '../data/auth_repository.dart';
import 'guild_estado.dart';
import 'guild_view_model.dart';
import 'login_view.dart';
import 'roster_view.dart';

/// `/newageguild`, the guild panel's door: resolves whoever is reading into
/// one of its four states and shows the screen that answers it.
class GuildView extends StatelessWidget {
  const GuildView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GuildViewModel(getIt<AuthRepository>())..resolver(),
      child: BlocBuilder<GuildViewModel, GuildEstado>(
        builder: (context, estado) {
          final vm = context.read<GuildViewModel>();
          return switch (estado) {
            GuildDeslogado() => LoginView(vm: vm),
            GuildCarregando() => const Scaffold(
              backgroundColor: PWColors.surface,
              body: Center(
                child: CircularProgressIndicator(color: PWColors.accent),
              ),
            ),
            // RosterView already brings its own Scaffold+AppBar; Sair becomes one of its actions.
            GuildLogado(:final papel) => RosterView(
              papel: papel,
              onSair: vm.sair,
            ),
            GuildSemAcesso() => Scaffold(
              backgroundColor: PWColors.surface,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Esta conta não tem acesso ao painel.',
                      style: TextStyle(color: PWColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: vm.sair,
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              ),
            ),
          };
        },
      ),
    );
  }
}
