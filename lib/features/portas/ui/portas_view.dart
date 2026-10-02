import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/result/result.dart';
import '../../../core/theme/pw_colors.dart';
import '../../../core/theme/pw_theme.dart';
import '../../../market/versoes.dart';
import '../../../market/versoes_repository.dart';
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
/// how many characters, how stale.** No class art, no feature list — there
/// is nothing to sell here, only a fork to resolve, and the front page
/// already learned what a second menu costs the day it carried one twice.
/// Selling the site a second time to somebody already on it is the exact
/// shape of that mistake.
///
/// **It reads `web/versoes.json` and nothing bigger.** Each marketplace's
/// index is ~4 MB; downloading either one just to print a character count
/// would make the cheapest screen on the site the heaviest one to load.
class PortasView extends StatefulWidget {
  const PortasView({super.key, this.carregar});

  /// Reads `versoes.json`. Injected so the suite can hand in a fixed
  /// [Result] without a network — `null` reaches for the real
  /// [VersoesRepository] through GetIt, the way `NovidadesView` already does
  /// for its own repository.
  final Future<Result<Map<String, VersaoResumo>>> Function()? carregar;

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
    final carregar = widget.carregar ?? getIt<VersoesRepository>().carregar;
    final resultado = await carregar();
    if (!mounted) return;

    setState(() {
      _estado = resultado.fold((versoes) => _Pronta(portasDe(versoes)), (
        failure,
      ) {
        // No collection has ever run for any version — not a failure, the
        // screen one would see before the collector's first pass. An empty
        // map draws every door dimmed, which is exactly what is true.
        if (failure is IndexMissingFailure) return _Pronta(portasDe(const {}));
        return const _Inacessivel();
      });
    });
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
class _Portas extends StatelessWidget {
  const _Portas({required this.portas});

  final List<Porta> portas;

  static const _lado = 620.0;

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final ladoALado = largura >= _lado;

    final linha = Flex(
      direction: ladoALado ? Axis.horizontal : Axis.vertical,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < portas.length; i++) ...[
          if (i > 0)
            SizedBox(width: ladoALado ? 20 : 0, height: ladoALado ? 0 : 20),
          if (ladoALado)
            Expanded(child: _Porta(porta: portas[i]))
          else
            _Porta(porta: portas[i]),
        ],
      ],
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          // `crossAxisAlignment: stretch` on the horizontal layout asks both
          // doors for the taller one's height, and a `Flex` sitting in a
          // vertical `SingleChildScrollView` offers an *infinite* one to
          // stretch into — `BoxConstraints forces an infinite height`.
          // `IntrinsicHeight` is what gives the row a real number to stretch
          // against instead, measuring each door first. Only needed side by
          // side: stacked, `stretch` works on the horizontal cross axis,
          // which the `ConstrainedBox` above already bounds.
          child: ladoALado ? IntrinsicHeight(child: linha) : linha,
        ),
      ),
    );
  }
}

class _Porta extends StatelessWidget {
  const _Porta({required this.porta});

  final Porta porta;

  @override
  Widget build(BuildContext context) {
    final pronta = porta.pronta;

    return Opacity(
      key: Key('porta-${porta.chave}'),
      // The same 0.5 `GavetaItem` dims an unready tool with — one rule for
      // "the shape of the place exists before the place does", drawn twice.
      opacity: pronta ? 1 : 0.5,
      child: Material(
        color: PWColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          // `null` rather than a no-op callback: `InkWell` itself reads a
          // null `onTap` as disabled, which is the only thing that keeps an
          // unready door from drawing its own ripple over nothing.
          onTap: pronta
              ? () => Navigator.of(context).pushNamed(porta.rota)
              : null,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PWColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The version's own name — a numeral, like every count and
                // date on this card, so it stays on the body face. Marcellus
                // draws Roman figures: its 1 has no flag and its 0 is barely
                // an O.
                Text(
                  porta.nome,
                  style: const TextStyle(
                    fontFamily: PWTheme.body,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: PWColors.papel,
                  ),
                ),
                const SizedBox(height: 14),
                if (pronta)
                  _Resumo(resumo: porta.resumo!)
                else
                  const _EmBreve(),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
        style: const TextStyle(fontSize: 14, color: PWColors.textMuted),
      ),
      const SizedBox(height: 4),
      Text(
        'coletado em ${_data(resumo.coletadoEm.toLocal())}',
        style: const TextStyle(fontSize: 12, color: PWColors.textMuted),
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
