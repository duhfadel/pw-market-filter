/// Escreve a lista de `web/guias/index.html` a partir de `guias`.
///
/// **Só a lista, e isso é deliberado.** O cabeçalho da página — as etiquetas
/// `og:`, o canónico, a tag do AdSense — continua escrito à mão onde está, e
/// é conferido por `test/web/paginas_html_test.dart`. Trazer isso para dentro
/// de um gerador seria reescrever o que já funciona e está testado, para
/// resolver um problema que não é esse.
///
/// O problema é outro: **houve duas listas de guias que não sabiam uma da
/// outra**, e um artigo publicado ficou dias sem caminho a partir do site. A
/// lista passa a sair de `lib/features/guias/domain/guia.dart`, que é a mesma
/// que a app lê.
///
/// ```
/// dart run tool/guias/pagina.dart            escreve
/// dart run tool/guias/pagina.dart --conferir sai 1 se o disco discordar
/// ```
///
/// O `--conferir` é o que o teste usa: mexer na declaração e não regenerar
/// passaria a página a dizer uma coisa e a app outra, que é exactamente a
/// divergência que isto existe para fechar.
library;

import 'dart:io';

import 'package:pw_market_filter/features/guias/domain/guia.dart';

/// As marcas que já estavam no ficheiro, postas lá para este momento.
const _inicio = '    <!-- INÍCIO DA LISTA -->';
const _fim = '    <!-- FIM DA LISTA -->';

/// As versões que a barra oferece, na ordem em que o site as mostra.
const versoesOferecidas = ['1.8.7', '1.2.6', '1.4.4'];

/// Palavras por minuto. **Um número redondo e assumido como tal**: a medida
/// serve para separar «dois minutos» de «quinze», não para prometer precisão
/// que ninguém pode verificar.
const palavrasPorMinuto = 200;

void main(List<String> args) {
  final conferir = args.contains('--conferir');
  final caminho = 'web/guias/index.html';
  final original = File(caminho).readAsStringSync();
  final novo = paginaCom(original);

  if (!conferir) {
    File(caminho).writeAsStringSync(novo);
    stdout.writeln('escrito $caminho');
    for (final guia in guias) {
      final medida = guia.medida ?? '${minutosDe(guia)} min';
      stdout.writeln('  ${guia.titulo.padRight(42)} $medida');
    }
    return;
  }

  if (novo == original) {
    stdout.writeln('$caminho está em dia');
    return;
  }
  stderr.writeln(
    '$caminho discorda da declaração — corre '
    '`dart run tool/guias/pagina.dart`',
  );
  exit(1);
}

/// Troca a região da lista de [original] pela lista declarada.
///
/// **Não há data nenhuma aqui, e isso é a correcção.** A primeira versão
/// desenhava o selo *novo* no momento de gerar, portanto a página em disco
/// deixava de concordar com a regeneração no dia em que o primeiro selo
/// expirasse — e o `--conferir` que o teste usa ficaria vermelho sem defeito
/// nenhum. Era um gate de publicação cuja entrada era o calendário, que é a
/// forma que já congelou este site duas vezes.
///
/// O selo vive agora em `data-publicado` e é desenhado pelo browser, no
/// relógio de quem visita. Numa página estática é o único relógio que há.
String paginaCom(String original) {
  final i = original.indexOf(_inicio);
  final f = original.indexOf(_fim);
  if (i < 0 || f < 0) {
    throw StateError('as marcas da lista não estão em web/guias/index.html');
  }
  final antes = original.substring(0, i);
  final depois = original.substring(f + _fim.length);
  return '$antes$_inicio\n${listaHtml()}$_fim$depois';
}

