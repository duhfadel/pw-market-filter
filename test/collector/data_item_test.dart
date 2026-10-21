import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/data_item.dart';

/// A reparação do `data-item`, sozinha.
///
/// Os dois mercados delimitam esse atributo com aspas simples e não escapam
/// apóstrofos no conteúdo — ver `apostrofo_no_criador_test` para o caso real
/// que isto custou no 1.2.6. Aqui prova-se a mecânica, que o caso real não
/// consegue isolar.
void main() {
  test('um apóstrofo no conteúdo deixa de fechar o atributo', () {
    const partido =
        '<li data-item=\'{"id":1,"creator":"Antonio\'"}\'><img></li>';

    final curado = fecharDataItem(partido);

    expect(curado, contains('&#39;'));
    expect(curado, contains('"creator":"Antonio&#39;"}'));
  });

  test('o que não tem apóstrofo fica byte a byte igual', () {
    // A reparação reescreve o HTML inteiro antes de alguém o ler. Mexer onde
    // não é preciso seria arriscar tudo o que já funciona por um caso raro.
    const inteiro = '<li data-item=\'{"id":1,"creator":"Antonio"}\'><img></li>';

    expect(fecharDataItem(inteiro), inteiro);
  });

  test('`data-item=\'null\'` passa intacto', () {
    // É o que a aba escreve para uma peça de moda, e não tem chave nenhuma
    // a fechar — contar chaves ali correria até ao fim do documento.
    const moda = '<li data-item=\'null\'><img></li>';

    expect(fecharDataItem(moda), moda);
  });

  test('objectos encaixados contam-se até à chave certa', () {
    // `slots.slotStones` é um objecto dentro do objecto. Parar na primeira
    // chave de fecho cortaria o item a meio.
    const encaixado =
        '<li data-item=\'{"a":{"b":1},"creator":"X\'"}\'><img></li>';

    final curado = fecharDataItem(encaixado);

    expect(curado, contains('{"a":{"b":1},"creator":"X&#39;"}'));
  });

  test('uma chave sem fecho devolve o resto como está', () {
    // HTML truncado é problema de quem o serviu. Inventar um fim seria
    // afirmar uma estrutura que ninguém viu.
    const truncado = '<li data-item=\'{"id":1,"crea';

    expect(fecharDataItem(truncado), truncado);
  });

  test('vários atributos na mesma página reparam-se todos', () {
    const dois =
        '<li data-item=\'{"a":"X\'"}\'></li><li data-item=\'{"b":"Y\'"}\'></li>';

    final curado = fecharDataItem(dois);

    expect(curado, contains('{"a":"X&#39;"}'));
    expect(curado, contains('{"b":"Y&#39;"}'));
  });
}
