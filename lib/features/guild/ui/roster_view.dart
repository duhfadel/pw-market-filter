import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/pw_colors.dart';
import '../../../core/theme/pw_theme.dart';
import '../../../core/widgets/game_icon.dart';
import '../../../market/ocupacoes.dart';
import '../data/jogadores_repository.dart';
import '../domain/jogador.dart';
import '../domain/papel.dart';
import 'roster_filtro.dart';
import 'roster_state.dart';
import 'roster_view_model.dart';
import 'widgets/jogador_form.dart';

/// The width below which the roster stops being a table and becomes a stack
/// of cards — the same breakpoint `TabelaDeInstancias` uses for the same
/// reason: a table with eight columns has nowhere to put most of them on a
/// phone.
const double _larguraTabela = 680;

/// The guild panel's roster: who is in the guild and what has been read off
/// their sheet print so far.
///
/// Image upload (the print itself) is deliberately not here — it is the next
/// piece, isolated on purpose because the web file-picker side of it is
/// fiddly and does not need to hold this list up.
class RosterView extends StatelessWidget {
  const RosterView({required this.papel, this.onSair, super.key});

  final Papel papel;

  /// When non-null, the AppBar grows a "Sair" action that calls it — the
  /// guild door's own job, not this screen's, so it stays null for the
  /// existing tests that mount `RosterView` on its own.
  final VoidCallback? onSair;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => RosterViewModel(getIt<JogadoresRepository>(), papel)..carregar(),
    child: _Tela(onSair: onSair),
  );
}

class _Tela extends StatelessWidget {
  const _Tela({this.onSair});

  final VoidCallback? onSair;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PWColors.surface,
      appBar: AppBar(
        backgroundColor: PWColors.surface,
        title: const Text(
          'Jogadores',
          style: TextStyle(fontFamily: PWTheme.display, color: PWColors.papel),
        ),
        actions: onSair == null
            ? null
            : [
                TextButton(
                  onPressed: onSair,
                  style: TextButton.styleFrom(foregroundColor: PWColors.textMuted),
                  child: const Text('Sair'),
                ),
              ],
      ),
      body: BlocBuilder<RosterViewModel, RosterState>(
        builder: (context, state) => switch (state) {
          RosterLoading() => const Center(
            child: CircularProgressIndicator(color: PWColors.accent),
          ),
          RosterFalha() => const Center(
            child: Text(
              'Não deu para carregar os jogadores.',
              style: TextStyle(color: PWColors.textMuted),
            ),
          ),
          RosterPronto() => _Pronto(state: state),
        },
      ),
    );
  }
}

class _Pronto extends StatelessWidget {
  const _Pronto({required this.state});

  final RosterPronto state;

  /// The classes actually present in this roster, in the game's own order
  /// (`classesDoJogo`), with anything that order does not know about — there
  /// should be none, but `classe` is free text typed by hand — tacked on
  /// alphabetically at the end. Deriving this from the loaded roster rather
  /// than from `ocupacaoDaClasse` as a whole means a chip never offers a
  /// class nobody in this guild plays.
  List<String> _classesPresentes() {
    final presentes = <String>{
      for (final j in state.jogadores)
        if (j.classe != null) j.classe!,
    };
    final conhecidas = [for (final c in classesDoJogo) if (presentes.contains(c)) c];
    final desconhecidas = presentes.difference(conhecidas.toSet()).toList()..sort();
    return [...conhecidas, ...desconhecidas];
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<RosterViewModel>();
    final podeEditar = state.papel.podeEditarJogadores;
    final visiveis = vm.jogadoresVisiveis;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (podeEditar)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FilledButton.icon(
                    onPressed: () => mostrarJogadorForm(context, vm),
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Adicionar jogador'),
                  ),
                ),
              if (state.jogadores.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Ainda não há jogador nenhum cadastrado.',
                    style: TextStyle(color: PWColors.textMuted),
                  ),
                )
              else ...[
                const _CampoBusca(),
                const SizedBox(height: 12),
                _ChipsDeClasse(classes: _classesPresentes()),
                const SizedBox(height: 8),
                const _ChipsDeStatus(),
                const SizedBox(height: 16),
                if (visiveis.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Nenhum jogador encontrado com esses filtros.',
                      style: TextStyle(color: PWColors.textMuted),
                    ),
                  )
                else
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) => c.maxWidth > _larguraTabela
                          ? _TabelaJogadores(jogadores: visiveis)
                          : _CartoesJogadores(jogadores: visiveis),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The free-text search box — `nome` only, case-insensitive substring.
