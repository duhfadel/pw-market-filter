// Builds an index out of the saved fixtures, with no network.
//
//   dart run tool/build_fixture_index.dart
//
// It is the whole market's roster with one character's gear — enough to see
// the screen work before a real collection has run, and enough to catch a
// pipeline that produces an index the app cannot read.
//
// **E ele escreve por cima do índice real, o que custou uma suíte vermelha.**
// Doze testes leem `web/market_index.json` como *o mercado* — presets, combos,
// emblemas, Destaques — e contra uma fixture de 27 itens falham todos de uma
// vez, com o aspecto de um defeito no código que se acabou de escrever. O
// ficheiro é ignorado pelo git, portanto nem `git status` o denuncia.
//
// Por isso o real é guardado ao lado antes de ser pisado, e
//
//   dart run tool/build_fixture_index.dart --repor
//
// põe-no de volta. Uma cópia e não um caminho separado: a app lê
// `web/market_index.json` e mais nada, e é essa a razão de a ferramenta
// escrever ali.

import 'dart:convert';
import 'dart:io';

import 'package:pw_market_filter/collector/detail_parser.dart';
import 'package:pw_market_filter/collector/index_builder.dart';
import 'package:pw_market_filter/collector/listing_parser.dart';

const _real = 'web/market_index.json';
const _guardado = 'web/market_index.real.json';

void main(List<String> args) {
  if (args.contains('--repor')) {
    final copia = File(_guardado);
    if (!copia.existsSync()) {
      stderr.writeln('Não há $_guardado para repor.');
      exitCode = 1;
      return;
    }
    copia.renameSync(_real);
    stdout.writeln('$_real reposto a partir da cópia.');
    return;
  }

  final real = File(_real);
  // Só guarda se ainda não houver cópia: correr a ferramenta duas vezes
  // seguidas não pode trocar o índice real pela fixture da primeira corrida.
  if (real.existsSync() && !File(_guardado).existsSync()) {
    real.copySync(_guardado);
    stdout.writeln('$_real guardado em $_guardado');
  }

  final listing = parseListing(
    File('test/fixtures/listing_pw187.html').readAsStringSync(),
  );
  final page = File('test/fixtures/detail_64112.html').readAsStringSync();
  final items = parseEquippedItems(page);

  // **O Mulexta entra porque é o único com os três itens ricos.** O Leandrim
  // tem astrolábio e conduíte modestos e nenhum livro divino; sem este, uma
  // tela construída das fixtures não mostra a escada do livro nem duas
  // ocorrências do mesmo atributo, que são precisamente os casos que custam
  // caro para ver no mercado real.
  final rica = File('test/fixtures/detail_92624.html').readAsStringSync();
  final itensRicos = parseEquippedItems(rica);

  final builder = IndexBuilder(
    server: 'pw187',
    collectedAt: DateTime.now().toUtc(),
  );
  // O Mulexta não está nesta listagem — ela é de Agosto e ele apareceu
  // depois —, portanto as peças dele vão para o segundo anúncio da lista. É
  // uma ferramenta de pré-visualização: o que importa é a tela ter um
  // personagem com os três itens ricos para desenhar.
  var posicao = -1;
  for (final card in listing) {
    posicao++;
    final his = card.roleId == 64112;
    final ele = posicao == 1;
    builder.add(
      card,
      his
          ? items
          : ele
          ? itensRicos
          : const [],
      anecdotes: his ? parseAnecdotes(page) : null,
      inventory: his ? parseInventory(page) : const [],
      realm: his
          ? parseCelestialRealm(page) ?? ''
          : ele
          ? parseCelestialRealm(rica) ?? ''
          : '',
      path: his ? parsePath(page) ?? '' : '',
      runes: his ? parseRunes(page) : const [],
    );
  }

  final index = builder.build();
  final json = jsonEncode(index.toJson());
  File('web/market_index.json').writeAsStringSync(json);

  stdout
    ..writeln('web/market_index.json — ${(json.length / 1024).round()} KB')
    ..writeln('  personagens: ${index.characters.length}')
    ..writeln(
      '  com equipamento: '
      '${index.characters.where((c) => c.equipped.isNotEmpty).length}',
    )
    ..writeln('  atributos: ${index.attributes.length}')
    ..writeln('  itens contados: ${index.countedItems.length}')
    ..writeln('')
    ..writeln(
      'Para repor o mercado real: '
      'dart run tool/build_fixture_index.dart --repor',
    );
}
