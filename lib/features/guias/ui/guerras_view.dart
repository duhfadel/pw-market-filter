import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/rotas.dart' as rotas;
import '../../../core/theme/pw_colors.dart';
import '../../../core/theme/pw_theme.dart';
import '../../../core/widgets/game_icon.dart';
import '../../home/domain/community.dart';
import '../../home/ui/widgets/cabecalho.dart';
import '../../home/ui/widgets/rodape.dart';
import '../../search/ui/search_state.dart';
import '../../search/ui/search_view_model.dart';
import '../data/video_repository.dart';
import '../domain/video.dart';

/// Os vídeos de guerra territorial que a comunidade autorizou.
///
/// **A política é o conteúdo aqui.** A página só tem vídeo porque alguém se
/// ofereceu — nada é garimpado — e por isso o convite fica sempre visível, no
/// fim da grelha, e não apenas quando não há nada. Escondê-lo depois de entrar
/// o primeiro vídeo seria fechar a porta por onde a página se enche.
class GuerrasView extends StatefulWidget {
  const GuerrasView({this.carregar, super.key});

  /// Por onde os vídeos chegam. Injetável só para o teste; a produção usa o
  /// repositório de verdade, e **a tela monta-o ela própria** em vez de
  /// esperar por um provider — foi um `getIt` em falta, engolido por um
  /// `unawaited`, que deixou o seletor a girar para sempre em 02/10.
  final Future<List<Video>> Function()? carregar;

  @override
  State<GuerrasView> createState() => _GuerrasViewState();
}