///
/// A `StatefulWidget` of its own rather than a field inlined in `_Pronto`:
/// `_Pronto` is rebuilt by `BlocBuilder` on every keystroke (the view model
/// re-emits to make the rest of the screen follow the filter), and a
/// `TextField` built fresh from `initialValue` each time would forget
/// whatever the caret was doing — the exact trap `NumberField` exists to
/// avoid elsewhere in this app. Holding the controller in local `State`
/// survives those rebuilds because the element stays the same.
class _CampoBusca extends StatefulWidget {
  const _CampoBusca();

  @override
  State<_CampoBusca> createState() => _CampoBuscaState();
}

class _CampoBuscaState extends State<_CampoBusca> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    onChanged: (v) => context.read<RosterViewModel>().setBusca(v),
    style: const TextStyle(color: PWColors.papel),
    decoration: const InputDecoration(
      hintText: 'Buscar por nome…',
      prefixIcon: Icon(Icons.search, color: PWColors.apagado),
    ),
  );
}

class _ChipsDeClasse extends StatelessWidget {
  const _ChipsDeClasse({required this.classes});

  final List<String> classes;

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) return const SizedBox.shrink();
    final vm = context.read<RosterViewModel>();
    final atual = vm.filtro.classe;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final classe in classes)
          FilterChip(
            label: Text(classe),
            avatar: ocupacaoDaClasse.containsKey(classe)
                ? ClassIcon(ocupacaoDaClasse[classe]!, size: 18)
                : null,
            selected: atual == classe,
            onSelected: (selecionado) => vm.setClasse(selecionado ? classe : null),
            selectedColor: PWColors.violeta,
            backgroundColor: PWColors.elevado,
            labelStyle: TextStyle(color: atual == classe ? PWColors.papel : PWColors.textMuted),
          ),
      ],
    );
  }
}

/// The three statuses a player can be in. Fixed, unlike the class chips —
/// every roster has the same three regardless of who is on it.
const _statusOrdenados = ['pendente', 'transcrito', 'revisar'];

class _ChipsDeStatus extends StatelessWidget {
  const _ChipsDeStatus();

  @override
  Widget build(BuildContext context) {
    final vm = context.read<RosterViewModel>();
    final atual = vm.filtro.status;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final status in _statusOrdenados)
          FilterChip(
            label: Text(_rotuloStatus(status)),
            selected: atual == status,
            onSelected: (selecionado) => vm.setStatus(selecionado ? status : null),
            selectedColor: _corStatus(status),
            backgroundColor: PWColors.elevado,
            labelStyle: TextStyle(color: atual == status ? PWColors.noite : PWColors.textMuted),
          ),
      ],
    );
  }
}

String _rotuloStatus(String status) => switch (status) {
  'transcrito' => 'Transcrito',
  'pendente' => 'Pendente',
  'revisar' => 'Revisar',
  _ => status,
};

