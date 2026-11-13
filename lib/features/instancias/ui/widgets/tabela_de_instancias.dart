import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/widgets/game_icon.dart';
import '../../../../market/ocupacoes.dart';
import '../../domain/campo_personalizado.dart';
import '../../domain/entrada_de_instancia.dart';
import '../../domain/grupo_de_instancias.dart';
import '../../domain/personagem_de_instancia.dart';
import '../../domain/plano_de_instancias.dart';
import 'campos_do_personagem.dart';

/// A largura de uma coluna de número — o par `−`/`+` mais o campo. Uma só
/// medida, para o cabeçalho, as linhas e as somas não poderem desalinhar-se.
const _colunaDeNumero = 128.0;
const _colunaEstreita = 64.0;

/// A coluna do botão de tirar. Uma medida só, pela mesma razão.
double _colunaDoBotao(bool compacto) => compacto ? 34 : 40;
double _coluna(bool compacto) => compacto ? _colunaEstreita : _colunaDeNumero;

/// A largura da coluna de identidade (pega, ícone de classe, nome) quando a
/// tabela larga passa a rolar na horizontal — ver `TabelaDeInstancias`. Em
/// modo normal (sem campos-coluna) o nome continua a ser `Expanded` e esta
/// medida não se usa.
const _larguraNome = 210.0;

/// A largura de uma coluna de campo personalizado. A marcação é estreita (um
/// visto); a escolha precisa de caber a opção.
double _larguraCampoColuna(CampoPersonalizado c) =>
    c.tipo == CampoTipo.marcacao ? 86 : 128;

/// Os campos que viram coluna na tabela larga — marcação e escolha. A nota
/// não: texto é comprido demais para uma coluna, e fica numa linha própria
/// por baixo do personagem.
List<CampoPersonalizado> _camposColuna(List<CampoPersonalizado> campos) => [
  for (final c in campos)
    if (c.tipo != CampoTipo.nota) c,
];

/// O que o arrastar carrega: a morada de origem de um personagem.
typedef _Arrasto = Morada;

/// O cabeçalho de uma coluna de campo personalizado: o nome, cortado para
/// caber, com o nome inteiro na dica.
class _CabecaColunaCampo extends StatelessWidget {
  const _CabecaColunaCampo({required this.campo});

  final CampoPersonalizado campo;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: campo.nome,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            campo.tipo == CampoTipo.marcacao
                ? Icons.check_box_outlined
                : Icons.radio_button_checked,
            size: 18,
            color: PWColors.textMuted,
          ),
          const SizedBox(height: 3),
          Text(
            campo.nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              color: PWColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

/// A célula de um campo-coluna numa linha: o visto da marcação, ou a opção da
/// escolha, centrados na largura da coluna.
class _CelulaColunaCampo extends StatelessWidget {
  const _CelulaColunaCampo({
    required this.campo,
    required this.quem,
    required this.onde,
    required this.aoDefinir,
  });

  final CampoPersonalizado campo;
  final PersonagemDeInstancia quem;
  final Morada onde;
  final void Function(Morada, String, String?) aoDefinir;

  @override
  Widget build(BuildContext context) {
    if (campo.tipo == CampoTipo.marcacao) {
      final ligado = quem.marcado(campo.id);
      return Center(
        child: Tooltip(
          message: '${campo.nome} — ${quem.nome}',
          child: InkWell(
            onTap: () => aoDefinir(onde, campo.id, ligado ? null : '1'),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                ligado ? Icons.check_box : Icons.check_box_outline_blank,
                size: 22,
                color: ligado ? PWColors.accent : PWColors.textMuted,
              ),
            ),
          ),
        ),
      );
    }

    // Escolha: a opção atual, e um menu para a trocar.
    final valor = quem.extra(campo.id);
    final escolhido = valor != null && campo.opcoes.contains(valor);
    final mostra = escolhido ? valor : '—';
    return Center(
      child: PopupMenuButton<String>(
        tooltip: campo.nome,
        onSelected: (v) => aoDefinir(onde, campo.id, v.isEmpty ? null : v),
        itemBuilder: (_) => [
          for (final o in campo.opcoes) PopupMenuItem(value: o, child: Text(o)),
          const PopupMenuDivider(),
          const PopupMenuItem(value: '', child: Text('— limpar —')),
        ],
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: escolhido ? PWColors.accent : PWColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  mostra,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: escolhido ? PWColors.accent : PWColors.textMuted,
                    fontWeight: escolhido ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: PWColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tabela inteira — um grupo de cada vez, com subtotais, e um total geral
/// no fim.
class TabelaDeInstancias extends StatelessWidget {
  const TabelaDeInstancias({
    required this.plano,
    required this.compacto,
    required this.aoOrdenar,
    required this.aoSomar,
    required this.aoContar,
    required this.aoRenomear,
    required this.aoRemover,
    required this.aoMover,
    required this.aoRenomearGrupo,
    required this.aoRemoverGrupo,
    required this.aoAdicionarNoGrupo,
    required this.hoje,
    required this.aoPegarDiaria,
    required this.aoPegarGrupo,
    required this.aoFinalizarDungeon,
    required this.aoDefinirExtra,
    super.key,
  });

  final PlanoDeInstancias plano;
  final bool compacto;
  final void Function(EntradaDeInstancia) aoOrdenar;
  final void Function(Morada, EntradaDeInstancia, int delta) aoSomar;
  final void Function(Morada, EntradaDeInstancia, int valor) aoContar;
  final void Function(Morada, String nome) aoRenomear;
  final void Function(Morada) aoRemover;

  /// Um personagem chegou a um grupo por arrasto. `de` é a morada de origem,
  /// `paraGrupo` o destino.
  final void Function(Morada de, int paraGrupo) aoMover;
  final void Function(int grupo, String nome) aoRenomearGrupo;
  final void Function(int grupo) aoRemoverGrupo;
  final void Function(int grupo) aoAdicionarNoGrupo;

  /// O dia de hoje no fuso do Brasil, `AAAA-MM-DD`. Vem de fora, calculado
  /// uma vez, para a tabela toda concordar sobre que dia é.
  final String hoje;

  /// Pegar as três entradas de hoje de um personagem, e do grupo inteiro.
  final void Function(Morada) aoPegarDiaria;
  final void Function(int grupo) aoPegarGrupo;

  /// Finalizar uma dungeon no grupo que gasta [entrada]: todos −1 nela, +6
  /// chaves.
  final void Function(int grupo, EntradaDeInstancia entrada) aoFinalizarDungeon;

  /// Definir (ou limpar) o valor de um campo personalizado num personagem.
  final void Function(Morada, String campoId, String? valor) aoDefinirExtra;

  @override
  Widget build(BuildContext context) {
    // As marcações e escolhas viram colunas no largo; a nota fica numa linha
    // por baixo do personagem. Quando há colunas destas, a tabela passa a ter
    // largura fixa e rola na horizontal — um nome `Expanded` não cabe num
    // `SingleChildScrollView`, que dá largura infinita.
    final colunas = compacto
        ? const <CampoPersonalizado>[]
        : _camposColuna(plano.campos);
    final nomeFixo = colunas.isNotEmpty;

    final tabela = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // No estreito não há cabeçalho de colunas: cada cartão leva o ícone do
        // item ao lado do número, portanto uma fila de ícones no topo seria
        // uma legenda para uma tabela que ali não existe.
        if (!compacto) ...[
          _Cabecalho(
            plano: plano,
            compacto: compacto,
            aoOrdenar: aoOrdenar,
            colunas: colunas,
            nomeFixo: nomeFixo,
          ),
          const Divider(height: 1),
        ] else
          _OrdenarEstreito(plano: plano, aoOrdenar: aoOrdenar),
        for (var gi = 0; gi < plano.grupos.length; gi++)
          _Grupo(
            plano: plano,
            grupo: gi,
            compacto: compacto,
            // Um grupo só se apaga quando há mais de um: o último não pode
            // sumir, porque o primeiro personagem precisa sempre de uma casa.
            podeApagar: plano.grupos.length > 1,
            aoSomar: aoSomar,
            aoContar: aoContar,
            aoRenomear: aoRenomear,
            aoRemover: aoRemover,
            aoMover: aoMover,
            aoRenomearGrupo: aoRenomearGrupo,
            aoRemoverGrupo: aoRemoverGrupo,
            aoAdicionarNoGrupo: aoAdicionarNoGrupo,
            hoje: hoje,
            aoPegarDiaria: aoPegarDiaria,
            aoPegarGrupo: aoPegarGrupo,
            aoFinalizarDungeon: aoFinalizarDungeon,
            campos: plano.campos,
            colunas: colunas,
            nomeFixo: nomeFixo,
            aoDefinirExtra: aoDefinirExtra,
          ),
        const SizedBox(height: 6),
        if (compacto)
          _TotalGeralEstreito(plano: plano)
        else
          _TotalGeral(
            plano: plano,
            compacto: compacto,
            colunas: colunas,
            nomeFixo: nomeFixo,
          ),
      ],
    );

    if (!nomeFixo) return tabela;

    // A largura total da tabela com as colunas de campo, para o scroll
    // horizontal saber até onde vai.
    final largura =
        _larguraNome +
        EntradaDeInstancia.values.length * _colunaDeNumero +
        colunas.fold(0.0, (s, c) => s + _larguraCampoColuna(c)) +
        _colunaDoBotao(false) * 2 +
        // Uma folga, para nenhuma linha interna transbordar por um pixel de
        // arredondamento da pega ou de uma borda. Invisível no scroll.
        8;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(width: largura, child: tabela),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({
    required this.plano,
    required this.compacto,
    required this.aoOrdenar,
    this.colunas = const [],
    this.nomeFixo = false,
  });

  final PlanoDeInstancias plano;
  final bool compacto;
  final void Function(EntradaDeInstancia) aoOrdenar;
  final List<CampoPersonalizado> colunas;
  final bool nomeFixo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        if (nomeFixo)
          const SizedBox(width: _larguraNome)
        else
          const Expanded(child: SizedBox()),
        for (final entrada in EntradaDeInstancia.values)
          SizedBox(
            width: _coluna(compacto),
            child: _BotaoDeColuna(
              entrada: entrada,
              ordenada:
                  plano.ordem is OrdemPorEntrada &&
                  (plano.ordem as OrdemPorEntrada).entrada == entrada,
              compacto: compacto,
              aoTocar: () => aoOrdenar(entrada),
            ),
          ),
        for (final c in colunas)
          SizedBox(
            width: _larguraCampoColuna(c),
            child: _CabecaColunaCampo(campo: c),
          ),
        SizedBox(width: _colunaDoBotao(compacto) * 2),
      ],
    ),
  );
}

