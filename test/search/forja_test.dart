import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/domain/matcher.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/features/search/domain/search_query_url.dart';
import 'package:pw_market_filter/market/market_index.dart';

MarketCharacter _quem({required String nome, List<int> forja = const []}) =>
    MarketCharacter(
      roleId: nome.hashCode,
      name: nome,
      characterClass: 'Guerreiro',
      occupation: 1,
      level: 102,
      price: 100,
      fame: 0,
      cultivation: 'Leal',
      forja: forja,
      equipped: const [],
    );

final _index = MarketIndex(
  server: 'pw126',
  collectedAt: DateTime.utc(2026, 10, 6),
  attributes: const [],
  items: const {},
  characters: const [],
);

/// Os quatro ofícios de artesanato do 1.2.6, que a página publica por id e
/// nunca por nome.
void main() {
  // Medido em `detail_pw126_62224.html`: os quatro ids dão [7, 7, 7, 8].
  final artesao = _quem(nome: 'artesao', forja: const [7, 7, 7, 8]);
  final aprendiz = _quem(nome: 'aprendiz', forja: const [2, 1, 1, 1]);
  final ninguem = _quem(nome: 'ninguem');

  bool passa(MarketCharacter c, int? minimo) =>
      matchesQuery(_index, c, SearchQuery(forjaMinima: minimo));

  test('o mínimo olha o melhor ofício, não a soma nem o pior', () {
    // Somar artesanatos faria um número que não é quantidade de nada — o
    // mesmo erro que saiu do painel dos Registros. E exigir os quatro
    // responderia a pergunta de quem quer um artesão completo, que é outra.
    expect(passa(artesao, 8), isTrue);
    expect(passa(artesao, 9), isFalse);
    // O pior dos quatro é 7, e isso não o impede de passar em 8.
    expect(passa(artesao, 7), isTrue);
  });

  test('quem não tem a perícia nunca passa, e zero não é nível', () {
    // Lista vazia é ausência, não nível zero: quem não tem artesanato nenhum
    // não pode aparecer numa busca por artesãos.
    expect(passa(ninguem, 1), isFalse);
    expect(ninguem.forja, isEmpty);
    // Sem mínimo, está lá como toda a gente.
    expect(passa(ninguem, null), isTrue);
  });

  test('um nível baixo é um nível, e continua a filtrar', () {
    expect(passa(aprendiz, 2), isTrue);
    expect(passa(aprendiz, 3), isFalse);
  });

  test('o filtro conta como filtro em força', () {
    expect(const SearchQuery().isEmpty, isTrue);
    expect(const SearchQuery(forjaMinima: 8).isEmpty, isFalse);
  });

  test('o link leva e traz o nível de volta', () {
    const query = SearchQuery(forjaMinima: 8);
    final escrito = encodeQuery(query, _index);

    expect(escrito, contains('forja=8'));
    expect(
      decodeQuery(
        Uri.parse('?$escrito').queryParametersAll,
        _index,
      ).forjaMinima,
      8,
    );
  });

  test('o índice guarda os quatro na ordem dos ids, não ordenados', () {
    // É essa ordem que deixa os nomes entrarem um dia sem recolher nada: a
    // tela é que ordena para mostrar.
    final json = artesao.toJson();
    expect(json['forja'], [7, 7, 7, 8]);
    expect(MarketCharacter.fromJson(json).forja, [7, 7, 7, 8]);

    // E quem não tem não gasta bytes nenhuns no índice.
    expect(ninguem.toJson().containsKey('forja'), isFalse);
  });
}
