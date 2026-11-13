import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/theme/pw_theme.dart';

/// A abertura da raiz: o que o site faz, antes de dizer o nome dele.
///
/// **A raiz era um torniquete e deixou de ser, a 09/11/2026.** Eram três
/// cartas e **148 palavras** — e foi precisamente esta a página que o AdSense
/// viu como vazia a 31/10. A doc de `PortasView` dizia que a tela *«responde
/// duas perguntas e nada mais, de propósito»*, com o argumento de que não há
/// nada para vender a quem já está no site. O argumento vale para quem chegou
/// por um link de `/filtro` e já sabe o que isto é; não vale para quem
/// escreveu `portalpw.net` às cegas, que é exactamente quem esta tela recebe.
///
/// **A apresentação existe porque faltava a premissa**, e foi o dono a
/// apontá-la: «talvez falte a informaçao antes do market para que o pessoal
/// entenda o que sao aqueles numeros». Sem ela, *2.486 personagens à venda* é
/// um número sem substantivo.
class Abertura extends StatelessWidget {
  const Abertura({required this.wide, super.key});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    // `.intro h2 { font-size: clamp(24px, 3vw, 32px) }`.
    final largura = MediaQuery.sizeOf(context).width;
    final titulo = (largura * 0.03).clamp(24.0, 32.0);

    return Center(
      // `.intro { max-width: 620px; text-align: center }`.
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Três versões, três mercados',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: PWTheme.display,
                fontSize: wide ? titulo : 23,
                color: PWColors.papel,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            // **Um parágrafo e não quatro, e é a maquete a mandar.** A minha
            // versão tinha quatro — o que o mercado é, o que o site do jogo
            // não deixa procurar, as quatro armas chamadas Dilacerador e as
            // dezassete armas de topo. Era bom texto e está no sítio certo:
            // `web/index.html`, no bloco `#sem-script`, que é o que um
            // rastreador e um visitante sem JavaScript recebem — e é esse o
            // que conta para a revisão do AdSense, porque a app desenha em
            // canvas e não deixa texto no DOM.
            //
            // Aqui, doze linhas antes dos números empurravam a faixa viva
            // para fora da dobra. A premissa que falta a quem chega cabe
            // nesta frase.
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'No The Classic dá para '),
                  TextSpan(
                    text: 'vender o personagem inteiro',
                    // `.intro b { color: var(--texto); font-weight: 500 }`.
                    style: const TextStyle(
                      color: PWColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(
                    text:
                        ' — com o equipamento, as cartas e tudo o que ele '
                        'carrega. Cada versão tem o seu mercado, e é neles '
                        'que este site procura.',
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PWColors.apagado,
                fontSize: wide ? 15 : 13.5,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
