import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/result/result.dart';
import '../../../core/theme/pw_colors.dart';
import '../../../core/theme/pw_theme.dart';
import '../../../market/index_repository.dart' show IndexRepository;
import '../../../market/versoes.dart';
import '../../../market/versoes_repository.dart';
import '../../home/domain/arte_da_classe.dart';
import '../../home/domain/visit_label.dart' show groupThousands;
import '../../home/ui/widgets/cabecalho.dart';
import '../domain/versao.dart';

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
      appBar: AppBar(
        // Declared `false` on purpose: with no `leading` of its own, a pushed
        // route gets Flutter's automatic back arrow — which would sit beside
        // `Cabecalho`'s own mark, a second way home nobody asked for. The
        // mark is the only door here, the same arrangement every screen
        // without a hand-declared arrow shares.
        automaticallyImplyLeading: false,
        title: Cabecalho(
          wide: largura >= Cabecalho.larguraMinima,
          // No `versao`: this is the one screen that has not picked a
          // marketplace yet, and printing either version here would be the
          // site answering a question nobody asked it.
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
/// measuring it off whatever width the row happens to have, and the page has
/// the vertical room to spend: there was never anything else below the fold
/// here to compete with it.
class _Portas extends StatelessWidget {
  const _Portas({required this.portas});

  final List<Porta> portas;

  static const _lado = 620.0;

  /// The shape `DestaquesView`'s own cards use — see the class doc. Keeping
  /// one ratio for every tall card on the site is the point: two card shapes
  /// doing the same job one screen apart is how a site stops looking
  /// designed.
  static const _proporcao = 2 / 3;

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final ladoALado = largura >= _lado;

    Widget porta(int i) => AspectRatio(
      aspectRatio: _proporcao,
      child: _Porta(porta: portas[i]),
    );

    final linha = Flex(
      direction: ladoALado ? Axis.horizontal : Axis.vertical,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < portas.length; i++) ...[
          if (i > 0)
            SizedBox(width: ladoALado ? 20 : 0, height: ladoALado ? 0 : 20),
          if (ladoALado) Expanded(child: porta(i)) else porta(i),
        ],
      ],
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: linha,
        ),
      ),
    );
  }
}

/// Which class's art each door wears, and why that class and not another.
///
/// **Chosen so the picture itself says something true about the version
/// behind the door, not just decoration.** 1.2.6 has exactly six classes —
/// the classic ones, [classesClassicasPw126] — and 1.8.7 adds eleven more
/// that 1.2.6 never had. Giving each door a class from its *own* roster means
/// the two pictures differ for a reason a player can read, rather than being
/// two arbitrary faces.
///
/// `Guerreiro` for 1.2.6: one of its own six, and the art reads strongly even
/// at this card's modest width. `Espiritualista` for 1.8.7: one of the eleven
/// 1.2.6 never had, and not a random pick either — it is the class this
/// project's own CLAUDE.md already reaches for to name the price gap the
/// whole tool exists to show (Gege, 8000 TCC for the same 70-attack weapon
/// tmzin's Tormentador pays 130 for). The two also read apart at a glance —
/// warm red and orange against cool purple and teal — so the pair never
/// looks like one picture split in half.
const _classeDaPorta = {
  IndexRepository.pw126: 'Guerreiro',
  IndexRepository.pw187: 'Espiritualista',
};

/// One door: a tall card whose background is the class's own art, read
/// through a veil, with the version's facts in a footer at the bottom —
/// `DestaquesView`'s `_Carta` one screen over, not a treatment invented
/// fresh for this one. Two card shapes doing the same job here would be how
/// the site stops looking designed.
class _Porta extends StatelessWidget {
  const _Porta({required this.porta});

  final Porta porta;

