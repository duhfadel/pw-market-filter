import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/result/result.dart';
import '../../../core/theme/pw_colors.dart';
import '../../../core/theme/pw_theme.dart';
import '../data/jogadores_repository.dart';
import '../domain/jogador.dart';
import '../domain/papel.dart';
import 'mensagens.dart';
import 'roster_state.dart';
import 'roster_view_model.dart';
import 'widgets/jogador_form.dart';

/// The guild panel's roster: who is in the guild and what has been read off
/// their sheet print so far.
///
/// Image upload (the print itself) is deliberately not here — it is the next
/// piece, isolated on purpose because the web file-picker side of it is
/// fiddly and does not need to hold this list up.
class RosterView extends StatelessWidget {
  const RosterView({required this.papel, this.onSair, super.key});

  final Papel papel;

  /// When non-null, the AppBar grows a "Sair" action that calls it — the
  /// guild door's own job, not this screen's, so it stays null for the
  /// existing tests that mount `RosterView` on its own.
  final VoidCallback? onSair;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => RosterViewModel(getIt<JogadoresRepository>(), papel)..carregar(),
    child: _Tela(onSair: onSair),
  );
}

class _Tela extends StatelessWidget {
  const _Tela({this.onSair});

  final VoidCallback? onSair;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PWColors.surface,
      appBar: AppBar(
        backgroundColor: PWColors.surface,
        title: const Text(
          'Jogadores',
          style: TextStyle(fontFamily: PWTheme.display, color: PWColors.papel),
        ),
        actions: onSair == null
            ? null
            : [
                TextButton(
                  onPressed: onSair,
                  style: TextButton.styleFrom(foregroundColor: PWColors.textMuted),
                  child: const Text('Sair'),
                ),
              ],
      ),
      body: BlocBuilder<RosterViewModel, RosterState>(
        builder: (context, state) => switch (state) {
          RosterLoading() => const Center(
            child: CircularProgressIndicator(color: PWColors.accent),
          ),
          RosterFalha() => const Center(
            child: Text(
              'Não deu para carregar os jogadores.',
              style: TextStyle(color: PWColors.textMuted),
            ),
          ),
          RosterPronto() => _Pronto(state: state),
        },
      ),
    );
  }
}

class _Pronto extends StatelessWidget {
  const _Pronto({required this.state});

  final RosterPronto state;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<RosterViewModel>();
    final podeEditar = state.papel.podeEditarJogadores;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            if (podeEditar)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FilledButton.icon(
                  onPressed: () => mostrarJogadorForm(context, vm),
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Adicionar jogador'),
                ),
              ),
            if (state.jogadores.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Ainda não há jogador nenhum cadastrado.',
                  style: TextStyle(color: PWColors.textMuted),
                ),
              )
            else
              for (final j in state.jogadores) _LinhaJogador(j),
          ],
        ),
      ),
    );
  }
}

class _LinhaJogador extends StatelessWidget {
  const _LinhaJogador(this.jogador);

  final Jogador jogador;

  /// `classe · limite · NA <nivelAtaque> · HP <hp>`, skipping whatever the
  /// print has not been read yet — an absent stat is "not informed", never
  /// zero.
  String? get _subtitulo {
    final partes = <String>[
      if (jogador.classe != null) jogador.classe!,
      if (jogador.limite != null) jogador.limite!,
      if (jogador.nivelAtaque != null) 'NA ${jogador.nivelAtaque}',
      if (jogador.hp != null) 'HP ${jogador.hp}',
    ];
    return partes.isEmpty ? null : partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final subtitulo = _subtitulo;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(jogador.nome, style: const TextStyle(color: PWColors.papel, fontSize: 16)),
                if (subtitulo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitulo,
                      style: const TextStyle(color: PWColors.textMuted, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          if (!jogador.transcrito)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: _SeloPendente(),
            ),
        ],
      ),
    );
  }
}

/// A sheet print nobody has transcribed yet — the player exists in the
/// roster and nothing past the name is real.
class _SeloPendente extends StatelessWidget {
  const _SeloPendente();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: PWColors.elevado,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: PWColors.filete),
    ),
    child: const Text(
      'à espera de leitura',
      style: TextStyle(color: PWColors.textMuted, fontSize: 11),
    ),
  );
}

void mostrarJogadorForm(BuildContext context, RosterViewModel vm) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => JogadorForm(
      onSalvar: (jogador) async {
        final ok = await vm.adicionar(jogador);
        if (ok) {
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        } else {
          if (dialogContext.mounted) {
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              SnackBar(content: Text(mensagemDoGuildErro(GuildErro.salvar))),
            );
          }
        }
      },
    ),
  );
}
