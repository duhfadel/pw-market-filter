import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../domain/search_query.dart';
import '../search_state.dart';
import '../search_view_model.dart';
import 'section_header.dart';

/// Os quatro ofícios de artesanato do 1.2.6, como um mínimo sobre o melhor.
///
/// **Só desenha onde alguém os tem.** No 1.8.7 a página não publica perícias
/// nenhumas, portanto o escopo vem vazio e a secção desaparece sozinha — a
/// mesma regra do filtro de classe nos vídeos, e a razão por que nenhuma
/// tela precisa de saber em que mercado está.
///
/// **Sem rótulo por ofício, porque não há nomes.** A página publica as quatro
/// perícias por id; o dono diz que são *forja de arma, armadura, acessórios e
/// boticário*, mas nada confirma qual é qual. Por isso o controlo pergunta
/// *algum ofício em pelo menos N* em vez de prometer um ofício concreto —
/// rotular por palpite mandaria quem procura o ferreiro escolher o boticário
/// e ele nunca saberia.
class ForjaSection extends StatelessWidget {
  const ForjaSection({required this.state, required this.viewModel, super.key});

  final SearchReady state;
  final SearchViewModel viewModel;

  /// O maior nível que alguém no escopo tem em algum ofício, ou nulo quando
  /// ninguém tem nenhum.
  ///
  /// Lido do escopo que exclui este próprio controlo, como todos os outros:
  /// senão escolher 8 faria o topo passar a 8 e o controlo perderia a volta
  /// para trás.
  int? get _teto {
    var maior = 0;
    for (final c in state.facetsFor(FacetDimension.forja).scope) {
      for (final n in c.forja) {
        if (n > maior) maior = n;
      }
    }
    return maior == 0 ? null : maior;
  }

  @override
  Widget build(BuildContext context) {
    final teto = _teto;
    if (teto == null) return const SizedBox.shrink();

    final escolhido = state.query.forjaMinima;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: SectionHeader(
            title: 'Forja',
            glyph: Icons.hardware_outlined,
            expanded: true,
          ),
        ),
        const Text(
          'Pelo menos um dos quatro ofícios neste nível.',
          style: TextStyle(color: PWColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var n = 1; n <= teto; n++)
              ChoiceChip(
                label: Text('$n+'),
                selected: escolhido == n,
                onSelected: (ligado) =>
                    viewModel.setForjaMinima(ligado ? n : null),
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: escolhido == n ? PWColors.background : PWColors.text,
                ),
                selectedColor: PWColors.accent,
                backgroundColor: PWColors.surfaceRaised,
                showCheckmark: false,
              ),
          ],
        ),
      ],
    );
  }
}
