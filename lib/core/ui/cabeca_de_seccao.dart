import 'package:flutter/material.dart';

import '../theme/pw_colors.dart';
import '../theme/pw_theme.dart';

/// A régua que abre uma secção: o nome, um filete até ao fim, e uma porta
/// opcional à direita.
///
/// ```css
/// .cab    { display:flex; align-items:baseline; gap:16px; margin-bottom:22px }
/// .cab h2 { font-family: Marcellus; font-size:13px; letter-spacing:.2em;
///           text-transform:uppercase; color: apagado }
/// .cab .fio { flex:1; height:1px; background: filete }
/// .cab a  { font-size:13px; color: ouro }
/// ```
///
/// **Existe porque eu a escrevi quatro vezes no mesmo dia** — nos guias, no
/// canal, nas novidades e no selo do mercado — e quatro cópias de uma régua
/// divergem na primeira vez que alguém mexer numa. É a assinatura visual que
/// faz as telas parecerem o mesmo site, portanto é a última coisa que pode
/// andar à solta.
///
/// **Marcellus aqui é seguro**, ao contrário de quase todo o resto deste
/// projecto: um nome de secção não tem algarismos, e a face de display é o
/// que distingue uma régua de um rótulo qualquer.
class CabecaDeSeccao extends StatelessWidget {
  const CabecaDeSeccao({
    required this.titulo,
    this.porta,
    this.aoTocarNaPorta,
    super.key,
  });

  /// Escrito como quem chama o escreve. Vai para maiúsculas aqui, porque é
  /// decisão da régua e não de cada chamador — a primeira versão tinha
  /// `'TODOS OS GUIAS'` num sítio e `'Novidades do portal'` noutro.
  final String titulo;

  /// O que a porta da direita diz. Nula quando a secção não leva a lado
  /// nenhum.
  final String? porta;

  final VoidCallback? aoTocarNaPorta;

  @override
  Widget build(BuildContext context) => Row(
    // `align-items: baseline` — o filete alinha pela base do texto e não
    // pelo meio da caixa, que é o que o faz parecer uma régua debaixo da
    // palavra em vez de uma linha a cortá-la.
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        titulo.toUpperCase(),
        style: const TextStyle(
          fontFamily: PWTheme.display,
          color: PWColors.apagado,
          fontSize: 13,
          letterSpacing: 2.6,
        ),
      ),
      const SizedBox(width: 16),
      const Expanded(
        child: Padding(
          padding: EdgeInsets.only(bottom: 5),
          child: Divider(color: PWColors.border, height: 1),
        ),
      ),
      if (porta case final rotulo?) ...[
        const SizedBox(width: 16),
        InkWell(
          onTap: aoTocarNaPorta,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Text(
              rotulo,
              style: const TextStyle(color: PWColors.accent, fontSize: 13),
            ),
          ),
        ),
      ],
    ],
  );
}
