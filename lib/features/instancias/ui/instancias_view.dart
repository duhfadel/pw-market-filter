import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/rotas.dart' as rotas;
import '../../../core/theme/pw_colors.dart';
import '../../ads/ad_slot.dart';
import '../../home/ui/widgets/cabecalho.dart';
import '../domain/plano_de_instancias.dart';
import 'instancias_view_model.dart';
import 'widgets/escolher_classe.dart';
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            compacto ? 12 : 18,
            10,
            compacto ? 12 : 18,
            28,
          ),
          children: [
            const _Explicacao(),
            const SizedBox(height: 16),
            _Acoes(
              plano: plano,
              aoNovoGrupo: () => unawaited(_novoGrupo(context)),
              aoCopiar: () => unawaited(_copiarLink(context)),
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
              aoAdicionarNoGrupo: (grupo) =>
                  unawaited(_adicionar(context, grupo)),
            ),
            const SizedBox(height: 22),
            const _OndeFica(),
            const SizedBox(height: 22),
            const AdSlot(),
          ],
        ),
      ),
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
    required this.aoCopiar,
  });

  final PlanoDeInstancias plano;
  final VoidCallback aoNovoGrupo;
  final VoidCallback aoCopiar;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      FilledButton.icon(
        onPressed: aoNovoGrupo,
        icon: const Icon(Icons.create_new_folder_outlined, size: 18),
        label: const Text('Grupo'),
      ),
      const Spacer(),
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
