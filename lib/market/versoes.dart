/// One row of `web/versoes.json` — what the version-chooser screen reads
/// instead of downloading a 4 MB index per version to show two numbers.
///
/// Pure Dart, no `dart:io`: this is a model shared by the collector, which
/// writes the file, and the future chooser screen, which reads it. The
/// writing itself — reading the file off disk, merging, saving — is
/// `tool/collect.dart`'s job, because that part touches the filesystem and
/// `market/` depends on nothing.
class VersaoResumo {
  const VersaoResumo({
    required this.chave,
    required this.nome,
    required this.personagens,
    required this.coletadoEm,
  });

  /// The version's short name, matching `Servidor.chave` — `pw187`, `pw126`.
  final String chave;

  /// The readable name shown on the door — `1.8.7`, `1.2.6`.
  final String nome;

  /// How many characters were on sale in the collection this row describes.
  final int personagens;

  final DateTime coletadoEm;

  factory VersaoResumo.fromJson(Map<String, dynamic> json) => VersaoResumo(
    chave: json['chave'] as String,
    nome: json['nome'] as String,
    personagens: json['personagens'] as int,
    coletadoEm: DateTime.parse(json['coletadoEm'] as String),
  );

  Map<String, dynamic> toJson() => {
    'chave': chave,
    'nome': nome,
    'personagens': personagens,
    'coletadoEm': coletadoEm.toIso8601String(),
  };
}

/// Decodes the whole file: one row per known version, keyed by [VersaoResumo.chave].
Map<String, VersaoResumo> versoesFromJson(Map<String, dynamic> json) => {
  for (final entry in json.entries)
    entry.key: VersaoResumo.fromJson(entry.value as Map<String, dynamic>),
};

/// Encodes the whole file. Every row — not just the one a single run just
/// collected — because a run collects one version and the file holds every
/// version this site has ever published a door for.
Map<String, dynamic> versoesToJson(Map<String, VersaoResumo> versoes) => {
  for (final entry in versoes.entries) entry.key: entry.value.toJson(),
};
