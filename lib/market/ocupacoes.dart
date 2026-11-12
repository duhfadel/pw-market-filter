/// Que número de ocupação pertence a cada classe, que é o nome do ficheiro do
/// ícone.
///
/// **É um facto do jogo e não uma leitura da recolha**, e é essa a diferença
/// que o justifica existir ao lado de `IndexFacets.occupationOf`. Aquele
/// mapa diz *que classes apareceram neste índice*, portanto encolhe com o
/// mercado e desaparece quando não há recolha; este diz *como se chama o
/// ícone do Bardo*, que é verdade com ou sem mercado. Uma ferramenta de
/// planeamento pessoal não pode ficar sem ícones porque a loja fechou.
///
/// **Medido e não suposto.** Sobre os 2.977 personagens do índice de
/// 11/11/2026, as dezassete classes casam com exactamente uma ocupação cada
/// — zero ambiguidades. `ocupacoes_test` repete a conferência contra o
/// índice que estiver em `web/`, para o dia em que o jogo acrescentar uma
/// classe não ser descoberto por um ícone em falta.
const ocupacaoDaClasse = <String, int>{
  'Guerreiro': 0,
  'Mago': 1,
  'Espiritualista': 2,
  'Feiticeira': 3,
  'Bárbaro': 4,
  'Mercenário': 5,
  'Arqueiro': 6,
  'Sacerdote': 7,
  'Arcano': 8,
  'Místico': 9,
  'Retalhador': 10,
  'Tormentador': 11,
  'Atiradora': 12,
  'Paladino': 13,
  'Andarilho': 14,
  'Bardo': 15,
  'Ceifador': 16,
};

/// As dezassete, pela ordem da ocupação — que é a ordem em que o jogo as
/// apresenta, e não a alfabética.
final classesDoJogo = ocupacaoDaClasse.keys.toList(growable: false);
