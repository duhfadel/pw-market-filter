import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/result/result.dart';
import '../../../core/theme/pw_colors.dart';
import '../../../core/theme/pw_theme.dart';
import '../../home/data/novidade_lida.dart';
import '../../home/data/novidade_repository.dart';
import '../../home/domain/novidade.dart';
import '../../home/ui/widgets/cabecalho.dart';
import '../../home/ui/widgets/novidade_texto.dart';

/// The whole history of the site's own announcements, one screen, newest
/// first.
///
/// The front page's bar is a teaser that starts closed — three entries once
/// ran to a thousand pixels there. This is the opposite: whoever opened
/// `/novidades` came to read, so there is no accordion and no "ver mais".
///
/// **Nothing here reads a market fact.** `Novidade` and [NovidadeRepository]
/// are both about the site, not about a marketplace, and that is deliberate —
/// the planned 1.2.6 marketplace reuses this screen with no change, which it
/// could not do if a line here read `MarketIndex`. The import graph is wider
/// than that property, though, and it is worth being precise about the
/// difference: this file reaches `getIt<NovidadeRepository>()` through
/// `core/di/injection.dart`, which also registers `IndexRepository`, so the
/// market index is imported transitively even though nothing in this screen
/// looks at it. A reuse of this screen inherits the whole container, index
/// included — almost certainly harmless, but a different claim from "never
/// reaches it".
///
/// **Opening this screen is also what clears the header pill's unread dot**,
/// moved here on 01/10/2026 from the front page's own closed news bar: that
/// bar used to mark itself read the moment it was tapped open, and the mark
/// now happens here instead, once a load actually succeeds — which is what
/// lets a shared link straight to `/novidades` clear the dot too, not only a
/// tap on the pill that opened it.
class NovidadesView extends StatefulWidget {
  const NovidadesView({super.key, this.carregar, this.lida});

  /// Reads every announcement, [Novidade.publicadaEm] descending.
  ///
  /// Injected so the suite can hand in a fixed [Result] without touching the
  /// network — `null` reaches for the real [NovidadeRepository] through
  /// GetIt, the way every other route in this app finds its data.
  final Future<Result<List<Novidade>>> Function()? carregar;

  /// Marks the newest loaded entry as read. Injected so the suite can share
  /// one [NovidadeLida] between this screen and a pill under test; `null`
  /// reaches for the real browser storage [NovidadeLida] already defaults
  /// to.
  final NovidadeLida? lida;

  @override
  State<NovidadesView> createState() => _NovidadesViewState();
}

/// What the screen is doing right now. A `sealed` set rather than a loading
/// flag and a nullable list, because "no news at all" and "could not load"
/// have to be two states a `switch` cannot blur together.
sealed class _Estado {
  const _Estado();
}

class _Carregando extends _Estado {
  const _Carregando();
}

/// The request failed, or the body did not parse. **Not** the same screen as
/// an empty list — one is the server's fault and the other is simply nobody
/// having posted yet, and telling the reader apart from the owner matters.
class _Indisponivel extends _Estado {
  const _Indisponivel();
}

class _Pronta extends _Estado {
  const _Pronta(this.entradas);
  final List<Novidade> entradas;
}

class _NovidadesViewState extends State<NovidadesView> {
  _Estado _estado = const _Carregando();

  @override
  void initState() {
    super.initState();
    unawaited(_carregar());
  }

  Future<void> _carregar() async {
    final carregar = widget.carregar ?? getIt<NovidadeRepository>().carregar;
    final resultado = await carregar();
    if (!mounted) return;

    // Marked only on success: a failed load does not know what the newest
    // entry actually is, and marking off a stale or empty guess would clear
    // the dot for news this browser never actually saw.
    resultado.fold(
      (entradas) => (widget.lida ?? NovidadeLida()).marcarComoLida(entradas),
      (_) {},
    );

    setState(() {
      _estado = resultado.fold(
        (entradas) => _Pronta([...entradas]..sort(_maisRecentePrimeiro)),
        (_) => const _Indisponivel(),
      );
    });
  }

  static int _maisRecentePrimeiro(Novidade a, Novidade b) =>
      b.publicadaEm.compareTo(a.publicadaEm);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      // Declared `false` on purpose: with no `leading` of its own, a pushed
      // route gets Flutter's automatic back arrow — which would sit beside
      // `Cabecalho`'s own mark, a second way home nobody asked for. The mark
      // is the only door here, the same arrangement every screen without a
      // hand-declared arrow shares.
      automaticallyImplyLeading: false,
      title: Cabecalho(
        wide: MediaQuery.sizeOf(context).width >= Cabecalho.larguraMinima,
        // No `versao`, on purpose: this one screen reads the same twenty
        // messages for both marketplaces, so neither version is more true of
        // it than the other.
      ),
    ),
    body: switch (_estado) {
      _Carregando() => const Center(
        child: CircularProgressIndicator(color: PWColors.accent),
      ),
      _Indisponivel() => const _Mensagem(
        icone: Icons.cloud_off_outlined,
        texto: 'Não deu para carregar as novidades agora.',
        detalhe: 'Tente de novo em alguns minutos.',
      ),
      _Pronta(entradas: []) => const _Mensagem(
        icone: Icons.campaign_outlined,
        texto: 'Nenhuma novidade por aqui ainda.',
        detalhe: 'O que o dono escreve em #novidades aparece aqui.',
      ),
      _Pronta(:final entradas) => _Lista(entradas: entradas),
    },
  );
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

class _Lista extends StatelessWidget {
  const _Lista({required this.entradas});

  final List<Novidade> entradas;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: entradas.length,
        separatorBuilder: (_, _) =>
            const Divider(color: PWColors.border, height: 40),
        itemBuilder: (context, i) => _Entrada(entrada: entradas[i]),
      ),
    ),
  );
}

class _Entrada extends StatelessWidget {
  const _Entrada({required this.entrada});

  final Novidade entrada;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // The date is a count, not a name, so it stays on the body face —
      // Marcellus's `0` is barely an `O` and its `1` has no flag.
      Text(
        _data(entrada.publicadaEm),
        style: const TextStyle(
          color: PWColors.textMuted,
          fontSize: 13,
          letterSpacing: 0.3,
        ),
      ),
      const SizedBox(height: 6),
      // An entry with no title is a remark, not an announcement — a short
      // message in Discord has no wholly-bold first line, and drawing a
      // placeholder heading over it would turn a remark into a shout.
      if (entrada.titulo != null) ...[
        Text(
          entrada.titulo!,
          style: const TextStyle(
            fontFamily: PWTheme.display,
            color: PWColors.text,
            fontSize: 20,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
      ],
      NovidadeTexto(corpo: entrada.corpo),
    ],
  );

  /// `01/10/2026`, the same shape the collection date uses in the filter.
  static String _data(DateTime quando) {
    final local = quando.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
