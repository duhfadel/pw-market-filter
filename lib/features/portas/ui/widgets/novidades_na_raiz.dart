import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/ui/cabeca_de_seccao.dart';
import '../../../home/domain/novidade.dart';
import '../../../home/ui/novidades_view_model.dart';
import '../../../home/ui/widgets/novidade_texto.dart';

/// O último recado do Portal, aberto, na raiz.
///
/// **A barra fechada foi removida da home das versões a 01/10/2026** — a
/// pílula *Novidades* do cabeçalho passou a ser a mesma porta, e duas
/// superfícies para a mesma coisa na mesma página é a duplicação que o dono
/// recusou. Aqui não é o mesmo caso: a pílula é navegação e **só abre ao
/// toque**; esta secção mostra o texto, que é a única coisa da página que
/// muda sozinha e a única razão de alguém voltar amanhã.
///
/// **Um só, e aberto.** Três entradas abertas corriam a mil píxeis na home
/// antiga, e foi por isso que a barra nasceu fechada; um recado aberto são
/// noventa a duzentos, e fechado não diria nada que a pílula já não diga.
///
/// **Falha calada e sem rede não desenha**, como o canal e os streamers: a
/// tabela pode estar vazia, o Discord pode ter apagado, e nenhuma dessas é
/// uma avaria que valha um recado de erro numa página de entrada.
class NovidadesNaRaiz extends StatelessWidget {
  const NovidadesNaRaiz({required this.wide, this.espacoAcima = 0, super.key});

  final bool wide;

  /// Desenhado por dentro, para se ir embora com a secção quando não há
  /// recado nenhum — ver `AoVivoStrip.espacoAcima`.
  final double espacoAcima;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<NovidadesViewModel, List<Novidade>>(
        builder: (context, novidades) {
          if (novidades.isEmpty) return const SizedBox.shrink();
          final ultima = novidades.first;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (espacoAcima > 0) SizedBox(height: espacoAcima),
              CabecaDeSeccao(
                titulo: 'Novidades do portal',
                porta: 'todos os recados →',
                aoTocarNaPorta: () =>
                    Navigator.of(context).pushNamed('/novidades'),
              ),
              SizedBox(height: wide ? 14 : 11),
              _Painel(novidade: ultima, wide: wide),
            ],
          );
        },
      );
}

class _Painel extends StatelessWidget {
  const _Painel({required this.novidade, required this.wide});

  final Novidade novidade;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final titulo = novidade.titulo;

    return Container(
      padding: EdgeInsets.all(wide ? 22 : 16),
      decoration: BoxDecoration(
        color: PWColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PWColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titulo != null) ...[
            Text(
              titulo,
              style: TextStyle(
                color: PWColors.papel,
                fontSize: wide ? 16 : 15,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 3),
          ],
          Text(
            _data(novidade.publicadaEm.toLocal()),
            style: const TextStyle(color: PWColors.textMuted, fontSize: 11.5),
          ),
          SizedBox(height: wide ? 14 : 11),
          NovidadeTexto(corpo: novidade.corpo),
        ],
      ),
    );
  }

  static const _meses = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  /// `23 de outubro`. Por extenso e sem o ano: um recado que precise do ano
  /// para se situar já não é novidade, e estaria em `/novidades`.
  static String _data(DateTime d) => '${d.day} de ${_meses[d.month - 1]}';
}
