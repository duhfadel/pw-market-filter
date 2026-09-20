import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/domain/tool.dart';

void main() {
  test('as seções saem uma vez, e continuam saindo na segunda chamada', () {
    // O primeiro esboço guardava as vistas num Set global: funcionava uma vez
    // e devolvia lista vazia depois, que é o tipo de defeito que só aparece
    // quando a tela reconstrói.
    expect(secoesDaHome, secoesDaHome);
    expect(secoesDaHome.toSet().length, secoesDaHome.length);
    expect(secoesDaHome, contains('Ferramentas'));
  });

  test('o badge de novo vence sozinho', () {
    final titulos = tools.firstWhere((t) => t.name == 'Títulos');

    expect(titulos.novoEm(DateTime.utc(2026, 9, 21)), isTrue);
    expect(titulos.novoEm(DateTime.utc(2026, 11, 1)), isFalse);
  });

  test('o que não tem data nunca mostra badge', () {
    final filtro = tools.firstWhere((t) => t.name == 'Filtro do Marketplace');

    expect(filtro.novoEm(DateTime.utc(2026, 9, 21)), isFalse);
  });

  test('cada card aparece em exatamente uma seção', () {
    final somadas = [for (final s in secoesDaHome) ...toolsDe(s)];

    expect(somadas.length, tools.length);
  });
}
