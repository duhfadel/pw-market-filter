import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/rotas.dart' as rotas;
import '../../../core/theme/pw_colors.dart';
import '../../ads/ad_slot.dart';
import '../../home/ui/widgets/cabecalho.dart';
import '../domain/entrada_de_instancia.dart';
import '../domain/plano_de_instancias.dart';
import 'instancias_view_model.dart';
import 'widgets/escolher_classe.dart';
import 'widgets/gerir_campos.dart';
import 'widgets/tabela_de_instancias.dart';

/// O organizador de instâncias: grupos de personagens, e quantas entradas e
/// chaves cada um tem.
///
/// **É a primeira ferramenta deste site que escreve em vez de ler.** Tudo o
/// resto parte de uma recolha — o mercado, os registos, os vídeos — e
/// responde sobre o jogo. Esta não sabe nada: a lista é de quem está a ler,
/// escrita à mão, e o site nunca a viu nem a pode verificar.
///
/// **Por isso ela vive no navegador de quem escreve.** Não há conta, não há
/// servidor nosso no meio e não guardamos dados de ninguém. O preço é que é
/// por aparelho — e é por isso que existe o botão de link, a única rede
/// contra trocar de telemóvel ou limpar o navegador.
///
/// Os personagens arrumam-se em grupos de nome livre — *Conta principal*,
/// *Mulas* — e arrastam-se de um para outro. Ver `TabelaDeInstancias`.
class InstanciasView extends StatelessWidget {
  const InstanciasView({super.key, this.query = const {}});

  final Map<String, List<String>> query;

  /// Abaixo disto a tabela aperta — mas nunca perde uma coluna. São quatro
  /// números e eles são a tabela; empilhá-los daria quatro linhas por
  /// personagem e acabava-se a comparação, que é a razão de isto existir.
  static const _telaEstreita = 620.0;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<InstanciasViewModel>()..carregar(query),
    child: const _Tela(),
  );
}

