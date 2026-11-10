import 'collected_page.dart';

/// Quantos personagens sem campo se releem por corrida.
///
/// **O tecto é o que torna isto diferente de um carimbo novo.** Subir o
/// carimbo deita fora o estado inteiro e obriga a uma recolha de ~150
/// minutos, que não grava cache se estourar o tecto e tranca o site. Isto
/// repara aos poucos: 200 páginas são ~11 minutos a 3,2 s, cabem na meia
/// hora entre corridas com folga, e o site publica em todas elas.
///
/// Duzentos e não mais, porque a regra do espaçamento é dura: a corrida mais
/// lenta tem de caber entre duas, e a mais lenta já medida é de 18 minutos.
const releiturasPorCorrida = 200;

/// A razão por que se relê, como número.
///
/// **A memória do que já foi relido tem de poder ser esquecida, e esta é a
/// única forma honesta de o fazer.** `relidos` existe para que ninguém seja
/// relido duas vezes pelo mesmo motivo — mas quando o motivo muda, a memória
/// passa a guardar a resposta a outra pergunta.
///
/// Aconteceu logo à primeira: a reparação de 06/11 releu o mercado inteiro
/// por faltarem sexo e reino, e a causa só foi encontrada no dia seguinte —
/// a língua era sorteada por pedido. Com a causa corrigida, as mesmas 2.881
/// páginas precisam de ser relidas outra vez, e `relidos` dizia que já
/// estavam.
///
/// Subir este número esquece tudo, uma vez. É o carimbo do `CollectedPage`
/// em pequeno, e pela mesma razão: um número é uma decisão explícita, e
/// «falta esta chave?» não é.
///
/// **Foi a 3 a 10/11/2026, e o motivo é outro.** A reparação do sexo e do
/// reino acabou — zero personagens sem um ou sem outro no índice daquela
/// manhã —, e o lugar passou a servir os títulos de fundador: o parser lia o
/// primeiro card do documento em vez do mais alto, portanto quem tivesse dois
/// pacotes ficou com o grau errado guardado. A memória tinha de ser esquecida
/// para eles voltarem à fila.
const motivoDaReleitura = 3;

/// Os personagens a reler por lhes faltar o que a página tem.
///
/// **Uma vez cada, e é [jaRelidos] que o garante.** Sem essa memória, um
/// personagem cuja página genuinamente não imprime o campo seria relido em
/// todas as corridas para sempre — que é exactamente a razão pela qual o
/// carimbo é um número e não a pergunta «falta esta chave?». Com ela, cada
/// um custa uma página, uma vez, e o conjunto esgota-se sozinho.
///
/// Nasceu a 06/11/2026: o site traduziu-se a meio de duas recolhas, o sexo e
/// o reino vieram vazios em 2.879 personagens, e o arrasto da última leitura
/// boa salvou 2.785 deles no índice — mas o **estado** continuou vazio, e o
/// estado é de onde a próxima recolha parte.
///
/// **A 10/11/2026 passou a servir outro campo, e isso é o normal e não uma
/// excepção.** O sexo e o reino estão reparados — zero em falta no índice
/// daquela manhã — e o critério passou a ser o título de fundador: o parser
/// devolvia o primeiro card do documento em vez do mais alto, portanto quem
/// tem dois pacotes decodificados ficou com o grau errado guardado. A Madara
/// tinha `Fundador X` e `Fundador VII`, e o índice dizia 7.
///
/// **São 186 de 2.961 — dez minutos**, contra as duas horas e meia que subir
/// o carimbo custaria. É exactamente a diferença para que este ficheiro
/// existe: reparar aos poucos sem deitar fora o estado.
///
/// Quem não tem título nenhum fica de fora: nestes a leitura não pode estar
/// errada, porque não há card nenhum para o parser escolher mal.
Set<int> aReler(
  Map<int, CollectedPage> estado,
  Set<int> jaRelidos, {
  int tecto = releiturasPorCorrida,
}) {
  final alvos = <int>{};
  for (final entry in estado.entries) {
    if (alvos.length >= tecto) break;
    if (jaRelidos.contains(entry.key)) continue;
    // **Quem tem título de fundador, e só esses.** Sem card nenhum o parser
    // não teve nada para escolher mal, portanto a leitura não pode estar
    // errada — e pô-los na fila gastaria duas horas e meia da rede deles
    // para confirmar o que já se sabe.
    //
    // O critério anterior era *sem sexo ou sem reino*, e vale guardar o que
    // ele ensinou: começou por exigir **os dois** vazios, porque enquanto a
    // causa era desconhecida essa era a assinatura prudente de uma leitura
    // falhada. Com a causa encontrada — a língua era sorteada por pedido —
    // faltar **um** passou a bastar, e foi exactamente o caso que escapava:
    // o reino vinha do painel `Alma Celeste` e o sexo ficava vazio.
    final p = entry.value;
    if ((p.titles?.founder ?? '').isNotEmpty) alvos.add(entry.key);
  }
  return alvos;
}