Color _corStatus(String status) => switch (status) {
  'transcrito' => PWColors.ok,
  'revisar' => PWColors.danger,
  _ => PWColors.apagado,
};

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final cor = _corStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cor),
      ),
      child: Text(
        _rotuloStatus(status),
        style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// "Atualizado há N dias" from `atualizadoEm` — the date only. **Not** who
/// touched it: this iteration cannot resolve another staff member's uid to a
/// name, and a wrong or missing name would be worse than no byline at all.
String? _rotuloAtualizado(DateTime? data) {
  if (data == null) return null;
  final dias = DateTime.now().difference(data).inDays;
  if (dias <= 0) return 'atualizado hoje';
  if (dias == 1) return 'atualizado há 1 dia';
  return 'atualizado há $dias dias';
}

/// The column widths for the wide table — one place, so the header and every
/// row line up, and so the scroll wrap below knows exactly how wide the
/// whole thing is.
///
/// `Jogador` is fixed too, unlike the first version of this table: a
/// `Row` inside a horizontally-scrolling `SingleChildScrollView` gets an
/// unbounded width, and `Expanded` asserts on an unbounded constraint —
/// every column has to carry its own number once the table can scroll.
const double _colJogador = 220;
const double _colLimite = 90;
const double _colNivelAtaque = 130;
const double _colHp = 100;
const double _colNivelDefesa = 100;
const double _colCritico = 90;
const double _colStatus = 110;
const double _colAtualizado = 140;

/// The table's own width — the same 980 the page already caps its content
/// at (`_Pronto`'s `ConstrainedBox`), so on anything at or above that the
/// table fills the space exactly and the scrollbar never shows. Below it,
/// and in particular in the 681–760px band where the fixed columns alone
/// (760px) already outrun the 680px breakpoint that chose this layout, it
/// scrolls instead of overflowing — the same fix `TabelaDeInstancias`
/// already uses for its own fixed-width columns.
const double _larguraFixaTabela =
    _colJogador +
    _colLimite +
    _colNivelAtaque +
    _colHp +
    _colNivelDefesa +
    _colCritico +
    _colStatus +
    _colAtualizado;

class _TabelaJogadores extends StatelessWidget {
  const _TabelaJogadores({required this.jogadores});

  final List<Jogador> jogadores;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SizedBox(
      width: _larguraFixaTabela,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CabecalhoTabela(),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: jogadores.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => _LinhaJogador(jogadores[i]),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CabecalhoTabela extends StatelessWidget {
  const _CabecalhoTabela();

  @override
  Widget build(BuildContext context) {
    final vm = context.read<RosterViewModel>();
    final ordem = vm.filtro.ordem;

    void alternar(OrdemColuna coluna) => vm.setOrdem(ordem == coluna ? null : coluna);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: _colJogador, child: _TextoCabecalho('Jogador')),
          const SizedBox(width: _colLimite, child: _TextoCabecalho('Limite')),
          SizedBox(
            width: _colNivelAtaque,
            child: _CabecalhoOrdenavel(
              'Nível de Ataque',
              ativo: ordem == OrdemColuna.nivelAtaque,
              onTap: () => alternar(OrdemColuna.nivelAtaque),
            ),
          ),
          SizedBox(
            width: _colHp,
            child: _CabecalhoOrdenavel(
              'HP',
              ativo: ordem == OrdemColuna.hp,
              onTap: () => alternar(OrdemColuna.hp),
            ),
          ),
          SizedBox(
            width: _colNivelDefesa,
            child: _CabecalhoOrdenavel(
              'Nv. Defesa',
              ativo: ordem == OrdemColuna.nivelDefesa,
              onTap: () => alternar(OrdemColuna.nivelDefesa),
            ),
          ),
          SizedBox(
            width: _colCritico,
            child: _CabecalhoOrdenavel(
              'Crítico',
              ativo: ordem == OrdemColuna.critico,
              onTap: () => alternar(OrdemColuna.critico),
            ),
          ),
          const SizedBox(width: _colStatus, child: _TextoCabecalho('Status')),
          const SizedBox(width: _colAtualizado, child: _TextoCabecalho('Atualizado')),
        ],
      ),
    );
  }
}

class _TextoCabecalho extends StatelessWidget {
  const _TextoCabecalho(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Text(
    texto,
    style: const TextStyle(color: PWColors.apagado, fontSize: 12, fontWeight: FontWeight.w600),
  );
}

/// A column header that sorts the table when tapped — always descending; a
/// second tap on the same column clears the sort rather than reversing it,
/// since there is no ascending direction to reverse into (see
/// `RosterFiltro`).
class _CabecalhoOrdenavel extends StatelessWidget {
  const _CabecalhoOrdenavel(this.texto, {required this.ativo, required this.onTap});

  final String texto;
  final bool ativo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          texto,
          style: TextStyle(
            color: ativo ? PWColors.papel : PWColors.apagado,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (ativo)
          const Padding(
            padding: EdgeInsets.only(left: 2),
            child: Icon(Icons.arrow_downward, size: 12, color: PWColors.accent),
          ),
      ],
    ),
  );
}

class _LinhaJogador extends StatelessWidget {
  const _LinhaJogador(this.jogador);

  final Jogador jogador;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(width: _colJogador, child: _IdentidadeJogador(jogador)),
            SizedBox(width: _colLimite, child: _CelulaTexto(jogador.limite)),
            SizedBox(width: _colNivelAtaque, child: _CelulaNumero(jogador.nivelAtaque)),
            SizedBox(width: _colHp, child: _CelulaNumero(jogador.hp)),
            SizedBox(width: _colNivelDefesa, child: _CelulaNumero(jogador.nivelDefesa)),
            SizedBox(width: _colCritico, child: _CelulaTexto(jogador.critico)),
            SizedBox(width: _colStatus, child: _StatusChip(jogador.status)),
            SizedBox(width: _colAtualizado, child: _CelulaAtualizado(jogador.atualizadoEm)),
          ],
        ),
        if (jogador.aRevisar && jogador.nota != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: _NotaRevisao(jogador.nota!),
          ),
      ],
    ),
  );
}

class _IdentidadeJogador extends StatelessWidget {
  const _IdentidadeJogador(this.jogador);

  final Jogador jogador;

