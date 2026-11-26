import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../domain/jogador.dart';

/// The "add a player" dialog — name only is required. Everything else is a
/// stat somebody reads off a sheet print, which is the next task, so for now
/// it is "add first, the rest of the fields later": only a handful of plain
/// stats are offered, and they are all optional.
class JogadorForm extends StatefulWidget {
  const JogadorForm({required this.onSalvar, super.key});

  /// Builds the [Jogador] and hands it to the caller, who talks to the
  /// view-model and decides what the dialog does next (close it, or show a
  /// failure) — this widget only collects the fields.
  final void Function(Jogador jogador) onSalvar;

  @override
  State<JogadorForm> createState() => _JogadorFormState();
}

class _JogadorFormState extends State<JogadorForm> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _classe = TextEditingController();
  final _limite = TextEditingController();
  final _nivel = TextEditingController();
  final _nivelAtaque = TextEditingController();
  final _hp = TextEditingController();
  final _critico = TextEditingController();

  @override
  void dispose() {
    _nome.dispose();
    _classe.dispose();
    _limite.dispose();
    _nivel.dispose();
    _nivelAtaque.dispose();
    _hp.dispose();
    _critico.dispose();
    super.dispose();
  }

  String? _vazioParaNulo(String texto) => texto.trim().isEmpty ? null : texto.trim();

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;
    final jogador = Jogador(
      id: '',
      nome: _nome.text.trim(),
      classe: _vazioParaNulo(_classe.text),
      limite: _vazioParaNulo(_limite.text),
      nivel: int.tryParse(_nivel.text.trim()),
      nivelAtaque: int.tryParse(_nivelAtaque.text.trim()),
      hp: int.tryParse(_hp.text.trim()),
      critico: _vazioParaNulo(_critico.text),
    );
    widget.onSalvar(jogador);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: PWColors.surface,
      title: const Text('Adicionar jogador', style: TextStyle(color: PWColors.papel)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nome,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nome *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              TextFormField(
                controller: _classe,
                decoration: const InputDecoration(labelText: 'Classe'),
              ),
              TextFormField(
                controller: _limite,
                decoration: const InputDecoration(labelText: 'Limite'),
              ),
              TextFormField(
                controller: _nivel,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nível'),
              ),
              TextFormField(
                controller: _nivelAtaque,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nível de ataque'),
              ),
              TextFormField(
                controller: _hp,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'HP'),
              ),
              TextFormField(
                controller: _critico,
                decoration: const InputDecoration(labelText: 'Crítico'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _confirmar, child: const Text('Adicionar')),
      ],
    );
  }
}
