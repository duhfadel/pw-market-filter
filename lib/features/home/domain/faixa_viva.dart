import '../../../market/market_index.dart';
import '../../search/domain/matcher.dart';
import '../../search/domain/search_query.dart';

/// One figure of the live strip: a number somebody can click through to.
class FiguraViva {
  const FiguraViva({
    required this.numero,
    required this.rotulo,
    required this.query,
  });

  final int numero;

  /// What the number counts, written for somebody who has never been here.
  final String rotulo;

  /// The filter this figure opens, with the question already asked. A figure
  /// whose query answered a different number would be a door that lies, which
  /// is why [figurasVivas] counts through the matcher rather than by hand.
  final SearchQuery query;
}

/// The three numbers of the live strip, in reading order.
///
/// **Every number is counted by the matcher**, never by a hand-written loop
/// beside it. The strip and the grid it opens answer the same question, and
/// two readings of one question are how a figure and its own results come to
/// disagree — the shape that already cost this project the pulse of the home
/// in 30/09/2026, where the figures built their own `SearchQuery` while the
/// chips were built elsewhere.
///
/// **A figure nobody answers is kept, showing zero.** The market moves on its
/// own every half hour, and a strip whose middle number vanishes on a quiet
/// day reads as a broken page rather than as a quiet day. The same reason the
/// rebirth chips are drawn dimmed instead of dropped.
List<FiguraViva> figurasVivas(MarketIndex index) {
  int conta(SearchQuery query) =>
      index.characters.where((c) => matchesQuery(index, c, query)).length;

  const hoje = SearchQuery(novosEmDias: 1);
  const queda = SearchQuery(soComQueda: true);

  // **A ordem e a da maquete, e ela poe o movimento primeiro.** O total vem
  // no fim porque e o numero que menos muda -- esta no selo logo acima, com a
  // data da coleta, e repeti-lo em primeiro lugar dava a faixa viva o ar de
  // um resumo em vez de um movimento.
  return [
    FiguraViva(numero: conta(hoje), rotulo: 'entraram hoje', query: hoje),
    FiguraViva(numero: conta(queda), rotulo: 'baixaram o preço', query: queda),
    FiguraViva(
      numero: index.characters.length,
      rotulo: 'à venda agora',
      query: const SearchQuery(),
    ),
  ];
}
