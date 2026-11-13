import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../domain/campo_personalizado.dart';
import '../../domain/plano_de_instancias.dart';
import '../instancias_view_model.dart';

/// A folha de gerir os campos personalizados: criar um novo, e ver/apagar os
/// que já existem.
///
/// **Um sítio só para os campos, e não um botão por tipo.** Três botões
/// separados — marcação, escolha, nota — espalhariam a mesma ideia; aqui
/// escolhe-se o tipo dentro da mesma folha, e a lista por baixo torna claro
/// que os campos são globais (os mesmos em todos os personagens).
class GerirCampos extends StatelessWidget {
  const GerirCampos({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<InstanciasViewModel, PlanoDeInstancias>(
    builder: (context, plano) => Padding(
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
            'Campos personalizados',
            style: TextStyle(
              color: PWColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Colunas de informação suas, iguais em todos os personagens: '
            'uma marcação (sim/não), uma escolha entre opções, ou uma nota.',
            style: TextStyle(color: PWColors.textMuted, fontSize: 12.5),
          ),
          const SizedBox(height: 16),
          if (plano.campos.isNotEmpty) ...[
            for (final c in plano.campos)
              _LinhaDoCampo(
                campo: c,
                aoApagar: () =>
                    context.read<InstanciasViewModel>().removerCampo(c.id),
              ),
            const Divider(height: 24),
          ],
          const _NovoCampo(),
        ],
      ),
    ),
  );
}

String _rotuloDoTipo(CampoTipo t) => switch (t) {
  CampoTipo.marcacao => 'Marcação',
  CampoTipo.escolha => 'Escolha',
  CampoTipo.nota => 'Nota',
};

IconData _iconeDoTipo(CampoTipo t) => switch (t) {
  CampoTipo.marcacao => Icons.check_box_outlined,
  CampoTipo.escolha => Icons.radio_button_checked,
  CampoTipo.nota => Icons.sticky_note_2_outlined,
};

class _LinhaDoCampo extends StatelessWidget {
  const _LinhaDoCampo({required this.campo, required this.aoApagar});

  final CampoPersonalizado campo;
  final VoidCallback aoApagar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(_iconeDoTipo(campo.tipo), size: 18, color: PWColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                campo.nome,
                style: const TextStyle(
                  color: PWColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                campo.tipo == CampoTipo.escolha
                    ? '${_rotuloDoTipo(campo.tipo)} · ${campo.opcoes.join(', ')}'
                    : _rotuloDoTipo(campo.tipo),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PWColors.textMuted,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: aoApagar,
          iconSize: 18,
          tooltip: 'Apagar o campo "${campo.nome}" de todos os personagens',
          icon: const Icon(Icons.delete_outline, color: PWColors.textMuted),
        ),
      ],
    ),
  );
}

class _NovoCampo extends StatefulWidget {
  const _NovoCampo();

  @override
  State<_NovoCampo> createState() => _NovoCampoState();
}

class _NovoCampoState extends State<_NovoCampo> {
  final _nome = TextEditingController();
  final _opcoes = TextEditingController();
  CampoTipo _tipo = CampoTipo.marcacao;

  @override
  void dispose() {
    _nome.dispose();
    _opcoes.dispose();
    super.dispose();
  }

  bool get _valido {
    if (_nome.text.trim().isEmpty) return false;
    if (_tipo == CampoTipo.escolha) return _opcoesLimpas.isNotEmpty;
    return true;
  }

  List<String> get _opcoesLimpas => [
    for (final o in _opcoes.text.split(','))
      if (o.trim().isNotEmpty) o.trim(),
  ];

  void _criar() {
    if (!_valido) return;
    context.read<InstanciasViewModel>().adicionarCampo(
      _nome.text,
      _tipo,
      opcoes: _tipo == CampoTipo.escolha ? _opcoesLimpas : const [],
    );
    _nome.clear();
    _opcoes.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'NOVO CAMPO',
        style: TextStyle(
          color: PWColors.textMuted,
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _nome,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: PWColors.text),
        // Um nome curto vira a coluna e encurta o link: a marcação e a
        // escolha ganham uma coluna com este nome no cabeçalho, e um nome
        // grande deixa a coluna larga.
        decoration: const InputDecoration(
          labelText: 'Nome curto do campo',
          hintText: 'TW, Boss, Status…',
          helperText: 'Vira o cabeçalho da coluna — curto fica melhor.',
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        children: [
          for (final t in CampoTipo.values)
            ChoiceChip(
              label: Text(_rotuloDoTipo(t)),
              avatar: Icon(
                _iconeDoTipo(t),
                size: 16,
                color: _tipo == t ? PWColors.background : PWColors.textMuted,
              ),
              selected: _tipo == t,
              onSelected: (_) => setState(() => _tipo = t),
            ),
        ],
      ),
      if (_tipo == CampoTipo.escolha) ...[
        const SizedBox(height: 12),
        TextField(
          controller: _opcoes,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: PWColors.text),
          decoration: const InputDecoration(
            labelText: 'Opções, separadas por vírgula',
            hintText: 'Ativo, Vendendo, Parado',
          ),
        ),
      ],
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          onPressed: _valido ? _criar : null,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Criar campo'),
        ),
      ),
    ],
  );
}
