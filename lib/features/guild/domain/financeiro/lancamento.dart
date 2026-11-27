/// The kind of a financial entry: money in, money out, a staff payment, or a
/// transfer between the two pots.
enum TipoLancamento {
  entrada,
  despesa,
  pagamentoStaff,
  transferencia;

  /// The string stored in the database for this value.
  String get banco {
    switch (this) {
      case TipoLancamento.entrada:
        return 'entrada';
      case TipoLancamento.despesa:
        return 'despesa';
      case TipoLancamento.pagamentoStaff:
        return 'pagamento_staff';
      case TipoLancamento.transferencia:
        return 'transferencia';
    }
  }

  /// Looks up the enum value for a database string.
  static TipoLancamento doBanco(String valor) {
    return TipoLancamento.values.firstWhere(
      (t) => t.banco == valor,
      orElse: () => throw ArgumentError('TipoLancamento desconhecido: $valor'),
    );
  }
}

/// Which pot a lançamento affects: the day-to-day cash box or the reserve.
enum Pote {
  caixa,
  reserva;

  /// The string stored in the database for this value.
  String get banco {
    switch (this) {
      case Pote.caixa:
        return 'caixa';
      case Pote.reserva:
        return 'reserva';
    }
  }

  /// Looks up the enum value for a database string.
  static Pote doBanco(String valor) {
    return Pote.values.firstWhere(
      (p) => p.banco == valor,
      orElse: () => throw ArgumentError('Pote desconhecido: $valor'),
    );
  }
}

/// The category of an income entry.
enum CategoriaEntrada {
  guildAtiva,
  territorio,
  cashback,
  outro;

  /// The string stored in the database for this value.
  String get banco {
    switch (this) {
      case CategoriaEntrada.guildAtiva:
        return 'guild_ativa';
      case CategoriaEntrada.territorio:
        return 'territorio';
      case CategoriaEntrada.cashback:
        return 'cashback';
      case CategoriaEntrada.outro:
        return 'outro';
    }
  }

  /// Looks up the enum value for a database string.
  static CategoriaEntrada doBanco(String valor) {
    return CategoriaEntrada.values.firstWhere(
      (c) => c.banco == valor,
      orElse: () => throw ArgumentError('CategoriaEntrada desconhecida: $valor'),
    );
  }
}

/// One financial movement of the guild: an income, an expense, a staff
/// payment, or a transfer between pots.
class Lancamento {
  final String id;
  final TipoLancamento tipo;
  final Pote pote;
  final Pote? poteDestino;
  final int valor;
  final CategoriaEntrada? categoria;
  final String? descricao;
  final String? membro;
  final bool fixo;
  final DateTime data;
  final String? lancadoPorEmail;

  Lancamento({
    required this.id,
    required this.tipo,
    required this.pote,
    this.poteDestino,
    required this.valor,
    this.categoria,
    this.descricao,
    this.membro,
    this.fixo = false,
    required this.data,
    this.lancadoPorEmail,
  });

  factory Lancamento.fromJson(Map<String, dynamic> json) {
    return Lancamento(
      id: json['id'] as String,
      tipo: TipoLancamento.doBanco(json['tipo'] as String),
      pote: Pote.doBanco(json['pote'] as String),
      poteDestino: json['pote_destino'] == null
          ? null
          : Pote.doBanco(json['pote_destino'] as String),
      valor: json['valor'] as int,
      categoria: json['categoria'] == null
          ? null
          : CategoriaEntrada.doBanco(json['categoria'] as String),
      descricao: json['descricao'] as String?,
      membro: json['membro'] as String?,
      fixo: json['fixo'] as bool? ?? false,
      data: DateTime.parse(json['data'] as String),
      lancadoPorEmail: json['lancado_por_email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final dataStr =
        '${data.year.toString().padLeft(4, '0')}-'
        '${data.month.toString().padLeft(2, '0')}-'
        '${data.day.toString().padLeft(2, '0')}';
    return {
      'id': id,
      'tipo': tipo.banco,
      'pote': pote.banco,
      'pote_destino': poteDestino?.banco,
      'valor': valor,
      'categoria': categoria?.banco,
      'descricao': descricao,
      'membro': membro,
      'fixo': fixo,
      'data': dataStr,
      'lancado_por_email': lancadoPorEmail,
    };
  }
}