class _GuerrasViewState extends State<GuerrasView> {
  List<Video>? _videos;
  String? _classe;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    unawaited(_buscar());
  }

  Future<void> _buscar() async {
    final carregar =
        widget.carregar ?? () => VideoRepository().daSecao('guerras');
    final videos = await carregar();
    if (mounted) setState(() => _videos = videos);
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;

    return Scaffold(
      appBar: AppBar(
        // Declarado `false` de propósito: sem `leading` próprio, uma rota
        // empurrada ganha a seta automática do Flutter — que ficaria ao lado
        // da marca do `Cabecalho`, uma segunda porta para casa que ninguém
        // pediu.
        automaticallyImplyLeading: false,
        title: Cabecalho(
          wide: largura >= Cabecalho.larguraMinima,
          versao: rotas.pw187,
        ),
      ),
      body: _videos == null
          ? const Center(
              child: CircularProgressIndicator(color: PWColors.accent),
            )
          : _Conteudo(
              videos: _videos!,
              classe: _classe,
              aoEscolher: (c) => setState(() => _classe = c),
              busca: _busca,
              aoBuscar: (t) => setState(() => _busca = t),
            ),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({
    required this.videos,
    required this.classe,
    required this.aoEscolher,
    required this.busca,
    required this.aoBuscar,
  });

  final List<Video> videos;
  final String? classe;
  final ValueChanged<String?> aoEscolher;
  final String busca;
  final ValueChanged<String> aoBuscar;

  @override
  Widget build(BuildContext context) {
    final classes = classesCom(videos);
    final mostrados = [
      for (final v in videos)
        if ((classe == null || v.classe == classe) && v.contem(busca)) v,
    ];

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Cabecalho(),
                const SizedBox(height: 20),
                _CampoDeBusca(valor: busca, aoMudar: aoBuscar),
                if (classes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _FiltroDeClasse(
                    classes: classes,
                    escolhida: classe,
                    aoEscolher: aoEscolher,
                  ),
                ],
                const SizedBox(height: 20),
                if (mostrados.isEmpty)
                  _SemVideos(procurando: busca.isNotEmpty || classe != null)
                else
                  _Grelha(videos: mostrados),
                const SizedBox(height: 28),
                const _Convite(),
                const SizedBox(height: 28),
                const Rodape(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Procura em tudo o que o vídeo diz — título, personagem, detalhes e classe.
///
/// **Ideia do dono, e é ela que torna a guilda procurável sem lhe dar coluna
/// própria.** Eu tinha proposto separar `guilda_a` e `guilda_b` justamente
/// para abrir essa porta; ele viu que um campo de texto sobre o que já está
/// escrito faz o mesmo e não obriga ninguém a preencher mais campos.
///
/// Tudo local: a tela já tem os vídeos daquela seção em memória, portanto
/// procurar não custa um pedido. Mandar cada tecla ao PostgREST custaria um
/// pedido por letra para filtrar uma lista que já está aqui.
class _CampoDeBusca extends StatelessWidget {
  const _CampoDeBusca({required this.valor, required this.aoMudar});

  final String valor;
  final ValueChanged<String> aoMudar;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: TextField(
      onChanged: aoMudar,
      style: const TextStyle(color: PWColors.text, fontSize: 14),
      decoration: const InputDecoration(
        isDense: true,
        prefixIcon: Icon(Icons.search, size: 19, color: PWColors.textMuted),
        hintText: 'Buscar por guilda, personagem ou título',
        hintStyle: TextStyle(color: PWColors.textMuted, fontSize: 13),
      ),
    ),
  );
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Sem algarismos, portanto a face de display é segura aqui: Marcellus
      // desenha figuras romanas e o seu `1` não tem bandeira.
      Text(
        'Guerras Territoriais',
        style: TextStyle(
          fontFamily: PWTheme.display,
          fontSize: 32,
          color: PWColors.papel,
          height: 1.15,
        ),
      ),
      SizedBox(height: 10),
      Text(
        'Vídeos de guerra territorial do 1.8.7 — para rever como foi a '
        'guerra, analisar a gameplay ou comparar com a sua.',
        style: TextStyle(color: PWColors.textMuted, fontSize: 14, height: 1.55),
      ),
      SizedBox(height: 8),
      Text(
        'Todos os jogadores que têm seus vídeos aqui me deram permissão '
        'para tal.',
        style: TextStyle(color: PWColors.papel, fontSize: 14, height: 1.55),
      ),
    ],
  );
}

/// As classes que têm vídeo, mais *Todos*.
///
/// **Só as que têm**, que é a regra de todo controlo deste site: uma fila de
/// dezassete ícones dos quais quinze não dão resultado ensina o contrário do
/// que devia.
class _FiltroDeClasse extends StatelessWidget {
  const _FiltroDeClasse({
    required this.classes,
    required this.escolhida,
    required this.aoEscolher,
  });

  final List<String> classes;
  final String? escolhida;
  final ValueChanged<String?> aoEscolher;

  /// O número da arte de cada classe vem do **índice do mercado**, que já
  /// está montado acima de todas as rotas — a listagem traz nome e
  /// `occupation` juntos, portanto nada aqui precisa de uma tabela de nomes
  /// escrita à mão, que seria uma segunda cópia a divergir no dia em que o
  /// jogo acrescentasse uma classe.
  Map<String, int> _occupations(BuildContext context) {
    final estado = context.watch<SearchViewModel>().state;
    if (estado is! SearchReady) return const {};
    return {
      for (final c in estado.index.characters) c.characterClass: c.occupation,
    };
  }

  @override
  Widget build(BuildContext context) {
    final occupations = _occupations(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            rotulo: 'Todos',
            activo: escolhida == null,
            aoTocar: () => aoEscolher(null),
          ),
          for (final classe in classes) ...[
            const SizedBox(width: 8),
            _Chip(
              rotulo: classe,
              activo: escolhida == classe,
              aoTocar: () => aoEscolher(classe),
              occupation: occupations[classe],
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.rotulo,
    required this.activo,
    required this.aoTocar,
    this.occupation,
  });

  final String rotulo;
  final bool activo;
  final VoidCallback aoTocar;

  /// O número que nomeia a arte da classe. Nulo no chip *Todos* e em qualquer
  /// classe que este índice não conheça — e aí o chip desenha só o nome, que
  /// é o mesmo recuo silencioso de `ClassIcon` perante um ficheiro em falta.
  final int? occupation;

  @override
  Widget build(BuildContext context) => Material(
    color: activo ? PWColors.surfaceRaised : PWColors.surface,
    borderRadius: BorderRadius.circular(999),
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: aoTocar,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: activo ? PWColors.accent : PWColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (occupation != null) ...[
              ClassIcon(occupation!, size: 20),
              const SizedBox(width: 7),
            ],
            Text(
              rotulo,
              style: TextStyle(
                color: activo ? PWColors.accent : PWColors.text,
                fontSize: 13,
                fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A grelha, em 16:9 porque é a forma de uma miniatura do YouTube.
class _Grelha extends StatelessWidget {
  const _Grelha({required this.videos});

  final List<Video> videos;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, limites) {
      // Pela largura disponível e não pelo `wide` da página, o mesmo que a
      // grelha de destaques faz: uma coluna a 390 px mostra a miniatura
      // inteira, e três cabem acima de 900.
      final colunas = limites.maxWidth >= 900
          ? 3
          : limites.maxWidth >= 600
          ? 2
          : 1;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: colunas,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          // A miniatura (16:9) mais o espaço das três linhas por baixo. O
          // valor é medido e não estimado: a 16/12.6 o cartão transbordava
          // 7,1 px assim que o título ia a duas linhas e havia detalhes — e
          // isso com as fontes reais, portanto defeito e não artefacto do
          // harness.
          childAspectRatio: 16 / 13.6,
        ),
        itemCount: videos.length,
        itemBuilder: (_, i) => _Cartao(video: videos[i]),
      );
    },
  );
}

class _Cartao extends StatelessWidget {
  const _Cartao({required this.video});

  final Video video;

  /// `Bárbaro · gsafoot · 12/10/2026`, sem separadores soltos onde faltar
  /// um dos três — um `·` a abrir a linha é o que acontece quando se junta
  /// campos vazios sem olhar.
  String get _quem =>
      [?video.classe, ?video.personagem, ?video.dataEscrita].join('  ·  ');

  @override
  Widget build(BuildContext context) => Material(
    color: PWColors.surface,
    borderRadius: BorderRadius.circular(12),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => unawaited(
        launchUrl(
          Uri.parse(video.endereco),
          mode: LaunchMode.externalApplication,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  video.miniatura,
                  fit: BoxFit.cover,
                  // Uma miniatura que não carrega deixa a moldura escura e o
                  // título a falar — nunca uma caixa partida, o mesmo recuo
                  // silencioso que `ItemIcon` faz.
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: PWColors.surfaceRaised),
                ),
                const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    size: 46,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PWColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                // Duas linhas por baixo do título, cada uma a responder a uma
                // pergunta diferente: *quem gravou e quando*, depois *qual foi
                // a guerra*. Juntas numa só, a segunda metade seria sempre a
                // que o `ellipsis` comeria.
                if (_quem.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _quem,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PWColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (video.detalhes != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    video.detalhes!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PWColors.papel,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SemVideos extends StatelessWidget {
  const _SemVideos({required this.procurando});

  /// **"Nada aqui ainda" e "nada que case com isto" são coisas diferentes**,
  /// e só a primeira é sobre a página. Dizer a errada manda o visitante
  /// embora quando bastava apagar o que escreveu.
  final bool procurando;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36),
    child: Center(
      child: Text(
        procurando
            ? 'Nenhum vídeo com esses filtros.'
            : 'Ainda não há vídeos aqui.',
        style: const TextStyle(color: PWColors.textMuted, fontSize: 14),
      ),
    ),
  );
}

/// O convite, sempre visível.
///
/// **Não só quando a grelha está vazia**, e a razão é a própria política da
/// página: como nada é garimpado, ela depende de alguém se oferecer.
/// Escondê-lo depois de entrar o primeiro vídeo fecharia a porta por onde a
/// página se enche.
class _Convite extends StatelessWidget {
  const _Convite();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: PWColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: PWColors.border),
    ),
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        const Text(
          'Quer o seu vídeo aqui?',
          style: TextStyle(
            color: PWColors.papel,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        InkWell(
          onTap: () => unawaited(
            launchUrl(
              Uri.parse(discordInvite),
              mode: LaunchMode.externalApplication,
            ),
          ),
          child: const Text(
            'Fale comigo no Discord',
            style: TextStyle(
              color: PWColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Text(
          'ou me procure no jogo, nick duhit.',
          style: TextStyle(color: PWColors.textMuted, fontSize: 14),
        ),
      ],
    ),
  );
}
