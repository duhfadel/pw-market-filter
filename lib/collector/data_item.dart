/// A reparação do atributo `data-item`, partilhada pelos dois mercados.
library;

/// Fecha cada `data-item` pela chave do JSON em vez de pelo apóstrofo.
///
/// **As duas páginas delimitam o atributo com aspas simples e não escapam
/// apóstrofos no conteúdo**, portanto um criador chamado `Antonio'` ou
/// `king[D]oug'` termina o atributo a meio do objecto. O HTML sai assim:
///
/// ```
/// data-item='{… "creator":"king[D]oug'"}'><img …
///                                     ↑ o atributo acaba aqui
/// ```
///
/// O leitor de HTML faz o que deve — lê até ao delimitador — e entrega 999
/// caracteres de JSON cortado. O `jsonDecode` falha, o `catch` devolve nulo,
/// e **a peça fica sem atributos e sem pedras, calada**. Foi assim que o
/// Baekchu apareceu sem as pedras de HP nas calças e nas botas, relatado pelo
/// dono em 21/10/2026, enquanto a página dele as mostrava.
///
/// Medido no índice de 21/10: **854 itens em 337 dos 1.425 personagens**
/// vinham sem atributos nem pedras. Nem todos por esta causa — há peças que
/// de facto não dão nada — mas é o tecto do estrago, e um em cada quatro
/// personagens trazia pelo menos um.
///
/// **A reparação conta chaves em vez de confiar em delimitadores.** O
/// conteúdo é sempre um objecto JSON, portanto o fim é a chave que fecha a
/// primeira; o que estiver pelo caminho e for apóstrofo passa a `&#39;`,
/// que o leitor devolve como apóstrofo outra vez. Um nick com `{` ou `}`
/// derrotaria a contagem — mas esse já derrota a página deles antes de
/// chegar aqui.
///
/// **É a terceira vez que um valor contendo o carácter que o delimita custa
/// alguma coisa neste projecto**, depois da cor de guilda que escapava para
/// um `onload` e do `~` do link que o `Uri` escapava. Vale como forma: quem
/// escreve um contentor delimitado tem de escapar o delimitador, e quem lê
/// não pode contar com isso.
String fecharDataItem(String html) {
  const marca = "data-item='";
  final saida = StringBuffer();
  var i = 0;

  while (true) {
    final j = html.indexOf(marca, i);
    if (j < 0) {
      saida.write(html.substring(i));
      return saida.toString();
    }

    final inicio = j + marca.length;
    saida.write(html.substring(i, inicio));

    // Só objectos: `data-item='null'` é o que a aba escreve para uma peça de
    // moda, e não tem nada a fechar.
    if (!html.startsWith('{', inicio)) {
      i = inicio;
      continue;
    }

    var nivel = 0;
    var k = inicio;
    for (; k < html.length; k++) {
      if (html[k] == '{') {
        nivel++;
      } else if (html[k] == '}') {
        nivel--;
        if (nivel == 0) break;
      }
    }
    if (k >= html.length) {
      // Chave sem fecho: devolve o resto como está, em vez de inventar um
      // fim. Um HTML truncado é problema de quem o serviu.
      saida.write(html.substring(inicio));
      return saida.toString();
    }

    saida.write(html.substring(inicio, k + 1).replaceAll("'", '&#39;'));
    i = k + 1;
  }
}
