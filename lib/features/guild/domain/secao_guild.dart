import 'package:flutter/material.dart';

import 'papel.dart';

/// A section of the guild panel's menu-hub.
///
/// All three are built now. `financeiro` was the last to leave the
/// placeholder state the home's `Tool` already uses for a tool with no
/// route yet — a card dimmed and labelled *em breve* until it had a screen
/// behind it.
enum SecaoGuild {
  jogadores,
  salaGuerras,
  financeiro;

  String get rotulo => switch (this) {
    SecaoGuild.jogadores => 'Jogadores',
    SecaoGuild.salaGuerras => 'Sala de Guerras',
    SecaoGuild.financeiro => 'Financeiro',
  };

  String get subtitulo => switch (this) {
    SecaoGuild.jogadores => 'Quem está na guilda, e a ficha de cada um',
    SecaoGuild.salaGuerras => 'Monta os pts',
    SecaoGuild.financeiro => 'Saldo, lançamentos e o gasto fixo mensal',
  };

  IconData get icone => switch (this) {
    SecaoGuild.jogadores => Icons.groups,
    SecaoGuild.salaGuerras => Icons.shield,
    SecaoGuild.financeiro => Icons.account_balance_wallet,
  };

  /// Whether this section is built. All three are now — `financeiro` was
  /// the last to leave the placeholder state.
  bool get pronta => true;

  /// Whether `papel` may see this card at all — a card that is not visible
  /// for a role is omitted, never drawn disabled, which is the distinction a
  /// role with no business on the players screen needs.
  bool visivelPara(Papel papel) => switch (this) {
    // Jogadores mirrors the server's RLS: sala_guerras has no business here.
    SecaoGuild.jogadores => papel.podeVerJogadores,
    // Not built yet, but it is the home of the sala_guerras role, so every
    // role sees it — including the one it is for.
    SecaoGuild.salaGuerras => true,
    SecaoGuild.financeiro => papel == Papel.admin || papel == Papel.staffEditor,
  };
}
