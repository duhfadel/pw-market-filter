import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/rotas.dart' as rotas;
import '../../../core/theme/medidas_da_maquete.dart';
import '../../../core/theme/pw_colors.dart';
import '../../../market/market_index.dart';
import '../../ads/ad_slot.dart';
import '../../search/data/address_bar.dart';
import '../../search/domain/search_query.dart';
import '../../search/domain/search_query_url.dart';
import '../../search/ui/search_state.dart';
import '../../search/ui/search_view_model.dart';
import '../domain/arte_da_classe.dart';
import 'widgets/ao_vivo_strip.dart';
import 'widgets/cabecalho.dart';
import 'widgets/cartaz.dart';
import 'widgets/destaques_view.dart';
import '../../guias/ui/widgets/guerras_secao.dart';
import '../../guias/ui/widgets/guias_secao.dart';
import 'widgets/faixa_viva.dart';
import 'widgets/tool_navigation.dart';
import 'widgets/ajuda_strip.dart';
import 'widgets/discord_strip.dart';
import 'widgets/rodape.dart';

/// The Cartaz's own claim for the 1.8.7 market, where cards, relics,
/// essences and runes are all real sections of the filter.
const _subtituloPw187 =
    'Arma, cartas, relíquias, essências, runas — o que o marketplace guarda '
    'no inventário e não deixa procurar.';

/// The 1.2.6 market's own claim. That collector has none of 1.8.7's cards,
/// counted items or runes yet, so the hero describes the two families this
/// market's filter actually has — weapon and armour, down to their
/// attributes — rather than promising four it would prune on the very next
/// screen.
const _subtituloPw126 =
    'Arma, armadura e atributos — o que o marketplace guarda no inventário '
    'e não deixa procurar.';

/// Opens the filter already answering [query] — every Destaques card is a
/// door into the search that produced it, encoded the same way a shared
/// link is so the filter screen reads it back with `requestUrl`.
///
/// Pushes `AddressBar.canonicalFiltro` for the 1.8.7 home, never the bare
/// `/filtro` — `core/rotas.dart` only reads that path, forever, for links
/// already out in the world; nothing in the app may write it again. The
/// 1.2.6 home ([pw126]) pushes `/1.2.6/filtro` instead: a card built from the
/// 1.2.6 index opening the 1.8.7 filter would hand the query to an index it
/// was never checked against.
void _abrirBusca(
  BuildContext context,
  MarketIndex index,
  SearchQuery query, {
  required bool pw126,
}) {
  final q = encodeQuery(query, index);
  final path = pw126 ? '/${rotas.pw126}/filtro' : AddressBar.canonicalFiltro;
  Navigator.of(context).pushNamed(q.isEmpty ? path : '$path?$q');
}

/// The Portal's front page: the mark, the Cartaz, the Destaques, Streamers
/// and Comunidade.
///
/// It loads the market index like the filter does, and for the same reason it
/// is worth the wait: the Cartaz and the Destaques are both drawn from it. The
/// Cartaz opens on a class's own art before a single number is known, so the
/// wait never blanks the fold — only the class-specific parts (the Cartaz's
/// class and the six Destaques cards) wait on the load.
///
/// **The tool cards that used to sit below the Destaques are gone.**
/// `Cabecalho`'s pills, on every screen, already list the same tools and the
/// same guide — a second navigation surface for the same set, on the same
/// page, was the thing the owner called out on 01/10/2026: "não acho que
/// valha a pena duplicar".
///
/// **The closed news bar that used to sit here is gone too, moved on the
/// same day.** `/novidades` got a screen of its own, reachable from
/// `Cabecalho`'s own *Novidades* pill on every screen — a second surface for
/// the same announcements, on the same page, was the same duplication the
/// tool cards already were. What does not survive the move: the bar's closed
/// header showed the latest entry's own title and date, so a returning
/// visitor could tell whether the thing inside was the one they had already
/// read. The pill that replaces it carries only a label and an unread dot —
/// see `cabecalho.dart`'s `_NovidadesPill`, which is also where the dot's
/// rules now live.
class HomeView extends StatelessWidget {
  const HomeView({super.key, this.pw126 = false});