  @override
  Widget build(BuildContext context) {
    final pronta = porta.pronta;
    final arte = arteVerticalDaClasse(_classeDaPorta[porta.chave] ?? '');

    return Opacity(
      key: Key('porta-${porta.chave}'),
      // The same 0.5 `GavetaItem` dims an unready tool with — one rule for
      // "the shape of the place exists before the place does", drawn twice.
      // The art sits inside this same subtree, so an unready door dims its
      // picture along with everything else — never a bright photo over a
      // greyed-out door, which would read as the live one.
      opacity: pronta ? 1 : 0.5,
      child: Material(
        // The base layer, always on: what shows through if the art fails to
        // load (`errorBuilder` below draws nothing rather than a broken
        // box) and what the corners show once the image is clipped to them.
        color: PWColors.surface,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          // `null` rather than a no-op callback: `InkWell` itself reads a
          // null `onTap` as disabled, which is the only thing that keeps an
          // unready door from drawing its own ripple over nothing.
          onTap: pronta
              ? () => Navigator.of(context).pushNamed(porta.rota)
              : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PWColors.border),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // A class with no art draws the plain ground, never a
                // borrowed face — the same silent fallback
                // `arteVerticalDaClasse` itself makes by returning null.
                if (arte != null)
                  Image.asset(
                    arte,
                    fit: BoxFit.cover,
                    // Where the faces in these crops actually sit — the same
                    // tuning `DestaquesView`'s `_Carta` uses for the same
                    // asset family.
                    alignment: const Alignment(0, -0.76),
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                if (arte != null) const _Veu(),
                _Rodape(porta: porta, pronta: pronta),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Darkens only the card's lower reach, so the footer's text has solid
/// ground to land on without flattening the art above it.
///
/// Copied from `DestaquesView`'s own `_Veu` rather than retuned from
/// scratch — including the lesson that cost that file a real defect: the
/// ramp has to be dark **where the text starts**, not where the card ends.
/// Shipped once there at a 62% stop, it left the label on raw artwork on
/// five cards out of six, and only the sixth happened to read because that
/// particular painting was dark in the right place. A gradient whose
/// legibility depends on which picture sits behind it is not a design, it is
/// a coincidence — so this door inherits the same four stops rather than
/// risking a fifth version of that mistake.
class _Veu extends StatelessWidget {
  const _Veu();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          PWColors.noite.withValues(alpha: 0.55),
          PWColors.noite.withValues(alpha: 0.88),
          PWColors.noite.withValues(alpha: 0.97),
        ],
        stops: const [0.38, 0.58, 0.78, 1],
      ),
    ),
  );
}

/// The version's name, count and date, stacked over the veil at the bottom
/// of the card — the same position and shape `DestaquesView`'s `_Rodape`
/// already uses for the same job one screen over.
class _Rodape extends StatelessWidget {
  const _Rodape({required this.porta, required this.pronta});

  final Porta porta;
  final bool pronta;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The version's own name — a numeral, like every count and date
          // on this card, so it stays on the body face. Marcellus draws
          // Roman figures: its 1 has no flag and its 0 is barely an O.
          Text(
            porta.nome,
            style: const TextStyle(
              fontFamily: PWTheme.body,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: PWColors.papel,
            ),
          ),
          const SizedBox(height: 8),
          if (pronta) _Resumo(resumo: porta.resumo!) else const _EmBreve(),
        ],
      ),
    ),
  );
}

class _Resumo extends StatelessWidget {
  const _Resumo({required this.resumo});

  final VersaoResumo resumo;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${groupThousands(resumo.personagens)} personagens à venda',
        // `apagado`, not `textMuted`: this text now sits on `_Veu`'s dark
        // wash rather than the flat `surface` it was tuned against before,
        // and `apagado` is the muted tone `DestaquesView`'s own footer
        // already uses over the same wash.
        style: const TextStyle(fontSize: 14, color: PWColors.apagado),
      ),
      const SizedBox(height: 4),
      Text(
        'coletado em ${_data(resumo.coletadoEm.toLocal())}',
        style: const TextStyle(fontSize: 12, color: PWColors.apagado),
      ),
    ],
  );

  static String _data(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }
}

class _EmBreve extends StatelessWidget {
  const _EmBreve();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: PWColors.surfaceRaised,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'em breve',
      style: TextStyle(
        fontSize: 10,
        color: PWColors.textMuted,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
