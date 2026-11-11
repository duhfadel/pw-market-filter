import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/widgets/game_icon.dart';
import '../../../../market/ocupacoes.dart';
import '../../domain/entrada_de_instancia.dart';
import '../../domain/grupo_de_instancias.dart';
import '../../domain/personagem_de_instancia.dart';
import '../../domain/plano_de_instancias.dart';

/// A largura de uma coluna de número — o par `−`/`+` mais o campo. Uma só
/// medida, para o cabeçalho, as linhas e as somas não poderem desalinhar-se.
const _colunaDeNumero = 96.0;
const _colunaEstreita = 64.0;

/// A coluna do botão de tirar. Uma medida só, pela mesma razão.
double _colunaDoBotao(bool compacto) => compacto ? 34 : 40;
double _coluna(bool compacto) => compacto ? _colunaEstreita : _colunaDeNumero;

/// O que o arrastar carrega: a morada de origem de um personagem.
typedef _Arrasto = Morada;

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

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Cabecalho(plano: plano, compacto: compacto, aoOrdenar: aoOrdenar),
      const Divider(height: 1),
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
        ),
      const SizedBox(height: 6),
      _TotalGeral(plano: plano, compacto: compacto),
    ],
  );
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({
    required this.plano,
    required this.compacto,
    required this.aoOrdenar,
  });

  final PlanoDeInstancias plano;
  final bool compacto;
  final void Function(EntradaDeInstancia) aoOrdenar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
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
        SizedBox(width: _colunaDoBotao(compacto)),
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
                color: ordenada ? PWColors.accent : PWColors.textMuted,
                fontWeight: ordenada ? FontWeight.w700 : FontWeight.w500,
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
              if (g.personagens.isEmpty)
                _GrupoVazio(compacto: compacto)
              else
                for (final quem in ordenados) ...[
                  const Divider(height: 1),
                  _Linha(
                    quem: quem,
                    // A morada de origem, achada por identidade: dois
                    // personagens podem ter o mesmo nome e a mesma classe, e
                    // procurar por nome escreveria no errado.
                    onde: Morada(grupo, g.personagens.indexOf(quem)),
                    compacto: compacto,
                    aoSomar: aoSomar,
                    aoContar: aoContar,
                    aoRenomear: aoRenomear,
                    aoRemover: aoRemover,
                  ),
                ],
              const Divider(height: 1),
              _Subtotal(grupo: g, compacto: compacto),
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
    required this.aoSomar,
    required this.aoContar,
    required this.aoRenomear,
    required this.aoRemover,
  });

  final PersonagemDeInstancia quem;
  final Morada onde;
  final bool compacto;
  final void Function(Morada, EntradaDeInstancia, int) aoSomar;
  final void Function(Morada, EntradaDeInstancia, int) aoContar;
  final void Function(Morada, String) aoRenomear;
  final void Function(Morada) aoRemover;

  @override
  Widget build(BuildContext context) {
    final conteudo = _conteudo();
    return LongPressDraggable<_Arrasto>(
      data: onde,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: _Fantasma(quem: quem),
      // O lugar de origem esmaece enquanto o dedo carrega a cópia — diz de
      // onde isto saiu sem o fazer desaparecer, caso o arrasto se cancele.
      childWhenDragging: Opacity(opacity: 0.35, child: conteudo),
      child: conteudo,
    );
  }

  Widget _conteudo() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        // A pega: diz que a linha se arrasta. No telemóvel não há hover, e
        // sem isto o gesto seria um segredo.
        Padding(
          padding: EdgeInsets.only(
            left: compacto ? 0 : 2,
            right: compacto ? 2 : 4,
          ),
          child: Icon(
            Icons.drag_indicator,
            size: compacto ? 14 : 16,
            color: PWColors.border,
          ),
        ),
        // O ícone de classe sai no estreito: a classe já está escrita debaixo
        // do nome, e a 390 px os quatro steppers não cabem com ele ao lado.
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
        for (final entrada in EntradaDeInstancia.values)
          SizedBox(
            width: _coluna(compacto),
            child: _Campo(
              valor: quem.de(entrada),
              rotulo: '${entrada.nome} de ${quem.nome}',
              compacto: compacto,
              aoMudar: (n) => aoContar(onde, entrada, n),
              aoSomar: (d) => aoSomar(onde, entrada, d),
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
  );
}

/// O que se vê a voar com o dedo durante o arrasto.
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
  });

  final int valor;
  final String rotulo;
  final bool compacto;
  final void Function(int) aoMudar;
  final void Function(int) aoSomar;

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
    return Row(
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
        Expanded(
          child: Semantics(
            label: widget.rotulo,
            child: TextField(
              controller: _c,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (t) => widget.aoMudar(int.tryParse(t) ?? 0),
              style: const TextStyle(
                color: PWColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                hintText: '0',
                hintStyle: TextStyle(color: PWColors.border, fontSize: 15),
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
        _Passo(
          icone: Icons.add,
          ligado: true,
          lado: passo,
          rotulo: 'mais um — ${widget.rotulo}',
          aoTocar: () => widget.aoSomar(1),
        ),
      ],
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
    child: InkWell(
      onTap: ligado ? aoTocar : null,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        width: lado,
        height: lado,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: PWColors.border),
        ),
        child: Icon(
          icone,
          size: lado * 0.56,
          color: ligado ? PWColors.textMuted : PWColors.border,
        ),
      ),
    ),
  );
}

class _Subtotal extends StatelessWidget {
  const _Subtotal({required this.grupo, required this.compacto});
  final GrupoDeInstancias grupo;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final quantos = grupo.personagens.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 7, 0, 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              quantos == 1 ? 'subtotal · 1' : 'subtotal · $quantos',
              style: const TextStyle(
                color: PWColors.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final entrada in EntradaDeInstancia.values)
            SizedBox(
              width: _coluna(compacto),
              child: Text(
                '${grupo.total(entrada)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PWColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          SizedBox(width: _colunaDoBotao(compacto)),
        ],
      ),
    );
  }
}

class _TotalGeral extends StatelessWidget {
  const _TotalGeral({required this.plano, required this.compacto});
  final PlanoDeInstancias plano;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final n = plano.quantosPersonagens;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: PWColors.border, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              n == 1 ? 'Total · 1 personagem' : 'Total · $n personagens',
              style: const TextStyle(
                color: PWColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final entrada in EntradaDeInstancia.values)
            SizedBox(
              width: _coluna(compacto),
              child: Text(
                '${plano.total(entrada)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PWColors.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          SizedBox(width: _colunaDoBotao(compacto)),
        ],
      ),
    );
  }
}
