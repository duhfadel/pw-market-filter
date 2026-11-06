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
Set<int> aReler(
  Map<int, CollectedPage> estado,
  Set<int> jaRelidos, {
  int tecto = releiturasPorCorrida,
}) {
  final alvos = <int>{};
  for (final entry in estado.entries) {
    if (alvos.length >= tecto) break;
    if (jaRelidos.contains(entry.key)) continue;
    // **Os dois vazios, não um.** Uma página pode legitimamente não dizer o
    // sexo; não dizer nem o sexo nem o reino é a assinatura da leitura que
    // falhou, porque os dois saem da mesma lista de três linhas da ficha.
    final p = entry.value;
    if (p.sex.isEmpty && p.realm.isEmpty) alvos.add(entry.key);
  }
  return alvos;
}
