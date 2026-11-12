import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/widgets/game_icon.dart';
import '../../../../market/ocupacoes.dart';

/// A folha de adicionar um personagem: as dezassete classes e um nome.
///
/// **A classe escolhe-se pelo ícone e não numa lista de nomes.** Quem joga
/// reconhece o símbolo antes de ler a palavra, e dezassete nomes numa lista
/// suspensa são dezassete linhas para percorrer de cada vez que se acrescenta
/// alguém. A grelha mostra as dezassete de uma vez.
///
/// **O botão só acende com nome escrito.** Uma linha sem nome é uma linha que
/// ninguém identifica na própria tabela — a mesma regra que o leitor do link
/// aplica, e aqui dita em voz alta em vez de recusada em silêncio.
class EscolherClasse extends StatefulWidget {
  const EscolherClasse({required this.aoConfirmar, super.key});

  /// Recebe o nome e a classe. Fechar a folha é com quem chamou.
  final void Function(String nome, String classe) aoConfirmar;

  @override
  State<EscolherClasse> createState() => _EscolherClasseState();
}

class _EscolherClasseState extends State<EscolherClasse> {
  final _nome = TextEditingController();
  String _classe = classesDoJogo.first;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (_nome.text.trim().isEmpty) return;
    widget.aoConfirmar(_nome.text, _classe);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      18,
      18,
      18,
      18 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Novo personagem',
          style: TextStyle(
            color: PWColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _nome,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _confirmar(),
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: PWColors.text),
          decoration: const InputDecoration(
            labelText: 'Nome do personagem',
            hintText: 'como ele se chama no jogo',
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'CLASSE',
          style: TextStyle(
            color: PWColors.textMuted,
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final classe in classesDoJogo)
              _Classe(
                classe: classe,
                escolhida: classe == _classe,
                aoTocar: () => setState(() => _classe = classe),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _nome.text.trim().isEmpty ? null : _confirmar,
            child: const Text('Adicionar'),
          ),
        ),
      ],
    ),
  );
}

/// Um ícone de classe com o nome por baixo.
///
/// O nome fica, apesar de o ícone ser o que se reconhece: dezassete símbolos
/// sem legenda são um teste de memória, e quem joga uma classe não
/// necessariamente reconhece as outras dezasseis.
class _Classe extends StatelessWidget {
  const _Classe({
    required this.classe,
    required this.escolhida,
    required this.aoTocar,
  });

  final String classe;
  final bool escolhida;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: escolhida,
    label: classe,
    child: InkWell(
      onTap: aoTocar,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: escolhida ? PWColors.surfaceRaised : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: escolhida ? PWColors.accent : PWColors.border,
            width: escolhida ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClassIcon(ocupacaoDaClasse[classe] ?? -1, size: 34),
            const SizedBox(height: 5),
            Text(
              classe,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.15,
                color: escolhida ? PWColors.accent : PWColors.textMuted,
                fontWeight: escolhida ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
