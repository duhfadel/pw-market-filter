import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/pw_colors.dart';

/// O pedido de ajuda, sob o mesmo título `COMUNIDADE` do convite do Discord.
///
/// **Gémeo do [DiscordStrip] de propósito**: mesma altura, mesmo alinhamento,
/// mesmo tamanho de letra, e o nome em `accent` como o *Siga nosso Discord*.
/// As duas são formas de apoiar o site e lidas juntas dizem isso melhor do que
/// separadas — e a simetria é o que impede esta de parecer um anúncio enfiado
/// no meio da página.
///
/// **Esteve no rodapé primeiro e saiu de lá.** Foi onde o dono pediu, mas ao
/// abrir a página achou pouco visível, que é a lição do card dos streamers
/// escrita outra vez: *discreto* não é sussurrar, e o rodapé é a parte da
/// página que menos gente alcança.
///
/// **Copia o nick ao toque, e é isso que a torna útil em vez de só um
/// pedido.** O atrito nunca foi saber como o dono se chama; é escrever
/// `duhit` na correspondência do jogo, numa janela que está noutra aplicação.
/// Com o nick na área de transferência, quem decidiu ajudar não tem de o
/// decorar.
///
/// Só é montada no 1.8.7 — ver a chamada em `home_view.dart` —, porque é lá
/// que o personagem que recebe existe. No 1.2.6 isto mandaria as pessoas a um
/// sítio onde não há ninguém.
class AjudaStrip extends StatelessWidget {
  const AjudaStrip({required this.wide, super.key});

  final bool wide;

  /// O personagem que recebe. Uma constante e não texto solto no meio da
  /// árvore: ele aparece três vezes aqui — no rótulo, no que se copia e no
  /// aviso que confirma — e três cópias à mão é como duas delas divergem.
  static const nick = 'duhit';

  @override
  Widget build(BuildContext context) => Align(
    // O mesmo que o convite do Discord faz, e pela mesma razão: à direita no
    // computador, onde o olho acaba a linha e o canto está livre; ao centro no
    // telemóvel, onde um canto é só a borda de uma coluna estreita.
    alignment: wide ? Alignment.centerRight : Alignment.center,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Clipboard.setData(const ClipboardData(text: nick));
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                backgroundColor: PWColors.surfaceRaised,
                behavior: SnackBarBehavior.floating,
                width: 320,
                duration: Duration(seconds: 3),
                content: Text(
                  'Nick $nick copiado. É só mandar no jogo — obrigado!',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.volunteer_activism_outlined,
                size: 15,
                color: PWColors.accent,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: wide ? 'Quer ajudar o site?' : 'Ajude com gold',
                        style: const TextStyle(
                          color: PWColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // **A frase inteira só onde ela cabe numa linha.** No
                      // filtro esta faixa fica fixa acima dos resultados: duas
                      // linhas num telemóvel custam ~55 px de grelha a cada
                      // segundo, para sempre, na tela onde os resultados são o
                      // produto. O estreito diz o essencial numa linha.
                      if (wide)
                        const TextSpan(text: '  mande gold para o personagem ')
                      else
                        const TextSpan(text: '  '),
                      TextSpan(
                        text: nick,
                        style: const TextStyle(
                          color: PWColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      // **O servidor nunca cai, e isso é correcção e não
                      // decoração.** Quem copiar o nick e mandar no 1.2.6 não
                      // chega a lado nenhum: o personagem só existe no 1.8.7.
                      TextSpan(text: wide ? ' (server 1.8.7)' : ' (1.8.7)'),
                    ],
                  ),
                  // **Nada de essencial cai, e é por isso que o estreito tem
                  // texto próprio em vez de ellipsis.** Sem o gold não se sabe
                  // o que mandar, sem o nick não se sabe a quem, sem o
                  // servidor vai para o sítio errado. `Flexible` garante que
                  // nunca transborda, que foi o que a primeira versão fez
                  // por 66 px.
                  textAlign: wide ? TextAlign.start : TextAlign.center,
                  style: const TextStyle(
                    color: PWColors.textMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              const Icon(
                Icons.copy_rounded,
                size: 13,
                color: PWColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
