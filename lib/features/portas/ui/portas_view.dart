import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/result/result.dart';
import '../../../core/theme/pw_colors.dart';
import '../../../market/versoes_repository.dart';
import '../../guias/ui/widgets/guias_secao.dart';
import '../../home/ui/widgets/cabecalho.dart';
import '../../home/ui/widgets/ao_vivo_strip.dart';
import '../../home/ui/widgets/rodape.dart';
import '../domain/versao.dart';
import 'widgets/abertura.dart';
import 'widgets/canal_do_portal.dart';
import 'widgets/faixa_das_versoes.dart';
import 'widgets/heroi_da_raiz.dart';
import 'widgets/novidades_na_raiz.dart';

/// The front door, now that the site is two marketplaces.
///
/// `/` used to open the 1.8.7 home directly; a visitor who already knows
/// where they are going never sees this screen at all. Every link shared in
/// the community already names a version — `/filtro`, the five preset tools,
/// `/registros`, `/runas` — so this is only for whoever typed `portalpw.net`
/// cold, with no idea yet which mercado they want.
///
/// **It answers two questions and nothing else, on purpose: which version,
/// how many characters, how stale.** Each door is a tall, 2:3 portrait of
/// one class from that version's own roster, with the facts in a footer over
/// a veil at the bottom — see [_classeDaPorta] for which class and why, and
/// `_Portas`'s own doc for why the card is a portrait and not the wide
/// letterbox it first shipped as. The picture says something true about what
/// is behind the door instead of just decorating it. What stays off this
/// screen is a feature list: there is nothing to sell here, only a fork to
/// resolve, and the front page already learned what a second menu costs the
/// day it carried one twice. Selling the site a second time to somebody
/// already on it is the exact shape of that mistake, and art is not exempt
/// from it — which is why the picture stays a backdrop for three facts
/// rather than becoming a pitch of its own.
///
/// **It reads `web/versoes.json` and nothing bigger.** Each marketplace's
/// index is ~4 MB; downloading either one just to print a character count
/// would make the cheapest screen on the site the heaviest one to load.
class PortasView extends StatefulWidget {
  const PortasView({super.key});

  @override
  State<PortasView> createState() => _PortasViewState();
}

/// What the screen is doing right now.
sealed class _Estado {
  const _Estado();
}

class _Carregando extends _Estado {
  const _Carregando();
}

/// The file is there and could not be read — a real failure, and this screen
/// must not quietly draw it as two ordinary doors. Reaching `versoes.json`
/// and failing is different from the file simply having nothing yet for one
/// version (or for every version): that case is not an error at all, and
/// [_PortasViewState._carregar] folds it into [_Pronta] with an empty map
/// instead, which is what draws every door dimmed — the true answer, not a
/// hidden one.
class _Inacessivel extends _Estado {
  const _Inacessivel();
}

class _Pronta extends _Estado {
  const _Pronta(this.portas);
  final List<Porta> portas;
}

class _PortasViewState extends State<PortasView> {
  _Estado _estado = const _Carregando();

  @override
  void initState() {
    super.initState();
    unawaited(_carregar());
  }

