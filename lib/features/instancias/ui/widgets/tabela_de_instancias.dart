import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/widgets/game_icon.dart';
import '../../../../market/ocupacoes.dart';
import '../../domain/entrada_de_instancia.dart';
import '../../domain/personagem_de_instancia.dart';
import '../../domain/plano_de_instancias.dart';

/// A largura de cada coluna de número. Uma só medida, para o cabeçalho, as
/// linhas e a soma de baixo não poderem desalinhar-se — que é o defeito que
/// uma tabela montada com três `Row` independentes tem de fábrica.
const _colunaDeNumero = 62.0;
const _colunaEstreita = 52.0;

/// A tabela: uma linha por personagem, quatro números cada, soma em baixo.
class TabelaDeInstancias extends StatelessWidget {
  const TabelaDeInstancias({
    required this.plano,
    required this.compacto,
    required this.aoOrdenar,
    required this.aoContar,
    required this.aoRenomear,
    required this.aoRemover,
    super.key,
  });

  final PlanoDeInstancias plano;
  final bool compacto;
  final void Function(EntradaDeInstancia) aoOrdenar;

  /// O índice é sempre o da lista **de origem**, nunca o da ordenada: é a
  /// tabela que sabe o que o dedo tocou e é ela que traduz.
  final void Function(int indice, EntradaDeInstancia entrada, int quantos)
  aoContar;
  final void Function(int indice, String nome) aoRenomear;
  final void Function(int indice) aoRemover;

  double get _largura => compacto ? _colunaEstreita : _colunaDeNumero;

  @override
  Widget build(BuildContext context) {
    final ordenados = plano.emOrdem;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Cabecalho(
          plano: plano,
          largura: _largura,
          compacto: compacto,
          aoOrdenar: aoOrdenar,
        ),
        const Divider(height: 1),
        for (final quem in ordenados) ...[
          _Linha(
            quem: quem,
            // O índice de origem, encontrado por identidade: dois
            // personagens podem ter o mesmo nome e a mesma classe, e
            // procurar por nome escreveria no errado.
            indice: plano.personagens.indexOf(quem),
            largura: _largura,
            compacto: compacto,
            aoContar: aoContar,
            aoRenomear: aoRenomear,
            aoRemover: aoRemover,
          ),
          const Divider(height: 1),
        ],
        _Soma(plano: plano, largura: _largura, compacto: compacto),
      ],
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({
    required this.plano,
    required this.largura,
    required this.compacto,
    required this.aoOrdenar,
  });

  final PlanoDeInstancias plano;
  final double largura;
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
            width: largura,
            child: _BotaoDeColuna(
              entrada: entrada,
              ordenada:
                  plano.ordem is OrdemPorEntrada &&
                  (plano.ordem as OrdemPorEntrada).entrada == entrada,
              compacto: compacto,
              aoTocar: () => aoOrdenar(entrada),
            ),
          ),
        SizedBox(width: compacto ? 30 : 36),
      ],
    ),
  );
}

/// O cabeçalho de uma coluna: o ícone do item e um toque que ordena.
///
/// **O ícone é a etiqueta e a palavra é a ajuda.** Quatro nomes inteiros —
/// `Relíquia Maravilha: Artefato` tem 28 caracteres — não cabem em coluna
/// nenhuma, e o jogador reconhece a arte. A palavra curta fica por baixo e o
/// nome inteiro no tooltip, para quem precisar de confirmar que marcou o
/// item certo.
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

class _Linha extends StatelessWidget {
  const _Linha({
    required this.quem,
    required this.indice,
    required this.largura,
    required this.compacto,
    required this.aoContar,
    required this.aoRenomear,
    required this.aoRemover,
  });

  final PersonagemDeInstancia quem;
  final int indice;
  final double largura;
  final bool compacto;
  final void Function(int, EntradaDeInstancia, int) aoContar;
  final void Function(int, String) aoRenomear;
  final void Function(int) aoRemover;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Row(
            children: [
              ClassIcon(ocupacaoDaClasse[quem.classe] ?? -1, size: 26),
              const SizedBox(width: 9),
              Expanded(
                child: _Nome(
                  nome: quem.nome,
                  classe: quem.classe,
                  compacto: compacto,
                  aoRenomear: (novo) => aoRenomear(indice, novo),
                ),
              ),
            ],
          ),
        ),
        for (final entrada in EntradaDeInstancia.values)
          SizedBox(
            width: largura,
            child: _Campo(
              valor: quem.de(entrada),
              rotulo: '${entrada.nome} de ${quem.nome}',
              aoMudar: (n) => aoContar(indice, entrada, n),
            ),
          ),
        SizedBox(
          width: compacto ? 30 : 36,
          child: IconButton(
            onPressed: () => aoRemover(indice),
            iconSize: compacto ? 16 : 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Tirar ${quem.nome} da lista',
            icon: const Icon(Icons.close, color: PWColors.textMuted),
          ),
        ),
      ],
    ),
  );
}

