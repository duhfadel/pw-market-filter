import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/ui/cabeca_de_seccao.dart';
import '../../../home/ui/widgets/tool_navigation.dart';
import '../../../portas/domain/versao.dart';
import '../../data/video_repository.dart';
import '../../domain/guerra_recente.dart';
import '../../domain/video.dart';

/// A guerra mais recente de **cada** mercado, na raiz.
///
/// **Não é a secção da home de versão outra vez, e a diferença é a cota.** Lá
/// mostram-se as quatro guerras mais recentes *daquele* mercado; aqui mostra-se
/// a mais recente *de cada um dos três*. Com 47 vídeos no 1.8.7 contra zero no
/// 1.2.6 e zero no 1.4.4 — medido a 10/11/2026 —, uma lista dos mais recentes
/// sem cota por mercado seria sempre 1.8.7 e nunca mostraria os três, que é
/// precisamente o que esta secção existe para fazer.
///
/// É a mesma forma que os Destaques já têm: uma carta por categoria, e a
/// categoria escassa escolhe primeiro. Aqui a cota é fixa — um por mercado —
/// porque os mercados são três e não mudam.
///
/// **Só na raiz**, pela regra que esta casa já segue para os guias e para o
/// cartão do streamer: a etiqueta diz o que difere do escopo da página. Numa
/// tela de 1.8.7 escrever `1.8.7` é ruído; na raiz, que não é de versão
/// nenhuma, a versão é a informação que falta.
///
/// **A ordem é a das portas e vem de [portasDe]**, que é a lista escrita à mão
/// dos mercados que existem — 1.2.6, 1.4.4, 1.8.7, cronológica, escolha do
/// dono em 12/10/2026. Lida de lá e não repetida aqui: um quarto mercado
/// aparece nesta secção no mesmo dia em que ganha porta.
///
/// **Carrega sozinha e falha calada**, como [CanalDoPortal] e a faixa dos
/// streamers. E falhar não é o mesmo que estar vazia: um pedido que não
/// chegou não desenha nada, enquanto um mercado sem vídeos desenha o convite.
/// Dizer *«ainda sem vídeos»* por causa de um erro de rede seria afirmar sobre
/// o acervo o que só se sabe sobre a ligação.
class UltimosVideosDeGuerra extends StatefulWidget {
  const UltimosVideosDeGuerra({
    required this.wide,
    this.espacoAcima = 0,
    this.carregar,
    super.key,
  });

  final bool wide;

  /// **Desenhado por dentro da secção**, pela razão que `AoVivoStrip` já
  /// carrega: ela desaparece inteira quando não há vídeo nenhum em mercado
  /// nenhum, e o vão tem de se ir com ela.
  final double espacoAcima;

  /// Injectável só para o teste; a secção monta o repositório ela própria.
  final Future<List<Video>> Function()? carregar;

  /// Quantas guerras cada mercado lista.
  ///
  /// **Três e não uma, pedido do dono a 10/11/2026**, e a cota por mercado é
  /// o que torna isso possível sem a secção virar a lista do 1.8.7: três de
  /// *cada*, não as três mais recentes do site. Com 47 vídeos num mercado e
  /// zero nos outros dois, uma lista sem cota seria sempre a mesma coluna.
  static const porCada = 3;

  @override
  State<UltimosVideosDeGuerra> createState() => _UltimosVideosDeGuerraState();
}

enum _Estado { aCarregar, falhou, pronto }

class _UltimosVideosDeGuerraState extends State<UltimosVideosDeGuerra> {
  _Estado _estado = _Estado.aCarregar;

  /// As guerras mais recentes de cada mercado, pelo nome da versão.
  Map<String, List<GuerraRecente>> _porMercado = const {};

  /// Quantos vídeos cada mercado tem, para a porta de cada coluna.
  Map<String, int> _quantos = const {};

  @override
  void initState() {
    super.initState();
    unawaited(_carregar());
  }

