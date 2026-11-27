import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../domain/financeiro/lancamento.dart';

/// Portuguese labels and colours for the ledger and its dialogs — kept in
/// one file so the type tag on a ledger row and the chip in a dialog can
/// never drift into naming the same enum value two different ways.

String rotuloCategoria(CategoriaEntrada c) => switch (c) {
  CategoriaEntrada.guildAtiva => 'Guilda ativa',
  CategoriaEntrada.territorio => 'Território',
  CategoriaEntrada.cashback => 'Cashback',
  CategoriaEntrada.outro => 'Outro',
};

String rotuloPote(Pote p) => switch (p) {
  Pote.caixa => 'Caixa',
  Pote.reserva => 'Reserva',
};

String rotuloTipo(TipoLancamento t) => switch (t) {
  TipoLancamento.entrada => 'Entrada',
  TipoLancamento.despesa => 'Despesa',
  TipoLancamento.pagamentoStaff => 'Pagamento staff',
  TipoLancamento.transferencia => 'Transferência',
};

/// The ledger's own rule for colour: money in is green, the two kinds that
/// leave a pot are red, and a transfer — which `calculos.total` proves never
/// changes the guild's own total — stays neutral. The type tag borrows this
/// rather than keeping a second switch, so the tag and the amount beside it
/// can never disagree about which way the money moved.
Color corTipo(TipoLancamento t) => switch (t) {
  TipoLancamento.entrada => PWColors.ok,
  TipoLancamento.despesa => PWColors.danger,
  TipoLancamento.pagamentoStaff => PWColors.danger,
  TipoLancamento.transferencia => PWColors.apagado,
};
