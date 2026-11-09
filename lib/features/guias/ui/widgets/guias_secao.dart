import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../home/ui/widgets/tool_navigation.dart';
import '../../domain/guia.dart';

/// Os guias desta versão, na tela da versão.
///
/// **Lê de `guiasDe(versao)` e não de uma lista própria.** Já houve duas
/// listas de guias que não sabiam uma da outra, e o guia das runas ficou dias
/// publicado sem caminho a partir do site — é a mesma fonte que gera
/// `web/guias/index.html`.
///
/// **Não mostra minutos, ao contrário da página `/guias/`.** O tempo de
/// leitura é medido do próprio ficheiro, e medir ficheiros é `dart:io`, que
/// `lib/` não importa. A alternativa era guardar os minutos à mão na
/// declaração — o mesmo facto em dois sítios, que divergem no dia em que
/// alguém acrescenta um parágrafo. Aqui a pergunta também é outra: nesta tela
/// os guias são uma secção, e é na lista inteira que alguém escolhe o que ler.
///
/// **A etiqueta da versão desenha-se só quando diz algo.** Numa tela de 1.8.7,
/// escrever `1.8.7` em sete de oito cartas é ruído; o que vale dizer é qual
/// serve *todas* as versões, porque essa é a que não é de cá.
class GuiasSecao extends StatelessWidget {
  const GuiasSecao({required this.versao, required this.wide, super.key});

  /// `1.8.7`, `1.2.6`, `1.4.4`. Nunca nulo aqui: a tela de escolha não tem
  /// secção de guias, e `null` significaria «todos», que é a página `/guias/`.
  final String versao;

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final deCa = guiasDe(versao);
    if (deCa.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Cabeca(),
        SizedBox(height: wide ? 12 : 10),
        for (final guia in deCa) ...[
          _Carta(guia: guia, versao: versao, wide: wide),
          SizedBox(height: wide ? 8 : 6),
        ],
        // **A porta para a lista inteira fica, mesmo com tudo à vista.** É ela
        // que separa «os guias desta versão» de «os guias do site», e é o que
        // deixa alguém de 1.2.6 descobrir que há sete artigos de 1.8.7 em vez
        // de concluir que o site tem um guia só.
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => abrirEndereco(context, '/guias/', externo: true),
            child: const Text('Todos os guias'),
          ),
        ),
      ],
    );
  }
}

class _Cabeca extends StatelessWidget {
  const _Cabeca();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Text(
        'GUIAS',
        style: TextStyle(
          color: PWColors.textMuted,
          fontSize: 11,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(width: 12),
      const Expanded(child: Divider(color: PWColors.border, height: 1)),
    ],
  );
}

class _Carta extends StatelessWidget {
  const _Carta({required this.guia, required this.versao, required this.wide});

  final Guia guia;
  final String versao;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    // Só o que serve todas as versões ganha etiqueta: ver a nota da classe.
    final etiqueta = guia.versoes.isEmpty ? 'todas as versões' : null;

    return Material(
      color: PWColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () =>
            abrirEndereco(context, guia.endereco, externo: !guia.noApp),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: wide ? 16 : 12,
            vertical: wide ? 13 : 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: PWColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      guia.titulo,
                      style: TextStyle(
                        color: PWColors.text,
                        fontSize: wide ? 15 : 14,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                  if (etiqueta != null) ...[
                    const SizedBox(width: 10),
                    _Etiqueta(texto: etiqueta),
                  ],
                ],
              ),
              SizedBox(height: wide ? 4 : 3),
              Text(
                guia.linha,
                style: TextStyle(
                  color: PWColors.textMuted,
                  fontSize: wide ? 12.5 : 11.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: PWColors.surfaceRaised,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      texto,
      style: const TextStyle(
        color: PWColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    ),
  );
}