class _Tela extends StatelessWidget {
  const _Tela();

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final compacto = largura < InstanciasView._telaEstreita;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Cabecalho(
          wide: largura >= Cabecalho.larguraMinima,
          versao: rotas.pw187,
        ),
      ),
      body: BlocBuilder<InstanciasViewModel, PlanoDeInstancias>(
        builder: (context, plano) =>
            _Conteudo(plano: plano, compacto: compacto),
      ),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.plano, required this.compacto});

  final PlanoDeInstancias plano;
  final bool compacto;

  Future<void> _adicionar(BuildContext context, int grupo) async {
    final vm = context.read<InstanciasViewModel>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: PWColors.surface,
      isScrollControlled: true,
      builder: (folha) => EscolherClasse(
        aoConfirmar: (nome, classe) {
          vm.adicionar(grupo, nome, classe);
          Navigator.of(folha).pop();
        },
      ),
    );
  }

  Future<void> _novoGrupo(BuildContext context) async {
    final vm = context.read<InstanciasViewModel>();
    final nome = await _perguntarNome(context);
    if (nome != null && nome.trim().isNotEmpty) vm.adicionarGrupo(nome);
  }

  /// A folha de gerir campos: lista os que existem (para apagar) e tem o botão
  /// de criar um novo.
  Future<void> _gerirCampos(BuildContext context) async {
    final vm = context.read<InstanciasViewModel>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: PWColors.surface,
      isScrollControlled: true,
      builder: (folha) =>
          BlocProvider.value(value: vm, child: const GerirCampos()),
    );
  }

  void _removerGrupo(BuildContext context, int grupo) {
    final vm = context.read<InstanciasViewModel>();
    final g = vm.state.grupos[grupo];
    final mensageiro = ScaffoldMessenger.of(context);

    vm.removerGrupo(grupo);
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            g.personagens.isEmpty
                ? 'Grupo "${g.nome}" apagado.'
                : 'Grupo "${g.nome}" e ${g.personagens.length} personagens apagados.',
          ),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => vm.reporGrupo(grupo, g),
          ),
        ),
      );
  }

  void _removerPersonagem(BuildContext context, Morada onde) {
    final vm = context.read<InstanciasViewModel>();
    final quem = vm.state.grupos[onde.grupo].personagens[onde.personagem];
    final mensageiro = ScaffoldMessenger.of(context);

    vm.remover(onde);
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${quem.nome} saiu da lista.'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => vm.repor(onde, quem),
          ),
        ),
      );
  }

  /// Pegar a diária de um personagem, com desfazer.
  ///
  /// **Um clique errado soma +3 a quem não devia**, então guarda-se o plano
  /// de antes e oferece-se o desfazer — a mesma rede do tirar. Se já tinha
  /// pegado hoje o botão nem aparece, portanto aqui chega-se sempre com algo
  /// a somar.
  void _pegarDiaria(BuildContext context, Morada onde) {
    final vm = context.read<InstanciasViewModel>();
    final antes = vm.state;
    final nome = antes.grupos[onde.grupo].personagens[onde.personagem].nome;
    final mensageiro = ScaffoldMessenger.of(context);

    vm.pegarDiaria(onde);
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Entradas de hoje somadas a $nome.'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => vm.restaurar(antes),
          ),
        ),
      );
  }

  /// Finalizar uma dungeon no grupo, com desfazer. Conta quantos a fizeram —
  /// quem não tinha a entrada não entra.
  void _finalizarDungeon(
    BuildContext context,
    int grupo,
    EntradaDeInstancia entrada,
  ) {
    final vm = context.read<InstanciasViewModel>();
    final antes = vm.state;
    final quantos = antes.grupos[grupo].podemDungeon(entrada);
    if (quantos == 0) return;
    final mensageiro = ScaffoldMessenger.of(context);

    vm.finalizarDungeon(grupo, entrada);
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            quantos == 1
                ? 'Dungeon de ${entrada.curto}: 1 personagem gastou 1 e ganhou 6 chaves.'
                : 'Dungeon de ${entrada.curto}: $quantos personagens gastaram 1 e ganharam 6 chaves.',
          ),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => vm.restaurar(antes),
          ),
        ),
      );
  }

  /// Pegar a diária do grupo inteiro, com desfazer. Conta quantos foram
  /// mesmo somados — quem já tinha pegado hoje não entra.
  void _pegarGrupo(BuildContext context, int grupo) {
    final vm = context.read<InstanciasViewModel>();
    final antes = vm.state;
    final somados = antes.grupos[grupo].faltamHoje(InstanciasViewModel.hoje());
    final mensageiro = ScaffoldMessenger.of(context);

    vm.pegarDiariaDoGrupo(grupo);
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            somados == 1
                ? 'Entradas de hoje somadas a 1 personagem.'
                : 'Entradas de hoje somadas a $somados personagens.',
          ),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => vm.restaurar(antes),
          ),
        ),
      );
  }

  Future<void> _copiarLink(BuildContext context) async {
    final vm = context.read<InstanciasViewModel>();
    final mensageiro = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: vm.link));
    mensageiro.showSnackBar(
      const SnackBar(
        content: Text(
          'Link copiado. Abra-o noutro aparelho para levar a lista.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<InstanciasViewModel>();
    // A tabela usa a largura toda do monitor — sem tecto, grupos lado a lado
    // enchendo o ecrã, pedido do dono. O texto e os botões ficam presos a uma
    // coluna de leitura, que esticada de ponta a ponta seria desconfortável.
    const leitura = 860.0;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        compacto ? 12 : 18,
        10,
        compacto ? 12 : 18,
        28,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: leitura),
            child: const _Explicacao(),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: leitura),
            child: _Acoes(
              plano: plano,
              aoNovoGrupo: () => unawaited(_novoGrupo(context)),
              aoNovoCampo: () => unawaited(_gerirCampos(context)),
              aoCopiar: () => unawaited(_copiarLink(context)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TabelaDeInstancias(
          plano: plano,
          compacto: compacto,
          aoOrdenar: vm.ordenarPor,
          aoSomar: vm.somar,
          aoContar: vm.contar,
          aoRenomear: vm.renomear,
          aoRemover: (onde) => _removerPersonagem(context, onde),
          aoMover: vm.mover,
          aoRenomearGrupo: vm.renomearGrupo,
          aoRemoverGrupo: (grupo) => _removerGrupo(context, grupo),
          aoAdicionarNoGrupo: (grupo) => unawaited(_adicionar(context, grupo)),
          hoje: InstanciasViewModel.hoje(),
          aoPegarDiaria: (onde) => _pegarDiaria(context, onde),
          aoPegarGrupo: (grupo) => _pegarGrupo(context, grupo),
          aoFinalizarDungeon: (grupo, entrada) =>
              _finalizarDungeon(context, grupo, entrada),
          aoDefinirExtra: vm.definirExtra,
        ),
        const SizedBox(height: 22),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: leitura),
            child: const _OndeFica(),
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: leitura),
            child: const AdSlot(),
          ),
        ),
      ],
    );
  }
}

