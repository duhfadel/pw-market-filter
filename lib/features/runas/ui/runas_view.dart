import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/pw_colors.dart';
import '../../../core/widgets/game_icon.dart';
import '../../../core/theme/pw_theme.dart';
import '../../ads/ad_slot.dart';
import '../domain/calculo.dart';
import '../domain/runa.dart';

/// What a rune actually costs, before somebody starts collecting.
///
/// The fusion window shows a percentage and nothing else: it never says that
/// the rune in the centre is the twenty-fifth level seven somebody will feed
/// it, or that two of the nine rungs cost six runes where their neighbours
/// cost four. A level 10 is **648.000** level ones. Nobody arrives at that
/// number by looking at the window.
class RunasView extends StatefulWidget {
  const RunasView({super.key});

  @override
  State<RunasView> createState() => _RunasViewState();
}

class _RunasViewState extends State<RunasView> {
  int _alvo = 9;

  /// Level to how many are already owned. Absent means none.
  final _estoque = <int, int>{};

  @override
  Widget build(BuildContext context) {
    final largo = MediaQuery.sizeOf(context).width >= 620;
    final r = calcular(alvo: _alvo, estoque: _estoque);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calculadora de runas',
          style: TextStyle(fontFamily: PWTheme.display, fontSize: 19),
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
                padding: EdgeInsets.all(largo ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Alvo(
                      alvo: _alvo,
                      aoTrocar: (v) => setState(() => _alvo = v),
                    ),
                    SizedBox(height: largo ? 24 : 18),
                    _Estoque(
                      alvo: _alvo,
                      estoque: _estoque,
                      aoTrocar: (nivel, quantos) => setState(() {
                        if (quantos == 0) {
                          _estoque.remove(nivel);
                        } else {
                          _estoque[nivel] = quantos;
                        }
                      }),
                    ),
                    SizedBox(height: largo ? 28 : 22),
                    _Resultado(calculo: r, largo: largo),
                    SizedBox(height: largo ? 28 : 22),
                    _Forja(estoque: _estoque, largo: largo),
                    SizedBox(height: largo ? 28 : 22),
                    const _Nota(),
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

class _Alvo extends StatelessWidget {
  const _Alvo({required this.alvo, required this.aoTrocar});

  final int alvo;
  final ValueChanged<int> aoTrocar;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Text(
        'Quero fazer uma runa',
        style: TextStyle(color: PWColors.text, fontSize: 16),
      ),
      const SizedBox(width: 14),
      DropdownButton<int>(
        value: alvo,
        dropdownColor: PWColors.surfaceRaised,
        underline: const SizedBox.shrink(),
        style: const TextStyle(
          color: PWColors.accent,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        items: [
          for (var n = 2; n <= nivelMaximo; n++)
            DropdownMenuItem(
              value: n,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ItemIcon(arteDaRuna(n), size: 22),
                  const SizedBox(width: 8),
                  Text('nível $n'),
                ],
              ),
            ),
        ],
        onChanged: (v) {
          if (v != null) aoTrocar(v);
        },
      ),
    ],
  );
}

/// The drawer. One field per level below the target, all on screen.
///
/// Not a picker that adds rows: somebody already knows what they own, and
/// typing into a visible box is faster than choosing a level first.
class _Estoque extends StatelessWidget {
  const _Estoque({
    required this.alvo,
    required this.estoque,
    required this.aoTrocar,
  });

  final int alvo;
  final Map<int, int> estoque;
  final void Function(int nivel, int quantos) aoTrocar;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'JÁ TENHO',
        style: TextStyle(
          color: PWColors.textMuted,
          fontSize: 11,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      // Said in words as well as in the pictures: the icons cycle through the
      // five colours for this reason, and somebody holding a drawer of mixed
      // runes needs to know the mix is not a problem.
      const Text(
        'Serve runa de qualquer cor.',
        style: TextStyle(color: PWColors.textMuted, fontSize: 12, height: 1.4),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (var n = 1; n < alvo; n++)
            _Campo(
              // Keyed by level **and** target: the row is rebuilt when the
              // target changes, and without this the text would stay in the
              // box that has moved on to another level.
              key: ValueKey('$alvo-$n'),
              nivel: n,
              valor: estoque[n] ?? 0,
              aoTrocar: (q) => aoTrocar(n, q),
            ),
        ],
      ),
    ],
  );
}

class _Campo extends StatefulWidget {
  const _Campo({
    required this.nivel,
    required this.valor,
    required this.aoTrocar,
    super.key,
  });

  final int nivel;
  final int valor;
  final ValueChanged<int> aoTrocar;

  @override
  State<_Campo> createState() => _CampoState();
}

class _CampoState extends State<_Campo> {
  late final _controle = TextEditingController(
    text: widget.valor == 0 ? '' : '${widget.valor}',
  );

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 96,
    child: TextField(
      controller: _controle,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: PWColors.text, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'nv ${widget.nivel}',
        labelStyle: const TextStyle(color: PWColors.textMuted, fontSize: 12),
        isDense: true,
        border: const OutlineInputBorder(),
        // The rune itself, because the art brightens with the level: on a
        // screen about levels, the picture reads faster than the label.
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 8, right: 4),
          child: ItemIcon(arteDaRuna(widget.nivel), size: 22),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
      onChanged: (t) => widget.aoTrocar(int.tryParse(t) ?? 0),
    ),
  );
}

