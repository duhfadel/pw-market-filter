/// Harvests the socket stones' names, and does it in 32 page reads.
///
/// Usage:
///   dart run tool/pedras.dart            # lê o índice publicado
///   dart run tool/pedras.dart --server pw126
///
/// **Porque é que isto existe em vez de o coletor guardar o nome.** A página
/// traz a pedra como imagem *e* como texto — `<img …/51112.png width="16"> `
/// seguido de `Pedra do Olho Vermelho Ataque +75` — mas `ParsedItem.stones`
/// guarda só o id, e sempre guardou. Ensinar o parser a guardar o nome muda
/// `CollectedPage`, o que carimba todo o estado como velho e obriga a reler
/// **1.666 páginas** do servidor deles. Por 79 nomes que são do jogo e não do
/// mercado, isso é pagar o preço do que muda para obter o que não muda — a
/// mesma troca que a regra do `--resume` recusa.
///
/// **O índice diz quem usa o quê, então as páginas escolhem-se em vez de se
/// sortearem.** Cada personagem publicado traz a lista de ids por peça, o que
/// permite uma cobertura gulosa: a cada passo lê-se quem traz mais pedras
/// ainda sem nome. Medido em 20/10/2026 sobre o 1.8.7, as 79 pedras do mercado
/// inteiro cabem em **32 páginas** — 96 segundos ao ritmo de sempre, contra 83
/// minutos de recolha completa.
///
/// A saída é Dart para `lib/market/pedras.dart`, conferida à mão antes de
/// entrar — o mesmo arranjo de `card_combos.dart`, e pelo mesmo motivo: uma
/// tabela que o índice não consegue dar.
library;

import 'dart:convert';
import 'dart:io';

import 'package:html/parser.dart' as html_parser;

import 'package:pw_market_filter/collector/servidor.dart';
import 'package:pw_market_filter/market/market_index.dart';
import 'package:pw_market_filter/market/pedras.dart';

const _userAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/120.0 Safari/537.36';

/// O mesmo ritmo do coletor. O bloqueio do site é a razão, e ele não distingue
/// uma ferramenta pequena de uma grande.
const _pausa = Duration(milliseconds: 1500);

/// A pedra é a única imagem de 16 px dentro de um tooltip, e o nome é o texto
/// logo a seguir — até ao `<` que fecha o trecho.
///
/// **Corre sobre o atributo descodificado, nunca sobre o HTML cru.** A página
/// escreve o tooltip escapado — `&lt;img …` — portanto um `<img` procurado no
/// texto da página encontra zero e devolve "nenhuma pedra tem nome", que é a
/// mesma falha silenciosa que a nota do `Erupção Demoníaca` regista: ler por
/// cima da fonte em vez de através do parser.
final _pedra = RegExp(
  r'<img[^>]+src="[^"]*?/(\d+)\.png"[^>]*?width="16"[^>]*>\s*([^<]+)',
);

Future<void> main(List<String> arguments) async {
  final chave = _arg(arguments, '--server') ?? 'pw187';
  final servidor = Servidor.de(chave);

  final index = MarketIndex.fromJson(
    jsonDecode(File(servidor.arquivoDoIndice).readAsStringSync())
        as Map<String, dynamic>,
  );

  final porPersonagem = <int, Set<int>>{};
  for (final c in index.characters) {
    final suas = <int>{for (final i in c.equipped) ...i.stones};
    if (suas.isNotEmpty) porPersonagem[c.roleId] = suas;
  }
  final todas = <int>{for (final s in porPersonagem.values) ...s};
  stdout.writeln(
    '${todas.length} pedras distintas em ${porPersonagem.length} '
    'personagens.',
  );

  // Cobertura gulosa: a página que traz mais pedras ainda sem nome.
  final faltam = {...todas};
  final paginas = <int>[];
  while (faltam.isNotEmpty) {
    var melhor = 0;
    var ganho = 0;
    for (final e in porPersonagem.entries) {
      final n = e.value.where(faltam.contains).length;
      if (n > ganho) {
        ganho = n;
        melhor = e.key;
      }
    }
    if (ganho == 0) break;
    paginas.add(melhor);
    faltam.removeAll(porPersonagem.remove(melhor)!);
  }
  stdout.writeln(
    '${paginas.length} páginas cobrem todas — '
    '~${(paginas.length * _pausa.inMilliseconds / 1000).round()} s.',
  );

  final nomes = <int, String>{};
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  try {
    for (var i = 0; i < paginas.length; i++) {
      final html = await _get(client, servidor.detalhe(paginas[i]));
      if (html == null) {
        stdout.writeln('  ${paginas[i]}: não veio, seguindo');
      } else {
        var novas = 0;
        final tooltips = html_parser
            .parse(html)
            .querySelectorAll('[data-pw187-tooltip]')
            .map((e) => e.attributes['data-pw187-tooltip'] ?? '');
        for (final m in tooltips.expand(_pedra.allMatches)) {
          final id = int.parse(m.group(1)!);
          final nome = m.group(2)!.trim();
          if (nome.isEmpty || nomes.containsKey(id)) continue;
          nomes[id] = nome;
          novas++;
        }
        stdout.writeln(
          '  ${i + 1}/${paginas.length} · ${paginas[i]} · '
          '+$novas · ${nomes.length}/${todas.length}',
        );
      }
      if (i + 1 < paginas.length) await Future<void>.delayed(_pausa);
    }
  } finally {
    client.close(force: true);
  }

  final semNome = todas.where((id) => !nomes.containsKey(id)).toList()..sort();
  if (semNome.isNotEmpty) {
    stdout.writeln(
      '\nSem nome, e isso é um facto e não um erro: uma pedra que '
      'ninguém desta amostra mostrou no tooltip. ${semNome.join(', ')}',
    );
  }

  // O que já está na tabela não é reimpresso como novidade: o valor desta
  // corrida é o que ela acrescenta.
  final novas = nomes.keys.where((id) => !nomesDasPedras.containsKey(id));
  stdout.writeln('\n// ${nomes.length} nomes; ${novas.length} novos.');
  final ids = nomes.keys.toList()..sort();
  for (final id in ids) {
    final marca = nomesDasPedras.containsKey(id) ? '' : '  // novo';
    stdout.writeln("  $id: '${nomes[id]!.replaceAll("'", r"\'")}',$marca");
  }
}

String? _arg(List<String> args, String nome) {
  final i = args.indexOf(nome);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}

Future<String?> _get(HttpClient client, String url) async {
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set(HttpHeaders.userAgentHeader, _userAgent);
    request.headers.set(HttpHeaders.acceptLanguageHeader, 'pt-BR,pt;q=0.9');
    request.headers.set(HttpHeaders.acceptEncodingHeader, 'gzip');
    final response = await request.close();
    if (response.statusCode != 200) {
      await response.drain<void>();
      return null;
    }
    return await response.transform(utf8.decoder).join();
  } on SocketException {
    return null;
  } on HttpException {
    return null;
  }
}
