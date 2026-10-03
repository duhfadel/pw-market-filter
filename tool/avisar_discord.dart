import 'dart:convert';
import 'dart:io';

import 'package:pw_market_filter/market/alerta_de_entrada.dart';
import 'package:pw_market_filter/market/endereco_do_mercado.dart';

/// Where the private feed goes. Absent on a developer's machine, which is why
/// nothing is posted there: a local `--rebuild` must never put a message in
/// somebody's channel.
const _variavel = 'DISCORD_ALERTAS';

/// Posts one message naming the characters that have just entered the market
/// carrying something off [vigiaDeItens].
///
/// **A failure here can never take the collection down.** The run's whole
/// point is the index and the deploy; a Discord outage must not cost those.
/// But it is not swallowed either — it prints a `::warning::`, so the day the
/// webhook is revoked the run summary says so instead of the channel just
/// going quiet. That distinction is the lesson the visit counter paid for:
/// a `catch` that exists to keep a feature quiet will keep its bugs quiet too.
Future<void> avisarEntradas(List<EntradaNova> entradas, String servidor) async {
  if (entradas.isEmpty) return;

  final url = Platform.environment[_variavel];
  if (url == null || url.isEmpty) {
    stdout.writeln(
      '$_variavel não definido: ${entradas.length} entrada(s) não enviadas',
    );
    return;
  }

  try {
    await _postar(url, _mensagem(entradas, servidor));
    stdout.writeln('Discord: ${entradas.length} entrada(s) anunciadas');
  } catch (e) {
    stdout.writeln('::warning::falha ao avisar o Discord: $e');
  }
}

/// One message per run rather than one per character.
///
/// A run normally has one or two entries, and a webhook is rate limited per
/// webhook rather than per channel — so a quiet batch costs one request and a
/// loud one does not risk being throttled halfway through and announcing half
/// the arrivals.
String _mensagem(List<EntradaNova> entradas, String servidor) {
  if (entradas.length > limiteDeEnxurrada) {
    // Our own bookkeeping, not the market — see [limiteDeEnxurrada]. Said out
    // loud rather than silently dropped: a quiet feed and a broken feed look
    // identical from the channel.
    return '**$servidor** · ${entradas.length} personagens marcados como novos '
        'nesta coleta, acima do limite de $limiteDeEnxurrada. '
        'Quase de certeza é a memória do site que se perdeu, não o mercado — '
        'nada foi listado para o canal não ficar inútil.';
  }

  final linhas = <String>['**Entrou agora no mercado** · $servidor', ''];
  for (final e in entradas) {
    final itens = [
      for (final achado in e.achados.entries) '${achado.key} ×${achado.value}',
    ].join(' · ');

    linhas.addAll([
      '**${e.nome}** — ${e.preco} TCC · nv ${e.nivel} ${e.classe}',
      itens,
      enderecoDoPersonagem(servidor, e.roleId),
      '',
    ]);
  }
  return linhas.join('\n');
}

Future<void> _postar(String url, String conteudo) async {
  final cliente = HttpClient();
  try {
    final pedido = await cliente.postUrl(Uri.parse(url));
    pedido.headers.contentType = ContentType.json;
    pedido.write(jsonEncode({'content': conteudo}));
    final resposta = await pedido.close();
    await resposta.drain<void>();
    if (resposta.statusCode >= 300) {
      throw HttpException('o webhook respondeu ${resposta.statusCode}');
    }
  } finally {
    cliente.close();
  }
}

/// The one-off catch-up: everybody who already carries [item].
///
/// **Chunked, because Discord refuses a message over 2.000 characters and a
/// list of carriers has no ceiling.** The 1.8.7 market has 364 characters
/// above the coupon's floor; sending that as one message would fail entirely
/// rather than arrive truncated, which is the worst of both.
///
/// The whole list is in the run's log either way — the channel is for reading
/// at a glance, the log for reading in full.
Future<void> avisarLevantamento(
  List<EntradaNova> portadores,
  String item,
  String servidor,
) async {
  if (item.isEmpty || portadores.isEmpty) return;

  final url = Platform.environment[_variavel];
  if (url == null || url.isEmpty) {
    stdout.writeln('$_variavel não definido: levantamento não enviado');
    return;
  }

  final linhas = [
    for (final p in portadores)
      '**${p.nome}** — ${p.preco} TCC · nv ${p.nivel} ${p.classe} · '
          '**${p.achados[item]}**',
  ];

  var bloco = <String>['**Quem já carrega $item** · $servidor', ''];
  var tamanho = bloco.join('\n').length;
  final blocos = <String>[];

  for (final linha in linhas) {
    if (tamanho + linha.length + 1 > 1900) {
      blocos.add(bloco.join('\n'));
      bloco = <String>[];
      tamanho = 0;
    }
    bloco.add(linha);
    tamanho += linha.length + 1;
  }
  if (bloco.isNotEmpty) blocos.add(bloco.join('\n'));

  try {
    for (final texto in blocos) {
      await _postar(url, texto);
      // Um webhook aceita 5 pedidos por segundo; meio segundo entre blocos
      // mantém uma lista longa bem dentro disso sem nunca ser estrangulada
      // a meio e anunciar metade dos portadores.
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    stdout.writeln(
      'Discord: levantamento de "$item" enviado em ${blocos.length} parte(s)',
    );
  } catch (e) {
    stdout.writeln('::warning::falha ao enviar o levantamento: $e');
  }
}
