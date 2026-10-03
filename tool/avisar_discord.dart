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