  /// Whether this is the 1.2.6 marketplace's home rather than 1.8.7's.
  ///
  /// The two homes share every section below the Cartaz — the streamers, the
  /// community, the advert, the footer — because none of that is about which
  /// marketplace a visitor is in. What changes is the two places that *are*:
  /// the Cartaz's own class rotates through [classesClassicasPw126] instead
  /// of the full seventeen, and the Destaques below it draw two cards
  /// (`destaques126De`) instead of six. `main.dart` is what supplies the
  /// right index behind this flag — see its own routing table for the
  /// version-named `SearchViewModel` each home reads from.
  final bool pw126;

  /// Above this the page is not competing for space, and holding the layout at
  /// its tablet size leaves the mark reading as a small card adrift in black —
  /// on a 1920 monitor the logo was 18% of the width. Everything grows a step.
  static const _largeWidth = 1280.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // The grid becomes a column below this — the same number as
    // `Cabecalho.larguraMinima`, where its own pills collapse into the
    // overflow menu. One breakpoint, read from the one place it is defined.
    final wide = width >= Cabecalho.larguraMinima;
    final large = width >= _largeWidth;
    // **1180 no degrau de cima, que é a coluna da maquete** — `--col: 1180px`,
    // lida do CSS dela e já usada pela raiz. Esteve em 1040 até 10/11/2026,
    // por uma razão que continua verdadeira e que deixou de ser o limite: a
    // 900 a manchete antiga partia com *«usando»* sozinho numa segunda linha,
    // a 1366 e a 1920. 1040 era o mínimo que a resolvia, e ficou a valer como
    // se fosse o máximo.
    //
    // O que o denunciou foram os Destaques: a seis colunas, 1040 menos as
    // margens dá 960 de conteúdo e cartas de 148 px, onde a maquete lhes dá
    // 1132 e 177. Era isso que fazia a página inteira parecer um degrau
    // abaixo do desenho.
    //
    // **A faixa de tablet fica nos 780**, e isso é separado: aquele tecto não
    // é folga a mais, é o ponto em que a tipografia do Cartaz deixa de caber
    // — a 780 px o título dele já estourava a própria caixa em 36 px.
    final maxWidth = large ? Maquete.colunaDeLeitura : 780.0;
    // `.env { padding: 0 24px }` no degrau da maquete. Nos outros dois fica o
    // respiro que esta tela já tinha: ali a coluna é estreita e 24 px
    // colariam o texto à borda do ecrã.
    final margem = large ? 24.0 : (wide ? 40.0 : 20.0);

