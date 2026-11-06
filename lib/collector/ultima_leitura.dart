import '../market/market_index.dart';

/// O que sobrevive de uma leitura anterior quando a desta vez vem vazia.
///
/// **Dois campos, e só dois, porque só estes dois não podem mudar para trás.**
/// O sexo de um personagem não muda nunca; o reino celestial só sobe. Portanto
/// a leitura de ontem é, no pior caso, um piso verdadeiro — nunca uma
/// afirmação que o jogo contradiga. Preço, nível e fama mudam nos dois
/// sentidos e **não** entram aqui: arrastá-los seria publicar um número velho
/// com cara de novo, que é a razão pela qual a data da coleta está sempre na
/// tela.
///
/// Nasceu a 06/11/2026, por decisão do dono, depois de o site passar a
/// oscilar entre português e espanhol e duas recolhas completas trazerem
/// **zero de 2.879** nestes dois campos. A pergunta dele foi a certa: se não
/// chegam, deixa-se como estava até se resolver do lado deles. A alternativa
/// era publicar um índice sem o glifo de sexo e sem a ordenação por reino,
/// ou não publicar nada — e o mercado deixar de actualizar.
///
/// **Não é um remendo que esconde o defeito**, e é essa a parte que tem de se
/// manter verdadeira: o coletor conta no fim quantos personagens trouxeram
/// cada campo **fresco**, de modo que uma leitura que colapsa aparece no log
/// da corrida em vez de desaparecer debaixo do arrasto. Ver
/// `censoDosCampos`.
class UltimaLeitura {
  const UltimaLeitura({required this.sex, required this.realm});

  final String sex;
  final String realm;
}

/// O sexo e o reino de cada personagem no índice publicado.
///
/// Vazio quando nunca se publicou um índice, que é o que `publicado == null`
/// já significa em todo o resto deste ficheiro: ninguém foi visto ainda, e
/// não há nada a arrastar.
Map<int, UltimaLeitura> ultimasLeiturasDe(MarketIndex? publicado) => {
  if (publicado != null)
    for (final c in publicado.characters)
      if (c.sex.isNotEmpty || c.realm.isNotEmpty)
        c.roleId: UltimaLeitura(sex: c.sex, realm: c.realm),
};

/// O valor a publicar: o desta coleta, ou o da anterior quando este vem
/// vazio.
///
/// **A ordem importa e é esta:** uma leitura fresca ganha sempre, mesmo que
/// discorde da anterior — é ela que vê o jogo de hoje. O arrasto só preenche
/// ausência.
String comArrasto(String fresco, String? anterior) =>
    fresco.isNotEmpty ? fresco : (anterior ?? '');

/// Quantos personagens trazem cada campo **no estado**, antes de qualquer
/// arrasto.
///
/// **É o estado e não esta corrida**, e a distinção importa para o número não
/// mentir: num `--resume` quase nada é lido de novo, portanto o que isto
/// conta é o que o ficheiro de estado guarda — exactamente o que seria
/// publicado se não houvesse arrasto.
///
/// É a linha que impede o arrasto de se tornar um esconderijo: um campo a
/// zero tem de se ver no log de cada corrida até uma recolha o repor, não
/// meses depois quando alguém nota que o glifo de sexo está igual desde
/// Novembro.
Map<String, int> censoDosCampos(Iterable<UltimaLeitura> noEstado) {
  var sexo = 0;
  var reino = 0;
  for (final f in noEstado) {
    if (f.sex.isNotEmpty) sexo++;
    if (f.realm.isNotEmpty) reino++;
  }
  return {'sexo': sexo, 'reino': reino};
}
