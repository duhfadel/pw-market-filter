import 'package:flutter/material.dart';
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

  // **O mecanismo, montado aqui, e não uma ferramenta nomeada.** A versão
  // anterior cravava o *Títulos* como exemplo, e ficou vermelha no dia em que
  // os selos foram rodados — 23/10/2026 — sem nada estar partido. Qual entrada
  // carrega o selo é decisão de produto e muda de mês a mês; o que tem de
  // continuar verdade é que a data o apaga sozinha.
  test('o badge de novo vence sozinho', () {
    final marcada = Tool(
      name: 'qualquer',
      tagline: 'x',
      icon: Icons.star,
      secao: 'Ferramentas',
      novoAte: DateTime.utc(2026, 10, 20),
    );

    expect(marcada.novoEm(DateTime.utc(2026, 10, 19)), isTrue);
    expect(marcada.novoEm(DateTime.utc(2026, 10, 21)), isFalse);
  });

  // E a lista a sério continua a ser varrida: qualquer selo que lá esteja tem
  // de ter data, porque um *novo* sem prazo é o que esta regra existe para
  // impedir. Não diz quantos são, que é o que muda.
  test('nenhum selo de novo na lista real fica sem prazo', () {
    for (final t in tools) {
      if (t.novoEm(DateTime.utc(2026, 1, 1))) {
        expect(t.novoAte, isNotNull, reason: '${t.name} mostra novo sem data');
      }
    }
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