  Future<void> _carregar() async {
    try {
      final resultado = await getIt<VersoesRepository>().carregar();
      if (!mounted) return;

      setState(() {
        _estado = resultado.fold((versoes) => _Pronta(portasDe(versoes)), (
          failure,
        ) {
          // No collection has ever run for any version — not a failure, the
          // screen one would see before the collector's first pass. An empty
          // map draws every door dimmed, which is exactly what is true.
          if (failure is IndexMissingFailure) {
            return _Pronta(portasDe(const {}));
          }
          return const _Inacessivel();
        });
      });
    } catch (_) {
      // `VersoesRepository.carregar` itself never throws — it folds every
      // failure into a `Result`. The one thing that can still throw here is
      // `getIt<VersoesRepository>()` failing to resolve — a registration that
      // never ran, or ran against the wrong GetIt instance — and this used to
      // reach `unawaited` in `initState` unguarded, which swallowed it and
      // left the screen spinning forever with no error anywhere. A loading
      // state that cannot fail is a lie: any throw here draws the same error
      // screen an unreadable `versoes.json` would.
      if (!mounted) return;
      setState(() => _estado = const _Inacessivel());
    }
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;

    return Scaffold(
      // **A barra assenta sobre a arte do herói**, como na maquete: o corpo
      // passa por baixo dela e o palco começa no topo do ecrã em vez de uma
      // faixa abaixo. Só aqui — nas telas de versão a barra tem chão próprio
      // porque o que lhe fica por baixo é a página e não uma imagem.
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // Declared `false` on purpose: with no `leading` of its own, a pushed
        // route gets Flutter's automatic back arrow — which would sit beside
        // `Cabecalho`'s own mark, a second way home nobody asked for. The
        // mark is the only door here, the same arrangement every screen
        // without a hand-declared arrow shares.
        automaticallyImplyLeading: false,
        // Sem chão e sem sombra: o que se vê por baixo é a arte.
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Cabecalho(
          wide: largura >= Cabecalho.larguraMinima,
          // No `versao`: this is the one screen that has not picked a
          // marketplace yet, and printing either version here would be the
          // site answering a question nobody asked it.
          //
          // E `semMercado` pela mesma razão levada até ao fim: sem versão,
          // `rotaDaTool` cai no 1.8.7, portanto as pílulas de ferramentas e
          // guias escolhiam o mercado em silêncio para quem clicasse. Fica só
          // *Novidades*, que serve os dois. Ver `Cabecalho.semMercado`.
          semMercado: true,
        ),
      ),
      body: switch (_estado) {
        _Carregando() => const Center(
          child: CircularProgressIndicator(color: PWColors.accent),
        ),
        _Inacessivel() => const _Mensagem(
          icone: Icons.cloud_off_outlined,
          texto: 'Não deu para carregar as versões agora.',
          detalhe: 'Tente de novo em alguns minutos.',
        ),
        _Pronta(:final portas) => _Portas(portas: portas),
      },
    );
  }
}

class _Mensagem extends StatelessWidget {
  const _Mensagem({
    required this.icone,
    required this.texto,
    required this.detalhe,
  });

  final IconData icone;
  final String texto;
  final String detalhe;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 40, color: PWColors.textMuted),
          const SizedBox(height: 14),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: PWColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            detalhe,
            textAlign: TextAlign.center,
            style: const TextStyle(color: PWColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}

/// The two doors, side by side above 620 and stacked below it — the same
/// shape `RunasView` already uses for its own single-column fallback.
///
/// **Each door is a portrait, 2:3 — the same proportion `DestaquesView` cuts
/// its own cards to, and for the same reason: that is the shape the art was
/// cropped for.** The first version let the door's width set its height,
/// which on a 760 px page made a door about 370×150 — a letterbox so wide
/// that a 480×720 portrait had nothing left to show but a wing or a slice of
/// cape, no face, no figure. `AspectRatio` fixes the shape instead of
/// measuring it off whatever width the row happens to have.
///
/// **E a página passou a ter coisas abaixo das portas, a 09/11/2026.** Esta
/// nota dizia que havia espaço vertical de sobra porque *«nunca houve nada
/// abaixo da dobra aqui a competir»*; há agora — a abertura acima, os guias,
/// o canal e os streamers abaixo. Com conteúdo a sério a página rola sempre,
/// portanto **os dois ramos de layout colapsaram num só**: o rodapé deixou de
/// ser pregado em baixo no caso largo, porque deixou de haver espaço de sobra
/// para o prender. Um ramo a menos é um ramo a menos para divergir.
class _Portas extends StatelessWidget {
  const _Portas({required this.portas});

  final List<Porta> portas;

  static const _lado = 620.0;

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final ladoALado = largura >= _lado;

    // **760 px era a medida de três cartas e um rodapé.** Com abertura,
    // guias, canal e streamers a página passou a ser um documento, e a
    // maquete mede 1180 (`--col: 1180px`), lido do CSS dela.
    const colunaDeLeitura = 1180.0;
    final margem = ladoALado ? 24.0 : 16.0;

    final abertura = Padding(
      // `.intro { padding: 46px 24px 30px }`.
      padding: const EdgeInsets.fromLTRB(24, 46, 24, 30),
      child: Abertura(wide: ladoALado),
    );

    final linha = FaixaDasVersoes(
      portas: portas,
      wide: ladoALado,
      larguraDaColuna: colunaDeLeitura,
    );

