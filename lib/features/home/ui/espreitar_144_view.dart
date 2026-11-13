import 'package:flutter/material.dart';

import '../../../core/rotas.dart' as rotas;
import '../../../core/theme/pw_colors.dart';
import '../../../core/theme/medidas_da_maquete.dart';
import '../domain/arte_da_classe.dart';
import 'widgets/cabecalho.dart';
import 'widgets/cartaz.dart';
import 'widgets/palco_de_classe.dart';

/// O Cartaz do 1.4.4, sozinho — uma espreitadela, não uma tela.
///
/// **Temporária e com data para sair.** Pedido do dono a 10/11/2026, para ver
/// o Mercenário na caixa do Cartaz antes de o 1.4.4 abrir. Não se chega aqui
/// a clicar: a porta da raiz continua a não levar a lado nenhum, e é preciso
/// escrever `/1.4.4` no endereço.
///
/// **Desenha o Cartaz e mais nada, de propósito.** Aquele mercado não tem
/// índice — não há `market_index_144.json` —, portanto uma home inteira teria
/// de pedir números a algum lado, e o único lado que existe é o 1.8.7. Pôr
/// *2.486 personagens à venda* debaixo de um cabeçalho que diz 1.4.4 seria o
/// site a afirmar um mercado que não existe, que é precisamente o que a porta
/// da raiz se recusa a fazer ao ficar apagada.
///
/// **Quando o 1.4.4 abrir, isto sai.** O que nasce no lugar é a `HomeView`
/// com o índice daquela versão, como as outras duas — e o dia de apagar este
/// ficheiro é o mesmo em que `Porta.rota` deixa de ser nula.
class Espreitar144View extends StatelessWidget {
  const Espreitar144View({super.key});

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final wide = largura >= Cabecalho.larguraMinima;
    // Os mesmos degraus da home de um mercado, para esta tela não ter uma
    // conta própria a divergir da outra — que foi o defeito que o dono
    // apanhou: uma margem fixa de 24 deixava o texto colado à esquerda
    // enquanto as outras telas o põem na coluna de leitura.
    final large = largura >= 1280;
    final maxWidth = large ? Maquete.colunaDeLeitura : 780.0;

    return Scaffold(
      backgroundColor: PWColors.background,
      body: ListView(
        children: [
          Cartaz(
            classe: classeDoCartaz(rotas.pw144),
            wide: wide,
            margemHorizontal: recuoDoHeroi(largura, maxWidth, wide),
            subtitulo:
                'O mercado ainda não abriu. Esta tela existe para ver a arte '
                'da capa, e sai no dia em que o 1.4.4 entrar.',
            aoBuscar: () {},
            aoVerGuias: () {},
          ),
        ],
      ),
    );
  }
}