    return Scaffold(
      // **A barra assenta sobre a arte do herói**, como na raiz e como a
      // maquete faz nas duas telas: `.barra { position:absolute; top:0 }`.
      // Estava dentro da coluna de leitura, o que lhe dava chão próprio e
      // empurrava o herói para baixo dela.
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: _ComMargem(
          margem: margem,
          child: Cabecalho(
            wide: wide,
            versao: pw126 ? rotas.pw126 : rotas.pw187,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Behind everything and touching nothing: the light is decoration,
          // and decoration that eats a tap is a bug.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(child: _Aurora()),
          ),
          SafeArea(
            // Centred across, pinned to the **top** down the page. It used to
            // be a plain `Center`, from when the front page was a logo, a
            // headline and three cards: short enough that sitting in the
            // middle of the window looked composed rather than adrift.
            //
            // The page has grown since — the Destaques, the news panel — and on
            // a tall window the same rule opened a screen and a half of empty
            // sky above the logo before anything was readable. Vertical
            // centring is a rule about short pages, and this one stopped being
            // one.
            // **The scrollable is the whole width, and the cap lives inside
            // it.** It was the other way round — a 1040-wide `ListView`
            // centred in the window — and a wheel event lands on whatever is
            // under the pointer: out in the margins that was the background,
            // so the page did not move at all. It reads as a broken site
            // rather than as a layout choice, and it was reported that way.
            //
            // The scrollbar hugging the column instead of the window's edge
            // was the same fact wearing a different face. Both are gone.
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // **O herói e a faixa sangram de margem a margem**, como na
                // raiz: estavam presos à coluna de leitura e a arte ficava
                // emoldurada no meio do ecrã — uma fotografia ao lado do
                // conteúdo, que é o contrário do que ela é. O **texto** do
                // herói alinha com a coluna, calculado da mesma largura.
                //
                // Por isso vivem aqui, fora do `ConstrainedBox`, e tudo o
                // resto continua lá dentro.
                BlocBuilder<SearchViewModel, SearchState>(
                  builder: (context, state) {
                    final ready = state is SearchReady ? state : null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Cartaz(
                          // **Fixa por mercado desde 10/11/2026**, e era
                          // sorteada pela data da coleta. Decisão do dono:
                          // cada tela tem a cara dela, como a raiz já tem.
                          classe: classeDoCartaz(
                            pw126 ? rotas.pw126 : rotas.pw187,
                          ),
                          // `large`, not `wide`. Both were built and
                          // measured at 1200 px — close to this
                          // page's `large` step (1280) — and their
                          // "wide" typography does not fit the
                          // tablet band between 680 and 1279: at
                          // 780 px the Cartaz's own 40 px headline
                          // overflowed its box by 36 px. Below
                          // `large`, both fall back to their
                          // compact layout instead of the rest of
                          // the page's `wide` one.
                          wide: large,
                          // The canonical path for 1.8.7, the
                          // version-prefixed one for 1.2.6 — same
                          // reason as `_abrirBusca` above.
                          aoBuscar: () => Navigator.of(context).pushNamed(
                            pw126
                                ? '/${rotas.pw126}/filtro'
                                : AddressBar.canonicalFiltro,
                          ),
                          // One claim per marketplace, not one
                          // shared between them: 1.2.6's own filter
                          // has no cards, relics, essences or runes
                          // — the pruning this branch exists for —
                          // so the 1.8.7 line promised four
                          // families the very next click did not
                          // have.
                          // A segunda porta do herói: os guias,
                          // que servem as três versões e por isso
                          // não escolhem mercado nenhum.
                          aoVerGuias: () =>
                              abrirEndereco(context, '/guias/', externo: true),
                          subtitulo: pw126 ? _subtituloPw126 : _subtituloPw187,
                          // O texto do herói alinha com a coluna de leitura,
                          // calculado da mesma largura — a arte sangra, o
                          // texto não.
                          margemHorizontal: _recuoDoHeroi(
                            width,
                            maxWidth,
                            wide,
                          ),
                        ),
                        if (ready != null) ...[
                          SizedBox(height: wide ? 14 : 10),
                          // **Antes dos Destaques, e isso é a
                          // ordem da pergunta.** A faixa diz o
                          // tamanho e o movimento do mercado; os
                          // Destaques mostram seis pessoas dele.
                          // Invertido, as seis cartas chegariam
                          // antes de haver um mercado para elas
                          // pertencerem — e é o que a maquete
                          // tinha, que foi exactamente a falta
                          // que o dono apontou: «talvez falte a
                          // informaçao antes do market para que o
                          // pessoal entenda o que sao aqueles
                          // numeros».
                          FaixaViva(
                            index: ready.index,
                            wide: wide,
                            larguraDaColuna: maxWidth,
                            margem: wide ? 24 : 16,
                            onAbrir: (query) => _abrirBusca(
                              context,
                              ready.index,
                              query,
                              pw126: pw126,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    // Vertical padding only, applied once for the whole
                    // column. Horizontal padding is per-section instead —
                    // see `_ComMargem` — because the Cartaz bleeds to the
                    // column's own edges, and a shared side padding here
                    // would either pinch it or leave every other section
                    // without one.
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: wide ? 44 : 28),
                      child: Column(
                        // A `ListView` stretches its children across and a
                        // `Column` centres them, so the menu and the news bar
                        // would have shrunk to their own width without this.
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // **Os Destaques ficam dentro da coluna, e o herói
                          // e a faixa fora.** Saíram daqui por engano ao
                          // mover o herói, e passaram a receber a janela
                          // inteira — 1020 px onde a coluna dá 700 — o que
                          // pôs as cinco cartas numa linha só numa largura de
                          // tablet. Era o teste do `dy` que o dizia.
                          BlocBuilder<SearchViewModel, SearchState>(
                            builder: (context, state) {
                              if (state is! SearchReady) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: wide ? 14 : 10,
                                ),
                                child: _ComMargem(
                                  margem: margem,
                                  child: DestaquesView(
                                    index: state.index,
                                    wide: large,
                                    pw126: pw126,
                                    onAbrir: (query) => _abrirBusca(
                                      context,
                                      state.index,
                                      query,
                                      pw126: pw126,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // The tool cards and the guide line used to sit
                          // here, under a `FERRAMENTAS`/`GUIA` heading. They
                          // left on 01/10/2026: `Cabecalho`'s pills, on every
                          // screen, already list the same tools and the same
                          // guide — a card sold them with art and a tagline,
                          // a pill only lists them, but keeping both put two
                          // navigation surfaces for one set on the same page,
                          // one above the other. "não acho que valha a pena
                          // duplicar" is the owner's own call, 01/10/2026. The
                          // *novo* badge that lived on the Títulos card moved
                          // to `GavetaItem`, the drawer row each pill opens —
                          // the one place left that can still show it.
                          SizedBox(height: large ? 32 : (wide ? 26 : 20)),
                          // **Os guias desta versão, e não os do site.**
                          // Pedido do dono a 09/11/2026: guias em todas as
                          // versões, cada uma com os seus. Hoje sete dos oito
                          // são de 1.8.7 sem o dizerem, portanto o 1.2.6
                          // recebe só o que fala do cliente do jogo — e a
                          // porta *Todos os guias* dentro da secção é o que
                          // o impede de ler como «este site tem um guia».
                          //
                          // A pílula *Guias* do cabeçalho continua a destacar
                          // três entradas e não a listar isto: uma gaveta de
                          // navegação diz nomes, esta secção vende o artigo
                          // com a linha dele.
                          _ComMargem(
                            margem: margem,
                            child: GuiasSecao(
                              versao: pw126 ? rotas.pw126 : rotas.pw187,
                              wide: wide,
                            ),
                          ),
                          SizedBox(height: wide ? 26 : 20),
                          // **As guerras, e os vídeos sem o mapa.** A maquete
                          // desenhava os dois lado a lado; o painel do mapa
                          // saiu por duas razões medidas a 10/11/2026 — os
                          // territórios não mudam desde 18/08, e `/guerras/`
                          // está `noindex` e foi retirada do site de
                          // propósito a 29/09. Ver `GuerrasSecao`.
                          //
                          // Depois dos Guias e antes dos streamers: é
                          // comunidade a mostrar o que fez, e pertence a esse
                          // lado da página.
                          _ComMargem(
                            margem: margem,
                            child: GuerrasSecao(
                              versao: pw126 ? rotas.pw126 : rotas.pw187,
                              wide: wide,
                            ),
                          ),
                          SizedBox(height: wide ? 26 : 20),
                          // The closed news bar used to sit here, between the
                          // tools and the streamers — see the class doc above
                          // for what left with it on 01/10/2026 and what it
                          // cost.
                          // Depois das ferramentas e antes da comunidade. É o
                          // lugar que combina com o que a coisa é: cortesia a
                          // quem transmite, não o motivo de alguém ter vindo.
                          // Em cima disputaria com as ferramentas; no rodapé
                          // ninguém veria.
                          _ComMargem(
                            margem: margem,
                            // **Só quem joga esta versão**, pedido do dono
                            // a 09/11/2026. A versão vem do título da
                            // transmissão e não de uma coluna: a Twitch só
                            // diz *Perfect World*, e um título é reescrito a
                            // cada transmissão, portanto quem muda de versão
                            // muda sozinho.
                            child: AoVivoStrip(
                              wide: wide,
                              versao: pw126 ? rotas.pw126 : rotas.pw187,
                            ),
                          ),
                          SizedBox(height: wide ? 26 : 20),
                          _ComMargem(
                            margem: margem,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _Secao(nome: 'Comunidade'),
                                SizedBox(height: wide ? 12 : 10),
                                // **O pedido de ajuda vem primeiro, por
                                // decisão do dono em 23/10/2026.** Esteve no
                                // rodapé antes disso, que foi onde ele o
                                // pediu — e ao ver a página achou pouco
                                // visível, que é a lição do card dos
                                // streamers escrita outra vez.
                                //
                                // As duas linhas são formas de apoiar o site
                                // e lidas juntas dizem isso melhor do que
                                // separadas; qual delas lidera é dele, e é
                                // esta, que é a que custa alguma coisa a quem
                                // atende.
                                //
                                // Só no 1.8.7, porque é lá que o personagem
                                // que recebe existe.
                                if (!pw126) ...[
                                  AjudaStrip(wide: wide),
                                  SizedBox(height: wide ? 6 : 4),
                                ],
                                DiscordStrip(wide: wide),
                              ],
                            ),
                          ),
                          SizedBox(height: wide ? 26 : 20),
                          // The advert came off the home when the page was
                          // rebuilt, because the new design showed no
                          // `PUBLICIDADE` label anywhere. The owner put it
                          // back on 01/10/2026, in the footer.
                          //
                          // Below the community and above the footer, which is
                          // the lowest place on the page that is still the
                          // page. It is the one block here nobody came for, so
                          // it goes last — but it is not hidden, because a
                          // hidden advert is a dishonest one.
                          _ComMargem(margem: margem, child: const AdSlot()),
                          SizedBox(height: wide ? 28 : 22),
                          _ComMargem(margem: margem, child: const Rodape()),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The light behind the front page.
///
/// Three layers, and the order is the whole trick: a violet sky at the top
/// fading into the page's own black, then two soft lights over it — one violet
/// high and centred, one gold low and to the left, which is where the eye
/// already is because that is where the reading starts.
///
/// It costs nothing to download. The alternative tried first was a blurred
/// screenshot of the game, which works and weighs 5 KB, but the greens and
/// browns of a grass valley fight an indigo palette; a gradient cannot go off
/// palette because it is made of the palette.
///
/// It does not scroll. On a phone the page is longer than the screen, and a
/// light that slides up with the content reads as a picture coming loose.
class _Aurora extends StatelessWidget {
  const _Aurora();

  /// Tall enough to cover the fold on a desktop and to fade out before the
  /// cards on a phone.
  static const _height = 900.0;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _height,
    child: Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [PWColors.nightTop, PWColors.background],
              stops: [0, 0.78],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.85),
              radius: 0.9,
              colors: [
                PWColors.glowViolet.withValues(alpha: 0.22),
                PWColors.glowDeep.withValues(alpha: 0.10),
                PWColors.background.withValues(alpha: 0),
              ],
              stops: const [0, 0.45, 1],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.6, -0.2),
              radius: 0.7,
              colors: [
                PWColors.accent.withValues(alpha: 0.09),
                PWColors.accent.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// The page's ordinary side margin, applied one section at a time.
///
/// O recuo lateral do texto do herói, para alinhar com a coluna de leitura.
///
/// A arte sangra de margem a margem e o texto não — a mesma conta que a raiz
/// faz. Sem isto a manchete começaria no bordo do ecrã numa janela larga.
double _recuoDoHeroi(double largura, double maxWidth, bool wide) {
  final sobra = (largura - maxWidth) / 2;
  final margem = wide ? 24.0 : 16.0;
  return sobra > 0 ? sobra + margem : margem;
}

/// Everything on the page carries it except the Cartaz, which bleeds to the
/// reading column's own edges on purpose — see the comment at its call site.
/// A margin shared by every child of one `Column` would have pinched the
/// Cartaz along with the rest; wrapping each section individually is what
/// lets the hero opt out.
class _ComMargem extends StatelessWidget {
  const _ComMargem({required this.margem, required this.child});

  /// **A margem vem de fora e não de uma bandeira.** Era `wide ? 40 : 20`, o
  /// que juntava dois degraus de largura num só booleano — e quando o degrau
  /// de cima passou a 1180 com os 24 px da maquete, um terceiro valor não
  /// tinha por onde entrar. Quem conhece os três degraus é o `build` da
  /// página; este widget só os aplica.
  final double margem;

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: margem),
    child: child,
  );
}

/// The rule above the Comunidade section.
class _Secao extends StatelessWidget {
  const _Secao({required this.nome});

  final String nome;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        nome.toUpperCase(),
        style: const TextStyle(
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