/// Pergunta um nome de grupo num diálogo curto.
Future<String?> _perguntarNome(BuildContext context) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (d) => AlertDialog(
      backgroundColor: PWColors.surface,
      title: const Text('Novo grupo'),
      content: TextField(
        controller: c,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (v) => Navigator.of(d).pop(v),
        decoration: const InputDecoration(
          labelText: 'Nome do grupo',
          hintText: 'Conta principal, Mulas, …',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(d).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(d).pop(c.text),
          child: const Text('Criar'),
        ),
      ],
    ),
  );
}

class _Explicacao extends StatelessWidget {
  const _Explicacao();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Organizador de instâncias',
        style: Theme.of(context).textTheme.displayMedium,
      ),
      const SizedBox(height: 8),
      const Text(
        'Arrume os seus personagens em grupos — conta principal, mulas, o que '
        'quiser — e escreva quantas Relíquias Maravilha e Chaves da Sorte cada '
        'um tem. Arraste um personagem para o levar de um grupo a outro.',
        style: TextStyle(color: PWColors.textMuted, fontSize: 14, height: 1.5),
      ),
    ],
  );
}

class _Acoes extends StatelessWidget {
  const _Acoes({
    required this.plano,
    required this.aoNovoGrupo,
    required this.aoNovoCampo,
    required this.aoCopiar,
  });

  final PlanoDeInstancias plano;
  final VoidCallback aoNovoGrupo;
  final VoidCallback aoNovoCampo;
  final VoidCallback aoCopiar;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      FilledButton.icon(
        onPressed: aoNovoGrupo,
        icon: const Icon(Icons.create_new_folder_outlined, size: 18),
        label: const Text('Grupo'),
      ),
      // O construtor de campos: dá o nome e o tipo, e o campo aparece em
      // todos os personagens. Ver `CamposDoPersonagem`.
      OutlinedButton.icon(
        onPressed: aoNovoCampo,
        icon: const Icon(Icons.playlist_add, size: 18),
        label: Text(
          plano.campos.isEmpty ? 'Campo' : 'Campos (${plano.campos.length})',
        ),
      ),
      if (!plano.vazio)
        TextButton.icon(
          onPressed: aoCopiar,
          icon: const Icon(Icons.link, size: 17),
          label: const Text('Copiar link'),
        ),
    ],
  );
}

/// Diz onde a lista está guardada, e isto não é um detalhe técnico.
///
/// **Quem não sabe que é por aparelho descobre a perder tudo.** Uma
/// ferramenta sem conta que parece ter conta é uma promessa que o site não
/// fez — por isso está escrito na tela, ao lado do botão que resolve.
class _OndeFica extends StatelessWidget {
  const _OndeFica();
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.info_outline, size: 15, color: PWColors.textMuted),
      const SizedBox(width: 8),
      const Expanded(
        child: Text(
          'A lista fica guardada neste navegador, sem conta e sem servidor — '
          'ninguém mais a vê. Em troca, ela não acompanha você para outro '
          'aparelho: use Copiar link para a levar, ou para a guardar caso '
          'limpe os dados do navegador.',
          style: TextStyle(
            color: PWColors.textMuted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ),
    ],
  );
}