class _Resultado extends StatelessWidget {
  const _Resultado({required this.calculo, required this.largo});

  final Calculo calculo;
  final bool largo;

  @override
  Widget build(BuildContext context) {
    if (calculo.jaDa) {
      return _Painel(
        child: Text(
          'Você já tem o suficiente para uma runa nível ${calculo.alvo}.',
          style: const TextStyle(color: PWColors.ok, fontSize: 16),
        ),
      );
    }

    return _Painel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FALTA CONSEGUIR',
            style: TextStyle(
              color: PWColors.accent,
              fontSize: 11,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          // Biggest scale first: it is the one somebody acts on. The level-one
          // line is last because it gives the size of the thing, not an
          // errand — nobody goes looking for 648.000 of anything.
          // **Said once, above, instead of nine times between.** The lines
          // are the same debt in different currencies and must not read as a
          // shopping list — with three of them an `ou` between each carried
          // that; with nine it would be all anyone sees.
          const Text(
            'qualquer uma destas linhas serve',
            style: TextStyle(color: PWColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < calculo.escalas.length; i++)
            _Linha(
              partes: calculo.linhaDe(calculo.escalas[i]),
              forte: i == 0,
              largo: largo,
            ),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({
    required this.partes,
    required this.forte,
    required this.largo,
  });

  final List<Parcela> partes;
  final bool forte;
  final bool largo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 6,
      children: [
        for (var i = 0; i < partes.length; i++) ...[
          if (i > 0)
            const Text(
              '+',
              style: TextStyle(color: PWColors.textMuted, fontSize: 15),
            ),
          _Parcela(parte: partes[i], forte: forte && i == 0, largo: largo),
        ],
      ],
    ),
  );
}

class _Parcela extends StatelessWidget {
  const _Parcela({
    required this.parte,
    required this.forte,
    required this.largo,
  });

  final Parcela parte;
  final bool forte;
  final bool largo;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ItemIcon(arteDaRuna(parte.nivel), size: forte ? 30 : 24),
      const SizedBox(width: 9),
      Text(
        _comPontos(parte.quantos),
        style: TextStyle(
          color: forte ? PWColors.accent : PWColors.text,
          fontSize: forte ? (largo ? 26 : 22) : (largo ? 18 : 16),
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(width: 7),
      Text(
        'nível ${parte.nivel}',
        style: const TextStyle(color: PWColors.textMuted, fontSize: 13),
      ),
    ],
  );

  /// `648.000`, the way this site writes every other number.
  static String _comPontos(int n) {
    final s = '$n';
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

/// The same drawer read from the other end.
///
/// The panel above answers *what do I still need*; this one answers *what can
/// I already make*, which is the question somebody asks when they open the
/// bag before deciding on a target at all.
class _Forja extends StatelessWidget {
  const _Forja({required this.estoque, required this.largo});

  final Map<int, int> estoque;
  final bool largo;

  @override
  Widget build(BuildContext context) {
    final f = maiorQueDa(estoque);
    if (f.nivel == null) {
      return const _Painel(
        child: Text(
          'Diga o que você tem, aí acima, para saber a maior runa que dá '
          'para forjar.',
          style: TextStyle(color: PWColors.textMuted, fontSize: 13),
        ),
      );
    }

    return _Painel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A MAIOR QUE DÁ PARA FORJAR',
            style: TextStyle(
              color: PWColors.accent,
              fontSize: 11,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _Parcela(
            parte: Parcela(nivel: f.nivel!, quantos: f.quantos),
            forte: true,
            largo: largo,
          ),
          // Nothing in the drawer can climb: a level 2 wants three level
          // ones. Saying "you can forge 2 runas nível 1" would dress up what
          // is already in the bag as an achievement.
          if (!f.daParaFundir) ...[
            const SizedBox(height: 10),
            const Text(
              'ainda não dá para fundir: uma runa nível 2 pede três nível 1.',
              style: TextStyle(color: PWColors.textMuted, fontSize: 12),
            ),
          ],
          if (f.parcelasDaSobra.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'e ainda sobra',
              style: TextStyle(color: PWColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 6,
              children: [
                for (var i = 0; i < f.parcelasDaSobra.length; i++) ...[
                  if (i > 0)
                    const Text(
                      '+',
                      style: TextStyle(color: PWColors.textMuted, fontSize: 15),
                    ),
                  _Parcela(
                    parte: f.parcelasDaSobra[i],
                    forte: false,
                    largo: largo,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Painel extends StatelessWidget {
  const _Painel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: PWColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: PWColors.border),
    ),
    child: child,
  );
}

class _Nota extends StatelessWidget {
  const _Nota();

  @override
  Widget build(BuildContext context) => const Text(
    'A conta é do caminho garantido: em cada fusão, a runa do centro mais '
    'combustível suficiente para 100%. As cores não importam — a runa do '
    'centro é a que sobe. Ainda não calculamos o risco de tentar abaixo de '
    '100%, porque falhar faz a runa do centro descer um nível.',
    style: TextStyle(color: PWColors.textMuted, fontSize: 12, height: 1.5),
  );
}
