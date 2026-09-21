import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';

/// The 21/09 entry: the titles tool and the live streamers.
///
/// It names the NPC and gives her coordinates, which is the part that turns
/// "this exists" into "go here". The site can explain a mechanic all it likes;
/// somebody standing in the game needs a place to walk to.
class NewsTitulos extends StatelessWidget {
  const NewsTitulos({required this.wide, super.key});

  final bool wide;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _p('Duas coisas novas por aqui.'),
      _titulo('Títulos'),
      Text.rich(
        TextSpan(
          children: [
            const TextSpan(
              text: 'A ',
              style: TextStyle(color: PWColors.text),
            ),
            const TextSpan(
              text: 'Gerente de Eventos',
              style: TextStyle(
                color: PWColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const TextSpan(
              text: ', na Cidade do Dragão ',
              style: TextStyle(color: PWColors.text),
            ),
            // The coordinates in the accent, because they are the one thing on
            // this line somebody copies into the game.
            const TextSpan(
              text: '(551, 636)',
              style: TextStyle(
                color: PWColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const TextSpan(
              text:
                  ', troca Páginas de Registro: Assimilação por atributo '
                  'permanente — e agora ela tem uma tela no site. São as 126 '
                  'receitas das seis abas, na mesma ordem e nas mesmas '
                  'posições do jogo: dá para ver o que cada uma dá, filtrar '
                  'por atributo e marcar várias para somar quanto custa em '
                  'páginas e quanto rende no total.',
              style: TextStyle(color: PWColors.text),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 14, height: 1.65),
      ),
      const SizedBox(height: 4),
      _titulo('Streamers amigos'),
      _p(
        'Quem da comunidade estiver ao vivo na Twitch aparece lá embaixo na '
        'página, e some sozinho quando a live acaba.',
      ),
      _p(
        'O pessoal que ajuda o site, se quiser, vai ter o nome aqui sempre '
        'que estiver online na Twitch. Se tiver uma arte, melhor ainda ;)',
      ),
      const Text(
        '— duhit',
        style: TextStyle(color: PWColors.textMuted, fontSize: 13),
      ),
    ],
  );

  Widget _titulo(String texto) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 8),
    child: Text(
      texto,
      style: const TextStyle(
        color: PWColors.accent,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _p(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      texto,
      style: const TextStyle(color: PWColors.text, fontSize: 14, height: 1.65),
    ),
  );
}
