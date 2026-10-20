/// Como se escreve o valor de um atributo na tela.
///
/// **Existe desde que os atributos passaram a ser decimais**, em 20/10/2026.
/// Quase tudo o que o jogo publica é inteiro — `Nível de Ataque +70`, `HP
/// +500` — e escrever `70.0` ali seria uma precisão que ninguém pediu e que
/// o próprio jogo não mostra. Mas o conduíte escreve `HP +69.60` e o livro
/// divino `Intervalo de Ataque -0.05s`, e arredondar o segundo dá `0`, que
/// lido diz *não muda* quando muda.
///
/// Portanto: inteiro quando é inteiro, decimal quando não é.
///
/// **Vírgula e não ponto**, porque a tela é em português e o resto do site
/// já separa milhares com ponto — `1.750 personagens`. Misturar as duas
/// convenções na mesma página é como um número começa a ser lido ao
/// contrário.
String numeroDeAtributo(double valor) {
  if (valor == valor.roundToDouble()) return valor.toInt().toString();

  // Duas casas chegam: é o que a página deles mostra — `+69.60`, `-0.05` — e
  // um zero à direita que a fonte não tem não acrescenta nada.
  var texto = valor.toStringAsFixed(2);
  while (texto.endsWith('0')) {
    texto = texto.substring(0, texto.length - 1);
  }
  if (texto.endsWith('.')) texto = texto.substring(0, texto.length - 1);
  return texto.replaceAll('.', ',');
}