  Future<void> _carregar() async {
    // **Sem `versao:`, de propósito** — aqui queremos os três mercados, e é o
    // agrupamento abaixo que os separa.
    final buscar =
        widget.carregar ?? () => VideoRepository().daSecao('guerras');
    try {
      final videos = await buscar();
      if (!mounted) return;

      final porMercado = <String, List<GuerraRecente>>{};
      final quantos = <String, int>{};
      for (final porta in portasDe(const {})) {
        final dali = [
          for (final v in videos)
            if (v.versao == porta.nome) v,
        ];
        quantos[porta.nome] = dali.length;
        final guerras = guerrasRecentes(dali);
        if (guerras.isNotEmpty) {
          porMercado[porta.nome] = guerras
              .take(UltimosVideosDeGuerra.porCada)
              .toList();
        }
      }

      setState(() {
        _estado = _Estado.pronto;
        _porMercado = porMercado;
        _quantos = quantos;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _estado = _Estado.falhou);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_estado != _Estado.pronto) return const SizedBox.shrink();
    // Nenhum mercado com vídeo nenhum: a secção seria três convites seguidos,
    // que é um formulário e não uma secção.
    if (_porMercado.isEmpty) return const SizedBox.shrink();

    final mercados = portasDe(const {});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.espacoAcima > 0) SizedBox(height: widget.espacoAcima),
        // **Sem porta na régua, e a razão é a cota.** Uma porta só teria de
        // escolher um mercado para onde ir, e esta secção existe justamente
        // para não escolher. Cada coluna leva a sua.
        const CabecaDeSeccao(titulo: 'Últimos vídeos de guerra'),
        SizedBox(height: widget.wide ? 18 : 14),
        if (widget.wide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, porta) in mercados.indexed) ...[
                  // **Filete entre colunas, nunca moldura à volta de cada.** É
                  // a regra que as três portas desta mesma página já seguem:
                  // três cartas com borda lêem-se como três coisas a competir,
                  // três colunas de uma faixa lêem-se como uma comparação.
                  if (i > 0)
                    const VerticalDivider(width: 49, color: PWColors.filete),
                  Expanded(
                    child: _Mercado(
                      versao: porta.nome,
                      guerras: _porMercado[porta.nome] ?? const [],
                      quantos: _quantos[porta.nome] ?? 0,
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          // No estreito a comparação lado a lado não cabe — três colunas a
          // 110 px cortariam o nome de qualquer guilda — e empilhadas as
          // etiquetas continuam a dizer de que mercado é cada uma.
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, porta) in mercados.indexed) ...[
                if (i > 0) const SizedBox(height: 18),
                _Mercado(
                  versao: porta.nome,
                  guerras: _porMercado[porta.nome] ?? const [],
                  quantos: _quantos[porta.nome] ?? 0,
                ),
              ],
            ],
          ),
      ],
    );
  }
}

/// Uma coluna: a etiqueta do mercado e a guerra mais recente dele.
class _Mercado extends StatelessWidget {
  const _Mercado({
    required this.versao,
    required this.guerras,
    required this.quantos,
  });

  final String versao;
  final List<GuerraRecente> guerras;
  final int quantos;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      _Etiqueta(versao),
      const SizedBox(height: 12),
      if (guerras.isEmpty)
        ..._semVideos
      else ...[
        for (final (i, guerra) in guerras.indexed) ...[
          if (i > 0) const SizedBox(height: 14),
          _Guerra(guerra),
        ],
        if (quantos > guerras.length) ...[
          const SizedBox(height: 12),
          // A porta é de cada coluna e não da secção, porque cada mercado tem
          // a sua página de guerras.
          InkWell(
            onTap: () =>
                abrirEndereco(context, '/$versao/guerras', externo: false),
            child: Text(
              'ver todos os $quantos →',
              style: const TextStyle(
                color: PWColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    ],
  );

  /// **O convite em vez de um vazio**, que é a decisão do dono de 10/11/2026
  /// sobre a secção da home de versão, aplicada aqui pela mesma razão: um
  /// mercado sem vídeo nenhum é onde o convite tem mais trabalho a fazer.
  ///
  /// Em texto e não na caixa do [ConviteDeVideo]: aqui são duas colunas vazias
  /// de três, e três caixas de convite seguidas leriam como um formulário.
  List<Widget> get _semVideos => const [
    Text(
      'Ainda sem vídeos daqui.',
      style: TextStyle(
        color: PWColors.papel,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
    SizedBox(height: 4),
    Text(
      'Gravou uma guerra? Mande para a gente.',
      style: TextStyle(color: PWColors.textMuted, fontSize: 13, height: 1.45),
    ),
  ];
}

/// Uma guerra da lista: o que foi, quem filmou, quando.
class _Guerra extends StatelessWidget {
  const _Guerra(this.guerra);

  final GuerraRecente guerra;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => unawaited(
      launchUrl(
        Uri.parse(guerra.primeira.endereco),
        mode: LaunchMode.externalApplication,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (guerra.manchete case final manchete?)
          Text(
            manchete,
            style: const TextStyle(
              color: PWColors.papel,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        if (guerra.quem case final quem?) ...[
          const SizedBox(height: 3),
          Text(
            quem,
            style: const TextStyle(color: PWColors.textMuted, fontSize: 12.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (guerra.dataEscrita case final data?) ...[
          const SizedBox(height: 2),
          Text(
            data,
            style: const TextStyle(color: PWColors.textMuted, fontSize: 12.5),
          ),
        ],
      ],
    ),
  );
}

/// A etiqueta do mercado, a ouro.
///
/// **Ouro, por decisão do dono a 10/11/2026, e aqui ele não gasta a cor do
/// dinheiro.** A regra desta casa é que o ouro significa preço e chamada à
/// acção — e existe para ele querer dizer dinheiro *onde há dinheiro*. Esta
/// secção não imprime preço nenhum, portanto não há com que colidir.
///
/// A pílula tem chão e borda; a porta de cada coluna é texto nu com uma seta.
/// São formas diferentes, o que impede a etiqueta de se ler como um link.
class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.versao);

  final String versao;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: PWColors.accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: PWColors.accent.withValues(alpha: 0.38)),
    ),
    child: Text(
      versao,
      style: const TextStyle(
        color: PWColors.accent,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        // Marcellus desenha algarismos romanos e isto é um número.
        letterSpacing: 0.4,
      ),
    ),
  );
}
