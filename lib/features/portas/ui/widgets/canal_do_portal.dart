import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../guias/data/video_repository.dart';
import '../../../guias/domain/video.dart';
import '../../../guias/ui/widgets/cartao_de_video.dart';

/// Os vídeos do canal do Portal PW, na raiz.
///
/// **É do site e não de uma versão**, e é por isso que vive aqui e não se
/// repete na tela de cada mercado. A spec diz isso com uma linha: *«O canal do
/// Portal não se repete aqui. É do site e não desta versão.»*
///
/// **Sem pílula no cabeçalho.** Uma entrada de navegação para uma secção da
/// mesma página, de um canal com dois vídeos, é promessa a mais — a pílula
/// entra no dia em que houver vídeos que bastem e uma página a listá-los.
/// *Novidades* tem a sua porque muda sozinha e tem o ponto a avisar.
///
/// **Carrega sozinha e falha calada.** Como a faixa dos streamers: é uma
/// secção a somar, não a razão de alguém ter vindo, e uma secção que grita ao
/// falhar é pior do que uma que se cala. Sem vídeos não desenha nada — e
/// **nem o espaço**, que é a mesma razão pela qual `AoVivoStrip.espacoAcima`
/// existe.
class CanalDoPortal extends StatefulWidget {
  const CanalDoPortal({
    required this.wide,
    this.espacoAcima = 0,
    this.carregar,
    super.key,
  });

  final bool wide;
  final double espacoAcima;

  /// Por onde os vídeos chegam. Injectável só para o teste; **a secção monta
  /// o repositório ela própria**, como `TelaDeVideos` já faz — foi um `getIt`
  /// em falta, engolido por um `unawaited`, que deixou esta mesma tela a
  /// girar para sempre em 02/10/2026.
  final Future<List<Video>> Function()? carregar;

  /// A secção da tabela `videos` que guarda os vídeos do próprio Portal.
  static const secao = 'canal';

  @override
  State<CanalDoPortal> createState() => _CanalDoPortalState();
}

class _CanalDoPortalState extends State<CanalDoPortal> {
  List<Video> _videos = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_carregar());
  }

  Future<void> _carregar() async {
    final buscar =
        widget.carregar ?? () => VideoRepository().daSecao(CanalDoPortal.secao);
    try {
      final videos = await buscar();
      if (!mounted) return;
      setState(() => _videos = videos);
    } catch (_) {
      // Fica vazia, e a secção desaparece. Ver a nota da classe.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_videos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.espacoAcima > 0) SizedBox(height: widget.espacoAcima),
        _Cabeca(wide: widget.wide),
        SizedBox(height: widget.wide ? 12 : 10),
        GrelhaDeVideos(videos: _videos),
      ],
    );
  }
}

class _Cabeca extends StatelessWidget {
  const _Cabeca({required this.wide});

  final bool wide;

  /// O canal, que é o único endereço que a secção publica — e vai no mesmo
  /// separador, como todo link externo deste site.
  static const _canal = 'https://www.youtube.com/@PortalPw';

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Text(
        'O CANAL DO PORTAL',
        style: TextStyle(
          color: PWColors.textMuted,
          fontSize: 11,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(width: 12),
      const Expanded(child: Divider(color: PWColors.border, height: 1)),
      const SizedBox(width: 12),
      TextButton(
        onPressed: () => unawaited(
          launchUrl(Uri.parse(_canal), mode: LaunchMode.externalApplication),
        ),
        child: Text(
          wide ? 'Ver no YouTube' : 'YouTube',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    ],
  );
}
