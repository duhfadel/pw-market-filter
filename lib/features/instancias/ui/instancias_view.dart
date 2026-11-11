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

/// O organizador de instâncias: quantas entradas e chaves cada personagem tem.
///
/// **É a primeira ferramenta deste site que escreve em vez de ler.** Tudo o
/// resto parte de uma recolha — o mercado, os registos, os vídeos — e
/// responde sobre o jogo. Esta não sabe nada: a lista é de quem está a ler,
/// escrita à mão, e o site nunca a viu nem a pode verificar.
///
/// **Por isso ela vive no navegador de quem escreve.** Não há conta, não há
/// servidor nosso no meio e não guardamos dados de ninguém. O preço é que é
/// por aparelho — e é por isso que existe o botão de link, que é a única rede
/// contra trocar de telemóvel ou limpar o navegador.
class InstanciasView extends StatelessWidget {
  const InstanciasView({super.key, this.query = const {}});

  /// O que o endereço trouxe. Uma lista no link ganha ao que está gravado —
  /// ver `InstanciasViewModel.carregar`.
  final Map<String, List<String>> query;

  /// Abaixo disto a tabela aperta — mas nunca perde uma coluna. São quatro
  /// números e eles são a tabela; empilhá-los daria quatro linhas por
  /// personagem e acabava-se a comparação, que é a razão de isto existir.
  static const _telaEstreita = 560.0;

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

  Future<void> _adicionar(BuildContext context) async {
    final vm = context.read<InstanciasViewModel>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: PWColors.surface,
      isScrollControlled: true,
      builder: (folha) => EscolherClasse(
        aoConfirmar: (nome, classe) {
          vm.adicionar(nome, classe);
          Navigator.of(folha).pop();
        },
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
  Widget build(BuildContext context) => Center(
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
            aoAdicionar: () => unawaited(_adicionar(context)),
            aoCopiar: () => unawaited(_copiarLink(context)),
          ),
          const SizedBox(height: 14),
          if (plano.vazio)
            const _Vazio()
          else
            TabelaDeInstancias(
              plano: plano,
              compacto: compacto,
              aoOrdenar: context.read<InstanciasViewModel>().ordenarPor,
              aoContar: context.read<InstanciasViewModel>().contar,
              aoRenomear: context.read<InstanciasViewModel>().renomear,
              aoRemover: context.read<InstanciasViewModel>().remover,
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
        'Escreva os seus personagens e quantas Relíquias Maravilha e Chaves '
        'da Sorte cada um tem. Toque no cabeçalho de uma coluna para ver '
        'quem tem mais e quem tem menos.',
        style: TextStyle(color: PWColors.textMuted, fontSize: 14, height: 1.5),
      ),
    ],
  );
}

class _Acoes extends StatelessWidget {
  const _Acoes({
    required this.plano,
    required this.aoAdicionar,
    required this.aoCopiar,
  });

  final PlanoDeInstancias plano;
  final VoidCallback aoAdicionar;
  final VoidCallback aoCopiar;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      FilledButton.icon(
        onPressed: aoAdicionar,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Personagem'),
      ),
      const Spacer(),
      // Só com alguém na lista: um botão que copia um link vazio promete
      // guardar o que ainda não existe.
      if (!plano.vazio)
        TextButton.icon(
          onPressed: aoCopiar,
          icon: const Icon(Icons.link, size: 17),
          label: const Text('Copiar link'),
        ),
    ],
  );
}

class _Vazio extends StatelessWidget {
  const _Vazio();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
    decoration: BoxDecoration(
      color: PWColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: PWColors.border),
    ),
    child: const Column(
      children: [
        Icon(Icons.group_add_outlined, size: 34, color: PWColors.textMuted),
        SizedBox(height: 12),
        Text(
          'Nenhum personagem ainda.',
          style: TextStyle(
            color: PWColors.text,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Toque em Personagem para escrever o primeiro.',
          textAlign: TextAlign.center,
          style: TextStyle(color: PWColors.textMuted, fontSize: 13),
        ),
      ],
    ),
  );
}

/// Diz onde a lista está guardada, e isto não é um detalhe técnico.
///
/// **Quem não sabe que é por aparelho descobre a perder tudo.** Uma
/// ferramenta sem conta que parece ter conta é uma promessa que o site não
/// fez e não pode cumprir — por isso está escrito na tela, ao lado do botão
/// que resolve o problema, e não num rodapé.
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