    final grade = Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(margem, 0, margem, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: colunaDeLeitura),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // `section { padding: 58px 0 }`.
              // `section { padding: 58px 0 }`.
              SizedBox(height: ladoALado ? 58 : 40),
              // Os guias das três versões, cada um com a sua à vista — aqui a
              // etiqueta é a informação que falta, ao contrário de uma tela de
              // versão onde seria ruído. Ver `GuiasSecao`.
              SizedBox(height: ladoALado ? 30 : 24),
              GuiasSecao(versao: null, wide: ladoALado),
              // **Quem está ao vivo, sem pedir versão — e é esta a tela que
              // podia mostrá-los sem versão nenhuma.** Pedido do dono a
              // 09/11/2026: o 1.4.4 tem de aparecer na home. Ele não tem tela
              // própria ainda, e as duas que têm faixa recusam-no com razão,
              // portanto o canal que escreve *1.4.4* no título não aparecia
              // em sítio nenhum do site — e a faixa é uma cortesia a quem
              // transmite.
              //
              // `versao: null` não é desleixo: a raiz não é de versão
              // nenhuma, logo não afirma nada ao mostrar quem não escreveu a
              // sua. É o contrário de uma página de versão, onde mostrar
              // alguém sem versão seria o site a dizer o que não sabe.
              // **O canal é do site e não de uma versão**, portanto vive
              // aqui e não se repete na tela de cada mercado.
              CanalDoPortal(wide: ladoALado, espacoAcima: 34),
              // A ordem da spec: canal, novidades, streamers. As novidades
              // ficam entre os dois porque são o que muda sozinho — e o que
              // vem logo acima e logo abaixo também muda, portanto a página
              // acaba com três secções vivas em vez de uma perdida no meio
              // de conteúdo fixo.
              NovidadesNaRaiz(wide: ladoALado, espacoAcima: 34),
              AoVivoStrip(wide: ladoALado, espacoAcima: 34),
              SizedBox(height: ladoALado ? 30 : 24),
              const Rodape(),
            ],
          ),
        ),
      ),
    );

    // **Um ramo só, desde 09/11/2026.** Havia dois: largo, o rodapé ficava
    // pregado em baixo e as portas centravam-se no que sobrava; empilhado, o
    // rodapé era o fim da página e rolava com ela. O que os separava era
    // haver espaço de sobra no caso largo — e com a abertura acima e três
    // secções abaixo não há: a página rola em qualquer largura.
    //
    // O aviso que ficava aqui continua a valer para quem pensar em voltar
    // atrás: uma tentativa de servir os dois casos com um desenho só
    // (`minHeight` + `IntrinsicHeight`) empurrou o rodapé para fora do ecrã
    // no caso largo. A saída não é um truque que equilibra os dois — é não
    // ter dois.
    // **O herói sangra e o resto não.** A arte é o chão da página, portanto
    // prendê-la à coluna de leitura daria uma fotografia emoldurada no meio
    // do ecrã — o contrário do que ela é. O **texto** dela alinha com a
    // coluna, calculado da mesma largura, para a manchete e a prosa abaixo
    // começarem na mesma linha vertical.
    final sobra = (largura - colunaDeLeitura) / 2;
    final recuoDoHeroi = sobra > 0 ? sobra + margem : margem;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroiDaRaiz(
            wide: ladoALado,
            // A coleta mais recente das que existem: é ela que decide a
            // classe, e assim a página só muda quando o mercado muda.
            quando: _coletaMaisRecente(),
            margemHorizontal: recuoDoHeroi,
          ),
          // A abertura e a faixa vêm antes do resto porque a faixa **sangra
          // de margem a margem** — é o `border-top`/`border-bottom` da
          // maquete a atravessar o ecrã — e por isso não cabe dentro da
          // coluna de leitura.
          abertura,
          linha,
          grade,
        ],
      ),
    );
  }

  /// A data da coleta mais recente, ou uma fixa quando ainda não houve
  /// nenhuma.
  ///
  /// **Fixa e não `DateTime.now()`**: a classe do herói deriva daqui, e um
  /// relógio faria a página mudar de cara a cada recarregamento — que é a
  /// regra que `classeDoCartaz` já segue, pela mesma razão.
  DateTime _coletaMaisRecente() {
    final datas = [
      for (final porta in portas)
        if (porta.resumo != null) porta.resumo!.coletadoEm,
    ];
    if (datas.isEmpty) return DateTime.utc(2026, 1, 1);
    datas.sort();
    return datas.last;
  }
}