  @override
  Widget build(BuildContext context) {
    final ocupacao = jogador.classe == null ? null : ocupacaoDaClasse[jogador.classe];
    return Row(
      children: [
        if (ocupacao != null) ...[ClassIcon(ocupacao, size: 28), const SizedBox(width: 8)],
        Expanded(
          child: Text(
            jogador.nome,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: PWColors.papel, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _CelulaTexto extends StatelessWidget {
  const _CelulaTexto(this.texto);

  final String? texto;

  @override
  Widget build(BuildContext context) => Text(
    texto ?? '—',
    style: TextStyle(color: texto == null ? PWColors.apagado : PWColors.papel, fontSize: 13),
  );
}

class _CelulaNumero extends StatelessWidget {
  const _CelulaNumero(this.valor);

  final int? valor;

  @override
  Widget build(BuildContext context) => Text(
    valor?.toString() ?? '—',
    style: TextStyle(color: valor == null ? PWColors.apagado : PWColors.papel, fontSize: 13),
  );
}

class _CelulaAtualizado extends StatelessWidget {
  const _CelulaAtualizado(this.data);

  final DateTime? data;

  @override
  Widget build(BuildContext context) {
    final rotulo = _rotuloAtualizado(data);
    return Text(rotulo ?? '—', style: const TextStyle(color: PWColors.apagado, fontSize: 12));
  }
}

class _NotaRevisao extends StatelessWidget {
  const _NotaRevisao(this.nota);

  final String nota;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.flag_outlined, size: 14, color: PWColors.danger),
      const SizedBox(width: 6),
      Expanded(child: Text(nota, style: const TextStyle(color: PWColors.danger, fontSize: 12))),
    ],
  );
}

/// The narrow layout — one card per player, the same information the table
/// carries but stacked instead of columned, with the attack level given the
/// prominence its own label (never the abbreviation "NA") earns it.
class _CartoesJogadores extends StatelessWidget {
  const _CartoesJogadores({required this.jogadores});

  final List<Jogador> jogadores;

  @override
  Widget build(BuildContext context) => ListView.separated(
    itemCount: jogadores.length,
    separatorBuilder: (_, _) => const SizedBox(height: 10),
    itemBuilder: (_, i) => _CartaoJogador(jogadores[i]),
  );
}

class _CartaoJogador extends StatelessWidget {
  const _CartaoJogador(this.jogador);

  final Jogador jogador;

  @override
  Widget build(BuildContext context) {
    final ocupacao = jogador.classe == null ? null : ocupacaoDaClasse[jogador.classe];
    final rotuloAtualizado = _rotuloAtualizado(jogador.atualizadoEm);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PWColors.elevado,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PWColors.filete),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (ocupacao != null) ...[ClassIcon(ocupacao, size: 32), const SizedBox(width: 10)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jogador.nome,
                      style: const TextStyle(
                        color: PWColors.papel,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (jogador.classe != null || jogador.limite != null)
                      Text(
                        [
                          if (jogador.classe != null) jogador.classe!,
                          if (jogador.limite != null) jogador.limite!,
                        ].join(' · '),
                        style: const TextStyle(color: PWColors.textMuted, fontSize: 12),
                      ),
                  ],
                ),
              ),
              _StatusChip(jogador.status),
            ],
          ),
          const SizedBox(height: 10),
          if (jogador.nivelAtaque != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: PWColors.noite,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Text(
                    'Nível de Ataque',
                    style: TextStyle(color: PWColors.textMuted, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    '${jogador.nivelAtaque}',
                    style: const TextStyle(
                      color: PWColors.accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _FichaSecundaria('HP', jogador.hp?.toString()),
              _FichaSecundaria('Nv. Defesa', jogador.nivelDefesa?.toString()),
              _FichaSecundaria('Crítico', jogador.critico),
              if (rotuloAtualizado != null)
                Text(rotuloAtualizado, style: const TextStyle(color: PWColors.apagado, fontSize: 11)),
            ],
          ),
          if (jogador.aRevisar && jogador.nota != null)
            Padding(padding: const EdgeInsets.only(top: 8), child: _NotaRevisao(jogador.nota!)),
        ],
      ),
    );
  }
}

/// A `rótulo: valor` pair on a card's secondary row — skipped entirely when
/// the value has not been read, same rule as everywhere else on this screen.
class _FichaSecundaria extends StatelessWidget {
  const _FichaSecundaria(this.rotulo, this.valor);

  final String rotulo;
  final String? valor;

  @override
  Widget build(BuildContext context) {
    if (valor == null) return const SizedBox.shrink();
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$rotulo ', style: const TextStyle(color: PWColors.apagado)),
          TextSpan(text: valor, style: const TextStyle(color: PWColors.papel)),
        ],
      ),
      style: const TextStyle(fontSize: 12),
    );
  }
}

void mostrarJogadorForm(BuildContext context, RosterViewModel vm) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => JogadorForm(vm: vm),
  );
}