/// O cabeçalho de uma coluna: o ícone do item e um toque que ordena.
class _BotaoDeColuna extends StatelessWidget {
  const _BotaoDeColuna({
    required this.entrada,
    required this.ordenada,
    required this.compacto,
    required this.aoTocar,
  });

  final EntradaDeInstancia entrada;
  final bool ordenada;
  final bool compacto;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: ordenada
        ? '${entrada.nome}\nordenado por esta coluna — toque para desfazer'
        : '${entrada.nome}\ntoque para ordenar',
    child: InkWell(
      onTap: aoTocar,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ItemIcon(entrada.itemId, size: compacto ? 22 : 26),
            const SizedBox(height: 3),
            Text(
              entrada.curto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compacto ? 9.5 : 10.5,
                // A chave é a coluna herói: o rótulo dela em dourado mesmo
                // quando não é a coluna que ordena, para a cabeça da coluna
                // combinar com os números dourados por baixo.
                color: ordenada || entrada == EntradaDeInstancia.chave
                    ? PWColors.accent
                    : PWColors.textMuted,
                fontWeight: entrada == EntradaDeInstancia.chave || ordenada
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Um grupo: o cabeçalho com o nome, as linhas, e o subtotal.
///
/// **É o alvo do arrasto.** O grupo inteiro é um `DragTarget`: largar um
/// personagem em qualquer ponto dele move-o para cá. Larga-se no grupo e não
/// numa linha porque o destino que interessa é a gaveta — a ordem dentro dela
/// ajeita-se depois, e pedir pontaria numa linha de 44 px tornaria o gesto
/// uma frustração no telemóvel.
class _Grupo extends StatelessWidget {
  const _Grupo({
    required this.plano,
    required this.grupo,
    required this.compacto,
    required this.podeApagar,
    required this.aoSomar,
    required this.aoContar,
    required this.aoRenomear,
    required this.aoRemover,
    required this.aoMover,
    required this.aoRenomearGrupo,
    required this.aoRemoverGrupo,
    required this.aoAdicionarNoGrupo,
    required this.hoje,
    required this.aoPegarDiaria,
    required this.aoPegarGrupo,
    required this.aoFinalizarDungeon,
    required this.campos,
    required this.colunas,
    required this.nomeFixo,
    required this.aoDefinirExtra,
  });

  final PlanoDeInstancias plano;
  final int grupo;
  final bool compacto;
  final bool podeApagar;
  final void Function(Morada, EntradaDeInstancia, int) aoSomar;
  final void Function(Morada, EntradaDeInstancia, int) aoContar;
  final void Function(Morada, String) aoRenomear;
  final void Function(Morada) aoRemover;
  final void Function(Morada, int) aoMover;
  final void Function(int, String) aoRenomearGrupo;
  final void Function(int) aoRemoverGrupo;
  final void Function(int) aoAdicionarNoGrupo;
  final String hoje;
  final void Function(Morada) aoPegarDiaria;
  final void Function(int) aoPegarGrupo;
  final void Function(int, EntradaDeInstancia) aoFinalizarDungeon;
  final List<CampoPersonalizado> campos;
  final List<CampoPersonalizado> colunas;
  final bool nomeFixo;
  final void Function(Morada, String, String?) aoDefinirExtra;

  @override
  Widget build(BuildContext context) {
    final g = plano.grupos[grupo];
    final ordenados = plano.emOrdem(grupo);

    return DragTarget<_Arrasto>(
      // Nunca aceita um arrasto que já é deste grupo: mover para dentro de
      // casa não é mover, e aceitá-lo faria piscar o realce sem efeito.
      onWillAcceptWithDetails: (d) => d.data.grupo != grupo,
      onAcceptWithDetails: (d) => aoMover(d.data, grupo),
      builder: (context, candidatos, _) {
        final recebendo = candidatos.isNotEmpty;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            // O realce ao receber um arrasto: diz *solta aqui* sem palavra
            // nenhuma, e some quando o dedo sai.
            color: recebendo ? PWColors.surfaceRaised : null,
            border: Border.all(
              color: recebendo ? PWColors.accent : PWColors.border,
              width: recebendo ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CabecaDoGrupo(
                nome: g.nome,
                quantos: g.personagens.length,
                podeApagar: podeApagar,
                aoRenomear: (nome) => aoRenomearGrupo(grupo, nome),
                aoRemover: () => aoRemoverGrupo(grupo),
                aoAdicionar: () => aoAdicionarNoGrupo(grupo),
              ),
              // A barra da coleta do grupo, logo abaixo do cabeçalho e só
              // quando há alguém para pegar. É a cara da funcionalidade nova,
              // por isso tem barra própria em vez de ser mais um ícone no
              // cabeçalho já cheio.
              if (g.personagens.isNotEmpty) ...[
                _BarraDaDiaria(
                  faltam: g.faltamHoje(hoje),
                  todosPegaram: g.todosPegaramHoje(hoje),
                  aoPegar: () => aoPegarGrupo(grupo),
                ),
                _BarraDaDungeon(
                  grupo: g,
                  aoFinalizar: (e) => aoFinalizarDungeon(grupo, e),
                ),
              ],
              if (g.personagens.isEmpty)
                _GrupoVazio(compacto: compacto)
              else
                for (final quem in ordenados) ...[
                  const Divider(height: 1),
                  if (compacto)
                    _Cartao(
                      quem: quem,
                      onde: Morada(grupo, g.personagens.indexOf(quem)),
                      pegouHoje: quem.pegouEm(hoje),
                      aoSomar: aoSomar,
                      aoContar: aoContar,
                      aoRenomear: aoRenomear,
                      aoRemover: aoRemover,
                      aoPegarDiaria: aoPegarDiaria,
                      campos: campos,
                      aoDefinirExtra: aoDefinirExtra,
                    )
                  else
                    _Linha(
                      quem: quem,
                      // A morada de origem, achada por identidade: dois
                      // personagens podem ter o mesmo nome e a mesma classe, e
                      // procurar por nome escreveria no errado.
                      onde: Morada(grupo, g.personagens.indexOf(quem)),
                      compacto: compacto,
                      pegouHoje: quem.pegouEm(hoje),
                      aoSomar: aoSomar,
                      aoContar: aoContar,
                      aoRenomear: aoRenomear,
                      aoRemover: aoRemover,
                      aoPegarDiaria: aoPegarDiaria,
                      campos: campos,
                      colunas: colunas,
                      nomeFixo: nomeFixo,
                      aoDefinirExtra: aoDefinirExtra,
                    ),
                ],
              const Divider(height: 1),
              if (compacto)
                _SubtotalEstreito(grupo: g)
              else
                _Subtotal(
                  grupo: g,
                  compacto: compacto,
                  colunas: colunas,
                  nomeFixo: nomeFixo,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CabecaDoGrupo extends StatelessWidget {
  const _CabecaDoGrupo({
    required this.nome,
    required this.quantos,
    required this.podeApagar,
    required this.aoRenomear,
    required this.aoRemover,
    required this.aoAdicionar,
  });

  final String nome;
  final int quantos;
  final bool podeApagar;
  final void Function(String) aoRenomear;
  final VoidCallback aoRemover;
  final VoidCallback aoAdicionar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
    child: Row(
      children: [
        const Icon(Icons.folder_outlined, size: 17, color: PWColors.accent),
        const SizedBox(width: 8),
        Expanded(
          child: _NomeDoGrupo(nome: nome, aoRenomear: aoRenomear),
        ),
        TextButton.icon(
          onPressed: aoAdicionar,
          icon: const Icon(Icons.add, size: 15),
          label: const Text('Personagem'),
          style: TextButton.styleFrom(
            foregroundColor: PWColors.textMuted,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
          ),
        ),
        // O último grupo não pode sumir — ver `_Grupo.podeApagar`.
        if (podeApagar)
          IconButton(
            onPressed: aoRemover,
            iconSize: 17,
            visualDensity: VisualDensity.compact,
            tooltip: 'Apagar o grupo "$nome" e os personagens dele',
            icon: const Icon(Icons.delete_outline, color: PWColors.textMuted),
          ),
      ],
    ),
  );
}

/// O nome do grupo, editável no sítio.
class _NomeDoGrupo extends StatefulWidget {
  const _NomeDoGrupo({required this.nome, required this.aoRenomear});
  final String nome;
  final void Function(String) aoRenomear;
  @override
  State<_NomeDoGrupo> createState() => _NomeDoGrupoState();
}

class _NomeDoGrupoState extends State<_NomeDoGrupo> {
  late final TextEditingController _c = TextEditingController(
    text: widget.nome,
  );
  @override
  void didUpdateWidget(_NomeDoGrupo a) {
    super.didUpdateWidget(a);
    if (widget.nome != _c.text) _c.text = widget.nome;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _c,
    onSubmitted: widget.aoRenomear,
    onTapOutside: (_) => widget.aoRenomear(_c.text),
    style: const TextStyle(
      color: PWColors.text,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
    decoration: const InputDecoration(
      isDense: true,
      filled: false,
      contentPadding: EdgeInsets.symmetric(vertical: 4),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
    ),
  );
}

/// A barra que pega as entradas de hoje para o grupo inteiro.
///
/// **Diz em que estado está, não só o que faz.** Enquanto falta alguém, é um
/// botão de acento que conta quantos — *pegar entradas de hoje (3)*. Quando
/// todos já pegaram, vira um recado calado com um visto, *todos já pegaram
/// hoje*, e deixa de ser tocável: a coleta é uma por dia, e um botão que não
/// faz nada ensina a desconfiar dos que fazem.
class _BarraDaDiaria extends StatelessWidget {
  const _BarraDaDiaria({
    required this.faltam,
    required this.todosPegaram,
    required this.aoPegar,
  });

  final int faltam;
  final bool todosPegaram;
  final VoidCallback aoPegar;

  @override
  Widget build(BuildContext context) {
    if (todosPegaram) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.event_available, size: 15, color: PWColors.ok),
            SizedBox(width: 7),
            Text(
              'Todos já pegaram as entradas hoje',
              style: TextStyle(
                color: PWColors.ok,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 12, 8),
      child: Align(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: aoPegar,
            borderRadius: BorderRadius.circular(9),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: PWColors.accent.withValues(alpha: 0.12),
                border: Border.all(color: PWColors.accent),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.redeem, size: 16, color: PWColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    // Conta quantos ainda faltam: ao somar só por quem não
                    // pegou, o botão promete o que vai mesmo fazer.
                    faltam == 1
                        ? 'Pegar entradas de hoje (1)'
                        : 'Pegar entradas de hoje ($faltam)',
                    style: const TextStyle(
                      color: PWColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// O botão da coleta diária de um personagem, ao lado do de tirar.
///
/// **Existe por personagem e não só por grupo** porque, nas palavras do dono,
/// *de repente eu posso pegar em um e não no outro*. Depois de pegar hoje vira
/// um visto verde apagado, com a dica *já pegou as entradas hoje* — a coleta é
/// uma por dia, e o estado tem de dizer-se, não só o botão.
class _BotaoDaDiaria extends StatelessWidget {
  const _BotaoDaDiaria({
    required this.nome,
    required this.pegouHoje,
    required this.aoPegar,
  });

  final String nome;
  final bool pegouHoje;
  final VoidCallback aoPegar;

  @override
  Widget build(BuildContext context) {
    if (pegouHoje) {
      return Tooltip(
        message: '$nome já pegou as entradas hoje',
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            // Verde-apagado, sem borda: diz *feito*, e não convida a tocar.
            color: PWColors.ok.withValues(alpha: 0.12),
          ),
          child: const Icon(
            Icons.event_available,
            size: 16,
            color: PWColors.ok,
          ),
        ),
      );
    }
    return Tooltip(
      message: 'Pegar as 3 entradas de hoje de $nome (+1 em cada)',
      child: InkWell(
        onTap: aoPegar,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: PWColors.accent),
          ),
          child: const Icon(Icons.redeem, size: 16, color: PWColors.accent),
        ),
      ),
    );
  }
}

/// A barra de finalizar uma dungeon: um botão por entrada, para o grupo todo.
///
/// **Um botão por entrada, porque cada dungeon gasta uma relíquia de um tipo
/// — decisão do dono a 13/11/2026.** Carregar num deles tira uma daquela
/// entrada e dá +6 chaves a cada personagem do grupo que a tenha; quem está a
/// zero daquela não pode fazer a dungeon e fica de fora. O botão conta quantos
/// podem, e apaga-se quando ninguém pode — um botão que não faz nada ensina a
/// desconfiar dos que fazem, a mesma regra da coleta diária.
class _BarraDaDungeon extends StatelessWidget {
  const _BarraDaDungeon({required this.grupo, required this.aoFinalizar});

  final GrupoDeInstancias grupo;
  final void Function(EntradaDeInstancia) aoFinalizar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 0, 12, 10),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Finalizar dungeon:',
          style: TextStyle(
            color: PWColors.textMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        for (final e in EntradaDeInstancia.entradas)
          _BotaoDeDungeon(
            entrada: e,
            podem: grupo.podemDungeon(e),
            aoFinalizar: () => aoFinalizar(e),
          ),
      ],
    ),
  );
}

class _BotaoDeDungeon extends StatelessWidget {
  const _BotaoDeDungeon({
    required this.entrada,
    required this.podem,
    required this.aoFinalizar,
  });

  final EntradaDeInstancia entrada;

  /// Quantos do grupo têm esta entrada — quem a dungeon vai afectar.
  final int podem;
  final VoidCallback aoFinalizar;

  @override
  Widget build(BuildContext context) {
    final ligado = podem > 0;
    return Tooltip(
      message: ligado
          ? 'Finalizar dungeon de ${entrada.curto}: −1 ${entrada.curto} e +6 '
                'chaves para os $podem do grupo que a têm'
          : 'Ninguém no grupo tem ${entrada.curto} para gastar',
      child: InkWell(
        onTap: ligado ? aoFinalizar : null,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: ligado ? PWColors.border : PWColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: ligado ? 1 : 0.4,
                child: ItemIcon(entrada.itemId, size: 18),
              ),
              const SizedBox(width: 6),
              Text(
                entrada.curto,
                style: TextStyle(
                  color: ligado ? PWColors.text : PWColors.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '−1',
                style: TextStyle(
                  color: ligado ? PWColors.danger : PWColors.border,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '+6',
                style: TextStyle(
                  color: ligado ? PWColors.accent : PWColors.border,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.vpn_key,
                size: 12,
                color: ligado ? PWColors.accent : PWColors.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrupoVazio extends StatelessWidget {
  const _GrupoVazio({required this.compacto});
  final bool compacto;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    child: Text(
      'Sem personagens. Toque em Personagem, ou arraste um de outro grupo para aqui.',
      style: TextStyle(
        color: PWColors.textMuted,
        fontSize: compacto ? 11.5 : 12.5,
      ),
    ),
  );
}

/// Uma linha de personagem — arrastável para outro grupo.
///
/// **`LongPressDraggable` e não `Draggable`**: num telemóvel a página rola com
/// o dedo, e um arrasto imediato roubaria todos os deslizes verticais. O
/// toque longo diz *isto é para levar* e deixa o rolar em paz — o mesmo
/// compromisso que qualquer lista reordenável do sistema faz.
class _Linha extends StatelessWidget {
  const _Linha({
    required this.quem,
    required this.onde,
    required this.compacto,
    required this.pegouHoje,
    required this.aoSomar,
    required this.aoContar,
    required this.aoRenomear,
    required this.aoRemover,
    required this.aoPegarDiaria,
    required this.campos,
    required this.colunas,
    required this.nomeFixo,
    required this.aoDefinirExtra,
  });

  final PersonagemDeInstancia quem;
  final Morada onde;
  final bool compacto;
  final bool pegouHoje;
  final void Function(Morada, EntradaDeInstancia, int) aoSomar;
  final void Function(Morada, EntradaDeInstancia, int) aoContar;
  final void Function(Morada, String) aoRenomear;
  final void Function(Morada) aoRemover;
  final void Function(Morada) aoPegarDiaria;
  final List<CampoPersonalizado> campos;
  final List<CampoPersonalizado> colunas;
  final bool nomeFixo;
  final void Function(Morada, String, String?) aoDefinirExtra;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // A identidade (pega + ícone + nome). Quando há colunas de campo,
            // mede exactamente `_larguraNome`, para a tabela que rola não
            // transbordar por uns pixéis da pega; senão enche o espaço livre.
            if (nomeFixo)
              SizedBox(
                width: _larguraNome,
                child: Row(
                  children: [
                    _PegaArrasto(onde: onde, quem: quem, compacto: compacto),
                    ClassIcon(ocupacaoDaClasse[quem.classe] ?? -1, size: 26),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _Nome(
                        nome: quem.nome,
                        classe: quem.classe,
                        compacto: compacto,
                        aoRenomear: (novo) => aoRenomear(onde, novo),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              _PegaArrasto(onde: onde, quem: quem, compacto: compacto),
              // O ícone de classe sai no estreito: a classe já está escrita
              // debaixo do nome, e a 390 px os quatro steppers não cabem com
              // ele ao lado.
              if (!compacto) ...[
                ClassIcon(ocupacaoDaClasse[quem.classe] ?? -1, size: 26),
                const SizedBox(width: 9),
              ],
              Expanded(
                child: _Nome(
                  nome: quem.nome,
                  classe: quem.classe,
                  compacto: compacto,
                  aoRenomear: (novo) => aoRenomear(onde, novo),
                ),
              ),
            ],
            for (final entrada in EntradaDeInstancia.values)
              SizedBox(
                width: _coluna(compacto),
                child: _Campo(
                  valor: quem.de(entrada),
                  rotulo: '${entrada.nome} de ${quem.nome}',
                  compacto: compacto,
                  destaque: entrada == EntradaDeInstancia.chave,
                  aoMudar: (n) => aoContar(onde, entrada, n),
                  aoSomar: (d) => aoSomar(onde, entrada, d),
                ),
              ),
            for (final c in colunas)
              SizedBox(
                width: _larguraCampoColuna(c),
                child: _CelulaColunaCampo(
                  campo: c,
                  quem: quem,
                  onde: onde,
                  aoDefinir: aoDefinirExtra,
                ),
              ),
            SizedBox(
              width: _colunaDoBotao(compacto),
              child: Center(
                child: _BotaoDaDiaria(
                  nome: quem.nome,
                  pegouHoje: pegouHoje,
                  aoPegar: () => aoPegarDiaria(onde),
                ),
              ),
            ),
            SizedBox(
              width: _colunaDoBotao(compacto),
              child: Center(
                child: Tooltip(
                  message: 'Tirar ${quem.nome} da lista',
                  child: InkWell(
                    onTap: () => aoRemover(onde),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: EdgeInsets.all(compacto ? 5 : 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: PWColors.border),
                      ),
                      child: Icon(
                        Icons.person_remove_outlined,
                        size: compacto ? 15 : 17,
                        color: PWColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Debaixo da linha, só as notas: a marcação e a escolha já são
        // colunas à direita, portanto aqui fica o que não cabe numa coluna.
        // Indentado para alinhar com o nome, não com a pega.
        if (_notas.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: compacto ? 24 : 37),
            child: CamposDoPersonagem(
              campos: _notas,
              quem: quem,
              onde: onde,
              aoDefinir: aoDefinirExtra,
            ),
          ),
      ],
    ),
  );

  /// As notas — o que a tabela larga mostra por baixo do nome. (Marcação e
  /// escolha são colunas.)
  List<CampoPersonalizado> get _notas => [
    for (final c in campos)
      if (c.tipo == CampoTipo.nota) c,
  ];
}

/// O que se vê a voar com o dedo durante o arrasto.
/// A pega por onde um personagem se arrasta para outro grupo.
///
/// **Só a pega arrasta, e isso resolve duas coisas de uma vez.** Antes a
/// linha inteira era arrastável e, sobre o campo de texto do nome, o toque
/// longo virava seleção de texto — o gesto nascia no sítio errado. E com
/// rato, o toque longo não se adivinha: o dono abriu a tela e não viu como
/// mudar alguém de grupo. Uma pega dedicada mostra o cursor de agarrar, traz
/// a sua dica, e larga o resto da linha em paz.
///
/// **`Draggable` e não `LongPressDraggable`** porque a pega é um alvo pequeno
/// e à esquerda: agarrá-la não rouba o deslize vertical da página como um
/// arrasto imediato sobre a linha toda roubaria. É o mesmo que uma lista
/// reordenável do sistema faz com o seu punho.
class _PegaArrasto extends StatelessWidget {
  const _PegaArrasto({
    required this.onde,
    required this.quem,
    required this.compacto,
  });

  final Morada onde;
  final PersonagemDeInstancia quem;
  final bool compacto;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Arraste para mudar de grupo',
    child: MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Draggable<_Arrasto>(
        data: onde,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: _Fantasma(quem: quem),
        // Enquanto se arrasta, a pega apaga-se no lugar de origem — um sinal
        // discreto de que a cópia que voa é esta.
        childWhenDragging: Opacity(opacity: 0.2, child: _icone()),
        child: _icone(),
      ),
    ),
  );

  Widget _icone() => Padding(
    padding: EdgeInsets.symmetric(horizontal: compacto ? 2 : 4, vertical: 2),
    child: Icon(
      Icons.drag_indicator,
      size: compacto ? 18 : 20,
      color: PWColors.textMuted,
    ),
  );
}

class _Fantasma extends StatelessWidget {
  const _Fantasma({required this.quem});
  final PersonagemDeInstancia quem;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: PWColors.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PWColors.accent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClassIcon(ocupacaoDaClasse[quem.classe] ?? -1, size: 24),
          const SizedBox(width: 8),
          Text(
            quem.nome,
            style: const TextStyle(
              color: PWColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Nome extends StatefulWidget {
  const _Nome({
    required this.nome,
    required this.classe,
    required this.compacto,
    required this.aoRenomear,
  });
  final String nome;
  final String classe;
  final bool compacto;
  final void Function(String) aoRenomear;
  @override
  State<_Nome> createState() => _NomeState();
}

class _NomeState extends State<_Nome> {
  late final TextEditingController _c = TextEditingController(
    text: widget.nome,
  );
  @override
  void didUpdateWidget(_Nome a) {
    super.didUpdateWidget(a);
    if (widget.nome != _c.text) _c.text = widget.nome;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      TextField(
        controller: _c,
        onSubmitted: widget.aoRenomear,
        onTapOutside: (_) => widget.aoRenomear(_c.text),
        style: TextStyle(
          color: PWColors.text,
          fontSize: widget.compacto ? 13 : 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          isDense: true,
          filled: false,
          contentPadding: EdgeInsets.symmetric(vertical: 4),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
      Text(
        widget.classe,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: PWColors.textMuted,
          fontSize: widget.compacto ? 10.5 : 11.5,
        ),
      ),
    ],
  );
}

/// Um número com `−` e `+`, que também se pode escrever.
///
/// **Os botões são o pedido do dono e o campo fica.** Tocar `−`/`+` é o gesto
/// de *usei uma chave* / *ganhei uma entrada*; escrever direto é para saltos
/// grandes. Um sem o outro deixava metade dos usos desajeitado.
///
/// **Vazio é zero e nunca "não sei".** Quem escreve aqui é o dono da conta: se
/// apagou o campo, tem zero. É o oposto do card do mercado, onde uma ausência
/// significa *não foi lido*.
class _Campo extends StatefulWidget {
  const _Campo({
    required this.valor,
    required this.rotulo,
    required this.compacto,
    required this.aoMudar,
    required this.aoSomar,
    this.destaque = false,
  });

  final int valor;
  final String rotulo;
  final bool compacto;
  final void Function(int) aoMudar;
  final void Function(int) aoSomar;

  /// A coluna da chave. Pinta o número em dourado — é a métrica herói desta
  /// ferramenta (a que se conta, a que acaba primeiro), e sem isto era só a
  /// quarta coluna igual às outras.
  final bool destaque;

  @override
  State<_Campo> createState() => _CampoState();
}

class _CampoState extends State<_Campo> {
  late final TextEditingController _c = TextEditingController(
    text: widget.valor == 0 ? '' : '${widget.valor}',
  );

  @override
  void didUpdateWidget(_Campo a) {
    super.didUpdateWidget(a);
    final escrito = int.tryParse(_c.text) ?? 0;
    if (escrito != widget.valor) {
      _c.text = widget.valor == 0 ? '' : '${widget.valor}';
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passo = widget.compacto ? 18.0 : 26.0;
    // Recuo de cada lado para o `+` desta coluna não encostar ao `−` da
    // seguinte: na tabela do largo as colunas são caixas encostadas, e sem
    // este vão os dois controlos liam-se como um só.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Passo(
            icone: Icons.remove,
            // Desligado no zero: ninguém tem menos que nada, e um `−` que não
            // faz nada ensina a desconfiar dos que fazem.
            ligado: widget.valor > 0,
            lado: passo,
            rotulo: 'menos um — ${widget.rotulo}',
            aoTocar: () => widget.aoSomar(-1),
          ),
          SizedBox(width: widget.compacto ? 3 : 5),
          Expanded(
            child: Semantics(
              label: widget.rotulo,
              child: TextField(
                controller: _c,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (t) => widget.aoMudar(int.tryParse(t) ?? 0),
                // O número lidera: maior e mais forte que os `−`/`+` à volta,
                // porque é a informação e o resto é maquinaria. A chave em
                // dourado.
                style: TextStyle(
                  color: widget.destaque ? PWColors.accent : PWColors.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  filled: false,
                  hintText: '0',
                  hintStyle: TextStyle(color: PWColors.border, fontSize: 18),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 0,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          SizedBox(width: widget.compacto ? 3 : 5),
          _Passo(
            icone: Icons.add,
            ligado: true,
            lado: passo,
            rotulo: 'mais um — ${widget.rotulo}',
            aoTocar: () => widget.aoSomar(1),
          ),
        ],
      ),
    );
  }
}

class _Passo extends StatelessWidget {
  const _Passo({
    required this.icone,
    required this.ligado,
    required this.lado,
    required this.rotulo,
    required this.aoTocar,
  });

  final IconData icone;
  final bool ligado;
  final double lado;
  final String rotulo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: rotulo,
    // **Fantasma, não caixa.** A moldura em volta de cada `−`/`+` era o que
    // enchia a grelha de retângulos e punha os controlos a competir com o
    // número. Sem borda nem fundo, o `−` e o `+` são só glifos; o `InkWell`
    // acende um halo redondo quando o rato passa, portanto no computador eles
    // dizem "sou botão" ao aproximar e desaparecem no resto do tempo. No
    // telemóvel não há hover, mas o glifo sozinho basta — ninguém confunde um
    // `+` com texto.
    child: InkWell(
      onTap: ligado ? aoTocar : null,
      borderRadius: BorderRadius.circular(lado / 2),
      hoverColor: PWColors.surfaceRaised,
      child: SizedBox(
        width: lado,
        height: lado,
        child: Icon(
          icone,
          size: lado * 0.62,
          color: ligado ? PWColors.textMuted : PWColors.border,
        ),
      ),
    ),
  );
}

class _Subtotal extends StatelessWidget {
  const _Subtotal({
    required this.grupo,
    required this.compacto,
    this.colunas = const [],
    this.nomeFixo = false,
  });
  final GrupoDeInstancias grupo;
  final bool compacto;
  final List<CampoPersonalizado> colunas;
  final bool nomeFixo;

  int _marcadosNoGrupo(String campoId) =>
      grupo.personagens.where((p) => p.marcado(campoId)).length;

  @override
  Widget build(BuildContext context) {
    final quantos = grupo.personagens.length;
    final rotulo = Text(
      quantos == 1 ? 'subtotal · 1' : 'subtotal · $quantos',
      style: const TextStyle(
        color: PWColors.textMuted,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 7, 0, 7),
      child: Row(
        children: [
          if (nomeFixo)
            SizedBox(width: _larguraNome - 10, child: rotulo)
          else
            Expanded(child: rotulo),
          for (final entrada in EntradaDeInstancia.values)
            SizedBox(
              width: _coluna(compacto),
              child: Text(
                '${grupo.total(entrada)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  // A chave do subtotal também em dourado, para a coluna herói
                  // se manter reconhecível de cima a baixo.
                  color: entrada == EntradaDeInstancia.chave
                      ? PWColors.accent
                      : PWColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          // Nas colunas de campo, a marcação mostra quantos marcaram; a
          // escolha não soma nada.
          for (final c in colunas)
            SizedBox(
              width: _larguraCampoColuna(c),
              child: Text(
                c.tipo == CampoTipo.marcacao ? '${_marcadosNoGrupo(c.id)}' : '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PWColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          SizedBox(width: _colunaDoBotao(compacto) * 2),
        ],
      ),
    );
  }
}

class _TotalGeral extends StatelessWidget {
  const _TotalGeral({
    required this.plano,
    required this.compacto,
    this.colunas = const [],
    this.nomeFixo = false,
  });
  final PlanoDeInstancias plano;
  final bool compacto;
  final List<CampoPersonalizado> colunas;
  final bool nomeFixo;

  @override
  Widget build(BuildContext context) {
    final n = plano.quantosPersonagens;
    final rotulo = Text(
      n == 1 ? 'Total · 1 personagem' : 'Total · $n personagens',
      style: const TextStyle(
        color: PWColors.text,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
    // Uma barra cheia, não uma linha fina. Numa ferramenta sobre somas, o
    // total geral é a âncora do fim — tem de ter peso de rodapé, não de mais
    // uma linha da tabela.
    //
    // No modo coluna o padding horizontal sai: ele empurraria as colunas para
    // fora do alinhamento com as linhas e faria a tabela transbordar.
    return Container(
      padding: nomeFixo
          ? const EdgeInsets.symmetric(vertical: 13)
          : const EdgeInsets.fromLTRB(14, 13, 6, 13),
      decoration: BoxDecoration(
        color: PWColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PWColors.border),
      ),
      child: Row(
        children: [
          if (nomeFixo)
            SizedBox(
              width: _larguraNome,
              child: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: rotulo,
              ),
            )
          else
            Expanded(child: rotulo),
          for (final entrada in EntradaDeInstancia.values)
            SizedBox(
              width: _coluna(compacto),
              child: Text(
                '${plano.total(entrada)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PWColors.accent,
                  fontSize: entrada == EntradaDeInstancia.chave ? 22 : 19,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          for (final c in colunas)
            SizedBox(
              width: _larguraCampoColuna(c),
              child: Text(
                c.tipo == CampoTipo.marcacao ? '${plano.marcados(c.id)}' : '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PWColors.accent,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          SizedBox(width: _colunaDoBotao(compacto) * 2),
        ],
      ),
    );
  }
}

// ===================== O estreito: cartões =====================
//
// **No telemóvel a linha única apertava tudo** — quatro `− [n] +` ao lado do
// nome e do ícone não cabem em 390 px, e encolhê-los até caber tornava os
// botões bicos de agulha. O dono pediu o óbvio: nome e classe em cima, os
// botões numa fila por baixo. Cada botão ganha o ícone do item ao lado, que é
// o que substitui o cabeçalho de colunas que o estreito deixou de ter.

/// Um personagem como cartão: identidade em cima, contagens em baixo.
class _Cartao extends StatelessWidget {
  const _Cartao({
    required this.quem,
    required this.onde,
    required this.pegouHoje,
    required this.aoSomar,
    required this.aoContar,
    required this.aoRenomear,
    required this.aoRemover,
    required this.aoPegarDiaria,
    required this.campos,
    required this.aoDefinirExtra,
  });

  final PersonagemDeInstancia quem;
  final Morada onde;
  final bool pegouHoje;
  final void Function(Morada, EntradaDeInstancia, int) aoSomar;
  final void Function(Morada, EntradaDeInstancia, int) aoContar;
  final void Function(Morada, String) aoRenomear;
  final void Function(Morada) aoRemover;
  final void Function(Morada) aoPegarDiaria;
  final List<CampoPersonalizado> campos;
  final void Function(Morada, String, String?) aoDefinirExtra;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _PegaArrasto(onde: onde, quem: quem, compacto: true),
              const SizedBox(width: 2),
              ClassIcon(ocupacaoDaClasse[quem.classe] ?? -1, size: 30),
              const SizedBox(width: 9),
              Expanded(
                child: _Nome(
                  nome: quem.nome,
                  classe: quem.classe,
                  compacto: true,
                  aoRenomear: (novo) => aoRenomear(onde, novo),
                ),
              ),
              _BotaoDaDiaria(
                nome: quem.nome,
                pegouHoje: pegouHoje,
                aoPegar: () => aoPegarDiaria(onde),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: 'Tirar ${quem.nome} da lista',
                child: InkWell(
                  onTap: () => aoRemover(onde),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: PWColors.border),
                    ),
                    child: const Icon(
                      Icons.person_remove_outlined,
                      size: 16,
                      color: PWColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // As três entradas numa fila, a chave sozinha na de baixo. São
          // coisas diferentes — a entrada abre a instância, a chave abre o
          // baú lá dentro —, e separá-las dá a cada botão o dobro da largura:
          // numa fila de quatro a 390 px, os `−`/`+` ficavam bicos de agulha.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entrada in EntradaDeInstancia.entradas) ...[
                // O espaço entre colunas, antes de cada uma menos a primeira:
                // sem ele o `+` de uma relíquia encostava ao `−` da seguinte,
                // e os dois liam-se como um controlo só.
                if (entrada != EntradaDeInstancia.entradas.first)
                  const SizedBox(width: 24),
                Expanded(
                  child: _CelulaEstreita(
                    entrada: entrada,
                    valor: quem.de(entrada),
                    rotulo: '${entrada.nome} de ${quem.nome}',
                    aoMudar: (n) => aoContar(onde, entrada, n),
                    aoSomar: (d) => aoSomar(onde, entrada, d),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _CelulaEstreita(
            entrada: EntradaDeInstancia.chave,
            valor: quem.de(EntradaDeInstancia.chave),
            rotulo: 'Chave da Sorte de ${quem.nome}',
            aoMudar: (n) => aoContar(onde, EntradaDeInstancia.chave, n),
            aoSomar: (d) => aoSomar(onde, EntradaDeInstancia.chave, d),
            comRotulo: true,
          ),
          if (campos.isNotEmpty)
            CamposDoPersonagem(
              campos: campos,
              quem: quem,
              onde: onde,
              aoDefinir: aoDefinirExtra,
            ),
        ],
      ),
    );
  }
}

/// Uma contagem no cartão: o ícone do item, e `−` [n] `+` por baixo.
///
/// O ícone é o que diz qual item é — no estreito não há cabeçalho de colunas
/// a dizê-lo, portanto cada célula tem de se explicar sozinha.
class _CelulaEstreita extends StatefulWidget {
  const _CelulaEstreita({
    required this.entrada,
    required this.valor,
    required this.rotulo,
    required this.aoMudar,
    required this.aoSomar,
    this.comRotulo = false,
  });

  final EntradaDeInstancia entrada;
  final int valor;
  final String rotulo;
  final void Function(int) aoMudar;
  final void Function(int) aoSomar;

  /// Desenha o nome do item ao lado, numa linha horizontal, em vez do ícone
  /// por cima. É o formato da chave no cartão: sozinha na sua linha, há espaço
  /// para a nomear por extenso e dar aos botões mais largura.
  final bool comRotulo;

  @override
  State<_CelulaEstreita> createState() => _CelulaEstreitaState();
}

class _CelulaEstreitaState extends State<_CelulaEstreita> {
  late final TextEditingController _c = TextEditingController(
    text: widget.valor == 0 ? '' : '${widget.valor}',
  );

  @override
  void didUpdateWidget(_CelulaEstreita a) {
    super.didUpdateWidget(a);
    final escrito = int.tryParse(_c.text) ?? 0;
    if (escrito != widget.valor) {
      _c.text = widget.valor == 0 ? '' : '${widget.valor}';
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _campo({double tamanho = 15}) => Semantics(
    label: widget.rotulo,
    child: TextField(
      controller: _c,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (t) => widget.aoMudar(int.tryParse(t) ?? 0),
      style: TextStyle(
        color: PWColors.text,
        fontSize: tamanho,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        hintText: '0',
        hintStyle: TextStyle(color: PWColors.border, fontSize: tamanho),
        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    // A chave, sozinha na sua linha: ícone, nome por extenso, e os botões à
    // direita com o campo de largura fixa — esticá-lo de ponta a ponta
    // afastaria o − do + até não parecerem o mesmo controlo.
    if (widget.comRotulo) {
      return Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: PWColors.surface,
          border: Border.all(color: PWColors.border),
        ),
        child: Row(
          children: [
            ItemIcon(widget.entrada.itemId, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.entrada.nome,
                style: const TextStyle(
                  color: PWColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _Passo(
              icone: Icons.remove,
              ligado: widget.valor > 0,
              lado: 30,
              rotulo: 'menos um — ${widget.rotulo}',
              aoTocar: () => widget.aoSomar(-1),
            ),
            const SizedBox(width: 8),
            SizedBox(width: 54, child: _campo(tamanho: 16)),
            const SizedBox(width: 8),
            _Passo(
              icone: Icons.add,
              ligado: true,
              lado: 30,
              rotulo: 'mais um — ${widget.rotulo}',
              aoTocar: () => widget.aoSomar(1),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ItemIcon(widget.entrada.itemId, size: 22),
        const SizedBox(height: 5),
        Row(
          children: [
            _Passo(
              icone: Icons.remove,
              ligado: widget.valor > 0,
              lado: 26,
              rotulo: 'menos um — ${widget.rotulo}',
              aoTocar: () => widget.aoSomar(-1),
            ),
            const SizedBox(width: 4),
            Expanded(child: _campo()),
            const SizedBox(width: 4),
            _Passo(
              icone: Icons.add,
              ligado: true,
              lado: 26,
              rotulo: 'mais um — ${widget.rotulo}',
              aoTocar: () => widget.aoSomar(1),
            ),
          ],
        ),
      ],
    );
  }
}

/// O subtotal de um grupo, no estreito: ícone do item e número, por célula.
class _SubtotalEstreito extends StatelessWidget {
  const _SubtotalEstreito({required this.grupo});
  final GrupoDeInstancias grupo;

  @override
  Widget build(BuildContext context) => _FaixaDeSomaEstreita(
    rotulo: grupo.personagens.length == 1
        ? 'subtotal · 1'
        : 'subtotal · ${grupo.personagens.length}',
    valorDe: grupo.total,
    cor: PWColors.textMuted,
    forte: false,
  );
}

/// O total geral, no estreito.
class _TotalGeralEstreito extends StatelessWidget {
  const _TotalGeralEstreito({required this.plano});
  final PlanoDeInstancias plano;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: PWColors.border, width: 2)),
    ),
    child: _FaixaDeSomaEstreita(
      rotulo: plano.quantosPersonagens == 1
          ? 'Total · 1 personagem'
          : 'Total · ${plano.quantosPersonagens} personagens',
      valorDe: plano.total,
      cor: PWColors.accent,
      forte: true,
    ),
  );
}

class _FaixaDeSomaEstreita extends StatelessWidget {
  const _FaixaDeSomaEstreita({
    required this.rotulo,
    required this.valorDe,
    required this.cor,
    required this.forte,
  });

  final String rotulo;
  final int Function(EntradaDeInstancia) valorDe;
  final Color cor;
  final bool forte;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: TextStyle(
            color: forte ? PWColors.text : PWColors.textMuted,
            fontSize: forte ? 13 : 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            for (final entrada in EntradaDeInstancia.values)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ItemIcon(entrada.itemId, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      '${valorDe(entrada)}',
                      style: TextStyle(
                        color: cor,
                        fontSize: forte ? 16 : 14,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

/// No estreito não há cabeçalho de colunas para tocar e ordenar, portanto a
/// ordenação vive numa fila de botões pequenos — um por item. É a mesma
/// acção que o cabeçalho faz no largo, só que dita com palavras porque os
/// ícones ali já estão gastos a identificar as colunas dos cartões.
class _OrdenarEstreito extends StatelessWidget {
  const _OrdenarEstreito({required this.plano, required this.aoOrdenar});
  final PlanoDeInstancias plano;
  final void Function(EntradaDeInstancia) aoOrdenar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        const Text(
          'Ordenar:',
          style: TextStyle(color: PWColors.textMuted, fontSize: 12),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final entrada in EntradaDeInstancia.values)
                _ChipDeOrdem(
                  entrada: entrada,
                  ativo:
                      plano.ordem is OrdemPorEntrada &&
                      (plano.ordem as OrdemPorEntrada).entrada == entrada,
                  aoTocar: () => aoOrdenar(entrada),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ChipDeOrdem extends StatelessWidget {
  const _ChipDeOrdem({
    required this.entrada,
    required this.ativo,
    required this.aoTocar,
  });
  final EntradaDeInstancia entrada;
  final bool ativo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: aoTocar,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: ativo ? PWColors.surfaceRaised : null,
        border: Border.all(color: ativo ? PWColors.accent : PWColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ItemIcon(entrada.itemId, size: 15),
          const SizedBox(width: 5),
          Text(
            entrada.curto,
            style: TextStyle(
              fontSize: 11.5,
              color: ativo ? PWColors.accent : PWColors.textMuted,
              fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}
