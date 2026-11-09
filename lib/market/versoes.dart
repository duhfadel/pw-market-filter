import 'market_index.dart';

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
    this.novosHoje,
  });

  /// The version's short name, matching `Servidor.chave` — `pw187`, `pw126`.
  final String chave;

  /// The readable name shown on the door — `1.8.7`, `1.2.6`.
  final String nome;

  /// How many characters were on sale in the collection this row describes.
  final int personagens;

  final DateTime coletadoEm;

  /// Quantos entraram no mercado no dia desta coleta, ou `null` quando a
  /// coleta que escreveu esta linha ainda não sabia contar.
  ///
  /// **Nulo e não zero, e a distinção é a honestidade da porta.** Zero quer
  /// dizer *ninguém entrou hoje*, que é notícia num mercado que se move de
  /// meia em meia hora; ausente quer dizer *esta linha é anterior ao
  /// número*. Escritos iguais, a porta anunciaria um mercado parado onde o
  /// que há é um ficheiro velho — a mesma razão pela qual um conduíte sem
  /// atributo não desenha zero.
  ///
  /// Os `versoes.json` já publicados não o têm, portanto a ausência é parte
  /// do contrato e não um defeito a corrigir.
  final int? novosHoje;

  /// Lê a linha inteira de um índice já construído.
  ///
  /// **Existe porque há dois escritores de `versoes.json`** — a coleta de uma
  /// versão e o `--escrever-versoes` que refaz o ficheiro a partir do disco —
  /// e um campo novo acrescentado à mão nos dois é um campo esquecido em um.
  /// Foi assim que o `require_level` morreu na travessia, e o `sexo`, e a
  /// `escada`.
  factory VersaoResumo.doIndice(
    MarketIndex index, {
    required String chave,
    required String nome,
  }) => VersaoResumo(
    chave: chave,
    nome: nome,
    personagens: index.characters.length,
    coletadoEm: index.collectedAt,
    novosHoje: novosHojeEm(index),
  );

  factory VersaoResumo.fromJson(Map<String, dynamic> json) => VersaoResumo(
    chave: json['chave'] as String,
    nome: json['nome'] as String,
    personagens: json['personagens'] as int,
    coletadoEm: DateTime.parse(json['coletadoEm'] as String),
    // Ausente é informação; escrito com o tipo errado continua a ser defeito.
    novosHoje: json['novosHoje'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'chave': chave,
    'nome': nome,
    'personagens': personagens,
    'coletadoEm': coletadoEm.toIso8601String(),
    if (novosHoje != null) 'novosHoje': novosHoje,
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

/// Quantos personagens entraram no mercado no dia desta coleta.
///
/// **Conta pela mesma regra que o filtro usa** — `PriceHistory.entrouNosUltimos`
/// — e não por uma segunda leitura da mesma pergunta. A porta da versão
/// anuncia um número e o filtro, ao abrir, tem de mostrar exactamente ele;
/// duas contagens é como as duas telas passam a discordar, que é a forma que
/// já custou o pulso da home a 30/09/2026.
///
/// **Sem registo nenhum, dá zero e não nulo.** Um índice sem histórico é a
/// primeira coleta de sempre, onde ninguém *entrou hoje* porque não havia
/// ontem com que comparar — é um facto sobre o mercado, não uma linha velha.
/// A ausência fica reservada para o ficheiro que precede o campo.
int novosHojeEm(MarketIndex index) => index.characters
    .where((c) => c.history?.entrouNosUltimos(1, index.collectedAt) ?? false)
    .length;
