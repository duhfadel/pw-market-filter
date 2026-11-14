import 'package:flutter/material.dart';

import '../../../core/rotas.dart' as rotas;
import '../../../core/theme/pw_colors.dart';
import '../../../core/widgets/game_icon.dart';
import '../../ads/ad_slot.dart';
import '../../home/domain/tool.dart';
import '../../home/ui/widgets/cabecalho.dart';
import '../../home/ui/widgets/tool_navigation.dart';

/// O catálogo das ferramentas do site.
///
/// **É uma tela e não uma página HTML, ao contrário dos Guias.** A diferença
/// é a mesma de sempre: um guia *é* conteúdo editorial, uma página que se lê,
/// e por isso vive em HTML (indexável, com anúncio). Uma ferramenta é uma
/// *tela do app* — o destino de cada card é uma rota interna. Uma tela Flutter
/// mantém uma só fonte de verdade, a lista `tools` que a barra já lê, e os
/// links ficam dentro do app.
///
/// **A pílula Ferramentas abre aqui**, como a dos Guias abre `/guias/` —
/// acabou a gaveta de linhas apertadas. A versão viaja no `?v=`, para a tela
/// mostrar as ferramentas de quem está a ler.
///
/// **O Filtro não está na lista, de propósito** (ver `tools`): é a porta da
/// frente do site e já está implícito em todo o lado.
class FerramentasView extends StatelessWidget {
  const FerramentasView({super.key, this.query = const {}});

  final Map<String, List<String>> query;

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final largo = largura >= 620;

    // A versão vem do endereço (`?v=`), posta pela pílula. Sem ela — alguém
    // que escreve `/ferramentas` à mão — mostra-se tudo, como o seletor faz.
    final versao = query['v']?.firstOrNull;
    final itens = toolsDe(
      'Ferramentas',
      versao: versao,
    ).where((t) => t.isReady).toList();

    return Scaffold(
      appBar: AppBar(
        // A mesma arrumação de todas as telas de ferramenta: a marca do
        // `Cabecalho` é a única porta para casa, sem uma seta automática ao
        // lado dela.
        automaticallyImplyLeading: false,
        title: Cabecalho(
          wide: largura >= Cabecalho.larguraMinima,
          // Sem versão no endereço, a barra fica no 1.8.7, que é onde as
          // ferramentas vivem.
          versao: versao ?? rotas.pw187,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  largo ? 24 : 16,
                  largo ? 24 : 18,
                  largo ? 24 : 16,
                  8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ferramentas',
                      style: TextStyle(
                        fontFamily: 'Marcellus',
                        color: PWColors.papel,
                        fontSize: largo ? 30 : 26,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'O que o site faz além de ler o mercado.',
                      style: TextStyle(color: PWColors.textMuted, fontSize: 14),
                    ),
                    SizedBox(height: largo ? 22 : 18),
                    for (final tool in itens)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CardFerramenta(tool: tool, versao: versao),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const AdSlot(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Uma ferramenta como linha rica: a arte solta à esquerda, o nome e a linha,
/// o selo, e um toque que abre a rota.
class _CardFerramenta extends StatelessWidget {
  const _CardFerramenta({required this.tool, required this.versao});

  final Tool tool;
  final String? versao;

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    return Material(
      color: PWColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => abrirTool(context, tool, versao: versao),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PWColors.border),
          ),
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          child: Row(
            children: [
              // A arte solta, sem caixa — pedido do dono a 14/11/2026. Vem da
              // pasta própria `assets/icons/ferramentas/`, limpa e sem
              // moldura; `ArteDaFerramenta` cai para o ícone do item quando
              // não há versão limpa.
              SizedBox(
                width: 56,
                height: 56,
                child: tool.emblem == null
                    ? Icon(tool.icon, color: PWColors.accent, size: 30)
                    : ArteDaFerramenta(tool.emblem!),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tool.name,
                            style: const TextStyle(
                              color: PWColors.papel,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (tool.betaEm(agora)) ...[
                          const SizedBox(width: 8),
                          const _Selo('BETA', preenchido: false),
                        ] else if (tool.novoEm(agora)) ...[
                          const SizedBox(width: 8),
                          const _Selo('novo', preenchido: true),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tool.tagline,
                      style: const TextStyle(
                        color: PWColors.textMuted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right,
                color: PWColors.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O selo *BETA* (contornado) ou *novo* (preenchido) — o mesmo par da gaveta:
/// um é ressalva, o outro é convite, e por isso nunca se parecem.
class _Selo extends StatelessWidget {
  const _Selo(this.texto, {required this.preenchido});

  final String texto;
  final bool preenchido;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: preenchido ? PWColors.accent : null,
      border: preenchido ? null : Border.all(color: PWColors.accent),
      borderRadius: BorderRadius.circular(preenchido ? 9 : 6),
    ),
    child: Text(
      texto,
      style: TextStyle(
        color: preenchido ? PWColors.background : PWColors.accent,
        fontSize: 9,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