/// A barra de filtro e as cartas.
String listaHtml() {
  final out = StringBuffer();

  // A barra conta **quantos guias há dentro de cada versão**, pela mesma
  // razão que as pílulas do cabeçalho contam: um botão que diz «1.2.6» sem
  // número promete tanto quanto o «1.8.7» ao lado, e entrega um oitavo.
  out.writeln(
    '    <div class="filtro-versao" role="group" '
    'aria-label="Filtrar guias por versão">',
  );
  out.writeln(
    '      <button type="button" class="chip-versao atual" '
    'data-ver="todos">Todos <span class="conta">${guias.length}</span>'
    '</button>',
  );
  for (final versao in versoesOferecidas) {
    final quantos = guiasDe(versao).length;
    out.writeln(
      '      <button type="button" class="chip-versao" '
      'data-ver="$versao"><span class="algarismos">$versao</span> '
      '<span class="conta">$quantos</span></button>',
    );
  }
  out.writeln('    </div>');
  out.writeln();

  for (final guia in guias) {
    // Vazio quer dizer todas, e no atributo isso escreve-se por extenso: o
    // filtro é lido por JavaScript, e um atributo vazio ali seria «não serve
    // nenhuma» em vez de «serve todas».
    final serve = guia.versoes.isEmpty
        ? versoesOferecidas
        : versoesOferecidas.where(guia.versoes.contains);
    final medida = guia.medida ?? '${minutosDe(guia)} min de leitura';
    final etiqueta = guia.versoes.isEmpty
        ? 'todas as versões'
        : guia.versoes.toList().join(' · ');

    // `data-publicado` em vez do selo: ver a nota de [paginaCom]. A data vai
    // em ISO para o `Date` do browser a ler sem adivinhar formato.
    final dia = guia.publicado.toIso8601String().substring(0, 10);
    out.writeln(
      '    <a class="guia" href="${guia.endereco}" '
      'data-versoes="${serve.join(',')}" data-publicado="$dia">',
    );
    out.writeln(
      '      <div class="titulo">${_comAlgarismos(guia.titulo)}'
      '</div>',
    );
    out.writeln(
      '      <div class="linha">${_comAlgarismos(guia.linha)}'
      '</div>',
    );
    out.writeln(
      '      <div class="meta"><span class="versao">'
      '${_comAlgarismos(etiqueta)}</span> · '
      '<span class="duracao">${_comAlgarismos(medida)}</span></div>',
    );
    out.writeln('    </a>');
  }
  return out.toString();
}

/// Minutos de leitura, medidos do próprio ficheiro.
int minutosDe(Guia guia) {
  final arquivo = guia.arquivo;
  if (arquivo == null) {
    // As multi contas vivem na app: não há HTML para contar. O ecrã é curto
    // e **assumido** em vez de adivinhado a partir de nada.
    return 4;
  }
  final palavras = palavrasDe(File(arquivo).readAsStringSync());
  final minutos = (palavras / palavrasPorMinuto).ceil();
  return minutos < 1 ? 1 : minutos;
}

/// Conta as palavras do `<main>` de uma página.
///
/// **Só o `<main>`**, e é o que separa uma medida de um número. O cabeçalho,
/// o rodapé e o bloco de publicidade repetem-se em todas as páginas: contados,
/// davam a um guia de dois parágrafos o mesmo peso de base que a um de trinta.
/// Os comentários HTML saem também — este repositório escreve-os longos, e
/// contá-los mediria a conversa sobre o guia em vez do guia.
int palavrasDe(String html) {
  final main = RegExp(r'<main[^>]*>(.*)</main>', dotAll: true).firstMatch(html);
  var texto = main?.group(1) ?? html;
  texto = texto.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), ' ');
  texto = texto.replaceAll(
    RegExp(r'<(script|style)[^>]*>.*?</\1>', dotAll: true),
    ' ',
  );
  texto = texto.replaceAll(RegExp(r'<[^>]+>'), ' ');
  return texto
      .split(RegExp(r'\s+'))
      .where((p) => p.replaceAll(RegExp(r'[^\wÀ-ÿ]'), '').isNotEmpty)
      .length;
}

/// Põe os algarismos fora da Marcellus.
///
/// A folha dos guias põe Marcellus nos títulos, e ela desenha algarismos
/// romanos: `nível 10` saiu **`nível IO`** numa página publicada. `.algarismos`
/// devolve o número à pilha do sistema. Aplicado aqui a todo o texto gerado
/// porque um título novo com um dígito é uma questão de tempo.
String _comAlgarismos(String texto) => texto.replaceAllMapped(
  RegExp(r'\d+(?:[.,]\d+)*'),
  (m) => '<span class="algarismos">${m[0]}</span>',
);
