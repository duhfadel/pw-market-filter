import 'package:flutter/material.dart';

import '../../../core/supabase/cliente.dart';
import '../../../core/theme/pw_colors.dart';
import '../../../core/theme/pw_theme.dart';
import '../domain/papel.dart';
import '../domain/secao_guild.dart';
import 'financeiro/fin_view.dart';
import 'guerra/sala_view.dart';
import 'roster_view.dart';

/// `/newageguild`'s menu-hub: one card per [SecaoGuild] the signed-in [papel]
/// may see. All three — *Jogadores*, *Sala de Guerras* and *Financeiro* —
/// are built and navigate on tap.
class MenuView extends StatelessWidget {
  const MenuView({required this.papel, this.onSair, super.key});

  final Papel papel;

  /// When non-null, the top bar grows a "Sair" action — the guild door's own
  /// job, which used to live on `RosterView` and now lives here, since the
  /// menu is the screen every role lands on first.
  final VoidCallback? onSair;

  /// Defensive on purpose: a widget test that mounts this screen on its own
  /// never calls `Supabase.initialize`, and `Supabase.instance` throws
  /// rather than answering null in that case.
  String? get _email {
    try {
      return supa.auth.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  // "Papel: …" rather than the bare role name: a bare "Sala de Guerras" here
  // would be indistinguishable, to a widget test and to a skimming eye, from
  // the section card of the same name just below.
  String get _rotuloPapel => switch (papel) {
    Papel.admin => 'Papel: admin',
    Papel.staffEditor => 'Papel: staff (editor)',
    Papel.staffBasico => 'Papel: staff',
    Papel.salaGuerras => 'Papel: sala de guerras',
  };

  @override
  Widget build(BuildContext context) {
    final secoes = SecaoGuild.values.where((s) => s.visivelPara(papel)).toList();
    final email = _email;
    return Scaffold(
      backgroundColor: PWColors.surface,
      appBar: AppBar(
        backgroundColor: PWColors.surface,
        title: const Text(
          'NewAge',
          style: TextStyle(fontFamily: PWTheme.display, color: PWColors.papel),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                email == null ? _rotuloPapel : '$email · $_rotuloPapel',
                style: const TextStyle(color: PWColors.textMuted, fontSize: 13),
              ),
            ),
          ),
          if (onSair != null)
            TextButton(
              onPressed: onSair,
              style: TextButton.styleFrom(foregroundColor: PWColors.textMuted),
              child: const Text('Sair'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final colunas = constraints.maxWidth >= 720
                ? 3
                : (constraints.maxWidth >= 480 ? 2 : 1);
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: colunas,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: 168,
              ),
              itemCount: secoes.length,
              itemBuilder: (context, i) =>
                  _CartaoSecao(secao: secoes[i], papel: papel),
            );
          },
        ),
      ),
    );
  }
}

class _CartaoSecao extends StatelessWidget {
  const _CartaoSecao({required this.secao, required this.papel});

  final SecaoGuild secao;
  final Papel papel;

  void _abrir(BuildContext context) {
    switch (secao) {
      case SecaoGuild.jogadores:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RosterView(papel: papel)),
        );
      case SecaoGuild.salaGuerras:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SalaGuerrasView()));
      case SecaoGuild.financeiro:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const FinanceiroView()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pronta = secao.pronta;
    return Material(
      color: PWColors.painel,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: pronta ? () => _abrir(context) : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                secao.icone,
                size: 32,
                color: pronta ? PWColors.accent : PWColors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                secao.rotulo,
                style: TextStyle(
                  fontFamily: PWTheme.display,
                  fontSize: 18,
                  color: pronta ? PWColors.papel : PWColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                secao.subtitulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: PWColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
