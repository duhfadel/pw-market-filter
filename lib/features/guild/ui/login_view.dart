import 'package:flutter/material.dart';

import '../../../core/result/result.dart';
import '../../../core/theme/pw_colors.dart';
import '../../../core/theme/pw_theme.dart';
import 'guild_view_model.dart';
import 'mensagens.dart';

/// The guild panel's front door: e-mail and senha, nada mais. Quem não tem
/// conta aqui não tem o que ver — não há "criar conta" nem "esqueci a
/// senha", porque as contas são criadas à mão por quem já tem acesso.
class LoginView extends StatefulWidget {
  const LoginView({required this.vm, super.key});

  final GuildViewModel vm;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    final r = await widget.vm.entrar(_email.text, _senha.text);
    if (!mounted) return;
    setState(() => _enviando = false);
    r.fold((_) {}, (f) {
      if (f is GuildFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagemDoGuildErro(f.erro))),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PWColors.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'NewAge',
                    style: TextStyle(
                      fontFamily: PWTheme.display,
                      color: PWColors.papel,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _email,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _senha,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Senha'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Obrigatório' : null,
                    onFieldSubmitted: (_) => _entrar(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _enviando ? null : _entrar,
                    style: const ButtonStyle(
                      minimumSize: WidgetStatePropertyAll(Size.fromHeight(44)),
                    ),
                    child: _enviando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: PWColors.surface,
                            ),
                          )
                        : const Text('Entrar'),
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