/// O nome, editável no sítio.
///
/// Escrito como o dono o escreveu e não maiúsculo nem arrumado: é o apelido
/// de alguém, e corrigi-lo faria a tabela discordar do jogo que ele tem na
/// outra janela.
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
  late final TextEditingController _controlador = TextEditingController(
    text: widget.nome,
  );

  @override
  void didUpdateWidget(_Nome anterior) {
    super.didUpdateWidget(anterior);
    // Só quando o nome deixa de concordar com o que está escrito — comparar
    // sempre e escrever sempre saltaria o cursor para o fim a cada letra. É
    // a mesma regra do `NumberField` do filtro.
    if (widget.nome != _controlador.text) _controlador.text = widget.nome;
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      TextField(
        controller: _controlador,
        onSubmitted: widget.aoRenomear,
        onTapOutside: (_) => widget.aoRenomear(_controlador.text),
        style: TextStyle(
          color: PWColors.text,
          fontSize: widget.compacto ? 13 : 14,
          fontWeight: FontWeight.w600,
        ),
        // **Sem o chão que o tema dá a todo o `TextField`.** Ali ele diz
        // *aqui escreve-se*, que numa tela de formulário é o que se quer;
        // numa tabela de quarenta campos são quarenta caixas claras a
        // desenhar a grelha por cima da grelha. O que diz que isto se
        // escreve é o cursor ao tocar.
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

/// Um número que se escreve.
///
/// **Vazio é zero e nunca "não sei".** Quem escreve aqui é o dono da conta:
/// se apagou o campo, tem zero. É o oposto do card do mercado, onde uma
/// ausência significa *não foi lido* e por isso não desenha linha nenhuma.
class _Campo extends StatefulWidget {
  const _Campo({
    required this.valor,
    required this.rotulo,
    required this.aoMudar,
  });

  final int valor;
  final String rotulo;
  final void Function(int) aoMudar;

  @override
  State<_Campo> createState() => _CampoState();
}

class _CampoState extends State<_Campo> {
  late final TextEditingController _controlador = TextEditingController(
    text: widget.valor == 0 ? '' : '${widget.valor}',
  );

  @override
  void didUpdateWidget(_Campo anterior) {
    super.didUpdateWidget(anterior);
    // Compara valores e não texto, para `07` não saltar o cursor — a mesma
    // regra do `NumberField`.
    final escrito = int.tryParse(_controlador.text) ?? 0;
    if (escrito != widget.valor) {
      _controlador.text = widget.valor == 0 ? '' : '${widget.valor}';
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.rotulo,
    child: TextField(
      controller: _controlador,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (texto) => widget.aoMudar(int.tryParse(texto) ?? 0),
      style: const TextStyle(
        color: PWColors.text,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        // Algarismos de largura fixa: é o que mantém quatro colunas de
        // números alinhadas quando uma linha tem 9 e a seguinte 31.
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      decoration: const InputDecoration(
        isDense: true,
        filled: false,
        hintText: '0',
        hintStyle: TextStyle(color: PWColors.border, fontSize: 15),
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    ),
  );
}

/// A soma de baixo — a única resposta que nenhuma linha sozinha dá.
class _Soma extends StatelessWidget {
  const _Soma({
    required this.plano,
    required this.largura,
    required this.compacto,
  });

  final PlanoDeInstancias plano;
  final double largura;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final quantos = plano.personagens.length;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              quantos == 1 ? '1 personagem' : '$quantos personagens',
              style: const TextStyle(
                color: PWColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final entrada in EntradaDeInstancia.values)
            SizedBox(
              width: largura,
              child: Text(
                '${plano.total(entrada)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PWColors.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          SizedBox(width: compacto ? 30 : 36),
        ],
      ),
    );
  }
}
