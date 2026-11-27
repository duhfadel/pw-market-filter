import 'runa.dart';

/// A snapshot of a player's sheet at one transcription. The image that
/// produced it is discarded; this is what stays and stacks over time.
class Ficha {
  Ficha({
    required this.jogadorId,
    required this.dados,
    required this.runas,
    this.id,
    this.criadaEm,
    this.criadoPor,
  });
  final String? id;
  final String jogadorId;
  final DateTime? criadaEm;
  final String? criadoPor;
  final Map<String, dynamic> dados; // the ~25 attributes, snake_case keys
  final List<Runa> runas;
  factory Ficha.fromJson(Map<String, dynamic> j) => Ficha(
    id: j['id'] as String?,
    jogadorId: j['jogador_id'] as String,
    criadaEm: j['criada_em'] != null
        ? DateTime.parse(j['criada_em'] as String)
        : null,
    criadoPor: j['criado_por'] as String?,
    dados: Map<String, dynamic>.from(j['dados'] as Map? ?? {}),
    runas: [
      for (final r in (j['runas'] as List? ?? []))
        Runa.fromJson(Map<String, dynamic>.from(r as Map)),
    ],
  );
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'jogador_id': jogadorId,
    if (criadoPor != null) 'criado_por': criadoPor,
    'dados': dados,
    'runas': [for (final r in runas) r.toJson()],
  };
}
