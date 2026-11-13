import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/domain/canal_ao_vivo.dart';

/// Reading the version off a stream title.
///
/// **Falsos positivos são o único dano real**, e é o que ordena tudo aqui:
/// não mostrar alguém custa visibilidade, mostrá-lo na versão errada é o site
/// a afirmar o que não sabe. Daí o casamento conservador — e daí este
/// ficheiro ter mais casos de recusa do que de aceitação.
void main() {
  group('as formas que contam', () {
    test('a forma com pontos, como o próprio mercado a escreve', () {
      expect(versaoDaTransmissao('The Classic PW 1.8.7'), '1.8.7');
    });

    test('o título real medido a 09/11/2026', () {
      // O único canal em directo nesse dia, e o que provou a regra num caso
      // verdadeiro em vez de inventado.
      expect(versaoDaTransmissao('THE CLASSIC PW 1.4.4 BETA ABERTO'), '1.4.4');
    });

    test('o número colado às letras, que é como se escreve de facto', () {
      // `\b` não serve aqui: entre `W` e `1` não há fronteira de palavra
      // nenhuma, portanto um `\b187\b` perderia a grafia mais comum de todas.
      expect(versaoDaTransmissao('pw187 hoje'), '1.8.7');
      expect(versaoDaTransmissao('PW126 rate baixa'), '1.2.6');
    });

    test('o número sozinho', () {
      expect(versaoDaTransmissao('jogando 144 beta'), '1.4.4');
    });

    test('não importa a caixa nem os emoji à volta', () {
      expect(versaoDaTransmissao('🔥 the classic 1.2.6 🔥'), '1.2.6');
    });
  });

  group('o que não conta, e é a metade que importa', () {
    test('título nenhum', () {
      expect(versaoDaTransmissao(null), isNull);
      expect(versaoDaTransmissao(''), isNull);
    });

    test('sem versão nenhuma', () {
      expect(versaoDaTransmissao('Perfect World com os amigos'), isNull);
    });

    test('duas versões nomeadas contam como não saber', () {
      // Decisão minha e barata de mudar: quem escreve as duas não disse em
      // qual está, e escolher uma por ordem de aparição seria o site a
      // inventar a resposta.
      expect(versaoDaTransmissao('migrando do 1.2.6 para o 1.8.7'), isNull);
      expect(versaoDaTransmissao('pw187 vs pw126'), isNull);
    });

    test('a mesma versão duas vezes conta uma', () {
      // Duas menções da mesma coisa não são ambiguidade.
      expect(versaoDaTransmissao('1.8.7 — the classic pw187'), '1.8.7');
    });

    test('um número maior que contém o nosso não conta', () {
      // `2187` e `1870` contêm `187`, e um limite ingénuo apanhá-los-ia.
      expect(versaoDaTransmissao('cheguei aos 2187 pontos'), isNull);
      expect(versaoDaTransmissao('1870 de ataque'), isNull);
      expect(versaoDaTransmissao('1265/2756 anedotas'), isNull);
    });

    test('um número com decimais não conta', () {
      expect(versaoDaTransmissao('drop de 187.5k'), isNull);
      expect(versaoDaTransmissao('187k de dano'), isNull);
    });

    test('a perda conhecida, cravada para o preço ser visível', () {
      // `187k` é dano ou ouro, e títulos destes estão cheios de números com
      // `k`, portanto a forma nua recusa a letra depois. O preço é este:
      // `PW187BR`, que ninguém escreveu ainda, também é recusado. A forma com
      // pontos não tem esta restrição porque não tem como ser outra coisa.
      expect(versaoDaTransmissao('PW187BR ao vivo'), isNull);
      expect(versaoDaTransmissao('PW 1.8.7BR ao vivo'), '1.8.7');
    });

    test('uma versão que o site não serve não é adivinhada', () {
      expect(versaoDaTransmissao('the classic pw 1.5.1'), isNull);
    });
  });

  group('o filtro por versão', () {
    // A composição que a tela faz: o cubit responde «está ao vivo neste
    // jogo», igual em todas as telas, e a faixa responde «pertence a esta
    // tela». São duas perguntas e por isso duas funções.
    List<CanalAoVivo> naTela(
      List<CanalAoVivo> canais,
      DateTime agora, {
      String? versao,
    }) => [
      for (final c in aoVivoAgora(canais, agora))
        if (transmiteAVersao(c, versao)) c,
    ];

    CanalAoVivo canal(String nome, {String? titulo}) => CanalAoVivo(
      canal: nome.toLowerCase(),
      nome: nome,
      aoVivo: true,
      titulo: titulo,
      jogo: 'Perfect World',
      espectadores: 10,
      vistoEm: DateTime.utc(2026, 11, 9, 14),
    );

    final agora = DateTime.utc(2026, 11, 9, 14, 2);

    final todos = [
      canal('DoOitoSete', titulo: 'The Classic PW 1.8.7'),
      canal('DoDoisSeis', titulo: 'pw126 rate baixa'),
      canal('SemVersao', titulo: 'Perfect World com os amigos'),
    ];

    test('uma página de versão mostra só quem a nomeia', () {
      expect(naTela(todos, agora, versao: '1.8.7').map((c) => c.nome), [
        'DoOitoSete',
      ]);
      expect(naTela(todos, agora, versao: '1.2.6').map((c) => c.nome), [
        'DoDoisSeis',
      ]);
    });

    test('sem versão no título, não entra em página de versão nenhuma', () {
      // Decisão do dono. O custo é visível a quem transmite e resolve-se
      // escrevendo a versão no título.
      for (final versao in const ['1.8.7', '1.2.6', '1.4.4']) {
        expect(
          naTela(todos, agora, versao: versao).map((c) => c.nome),
          isNot(contains('SemVersao')),
        );
      }
    });

    test('sem versão pedida, mostra todos — e é a raiz', () {
      // A raiz não é de versão nenhuma, portanto não afirma nada ao mostrar
      // quem não escreveu a sua.
      expect(naTela(todos, agora).map((c) => c.nome), hasLength(3));
    });

    test('o filtro não desfaz as outras regras', () {
      // Velho continua a não ser ao vivo, mesmo nomeando a versão certa.
      final velho = CanalAoVivo(
        canal: 'velho',
        nome: 'Velho',
        aoVivo: true,
        titulo: 'The Classic PW 1.8.7',
        jogo: 'Perfect World',
        espectadores: 999,
        vistoEm: DateTime.utc(2026, 11, 9, 13),
      );
      expect(naTela([velho], agora, versao: '1.8.7'), isEmpty);
    });

    test('e continua a ordenar pelos mais vistos', () {
      final poucos = canal('Poucos', titulo: 'pw187');
      final muitos = CanalAoVivo(
        canal: 'muitos',
        nome: 'Muitos',
        aoVivo: true,
        titulo: 'pw187',
        jogo: 'Perfect World',
        espectadores: 500,
        vistoEm: DateTime.utc(2026, 11, 9, 14),
      );
      expect(
        naTela([poucos, muitos], agora, versao: '1.8.7').map((c) => c.nome),
        ['Muitos', 'Poucos'],
      );
    });
  });
}
