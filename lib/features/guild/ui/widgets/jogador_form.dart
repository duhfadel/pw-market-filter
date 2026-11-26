import 'package:flutter/material.dart';

import '../../../../core/result/result.dart';
import '../../../../core/theme/pw_colors.dart';
import '../../domain/jogador.dart';
import '../escolher_imagem_io.dart'
    if (dart.library.js_interop) '../escolher_imagem_web.dart';
import '../imagem_escolhida.dart';
import '../mensagens.dart';
import '../roster_view_model.dart';

const int _limiteBytes = 512 * 1024;

/// The "add a player" dialog. **The print is the primary action** — the
/// product's whole point is "staff attaches the sheet, the stats are
/// transcribed later" — so attaching it sits right under the required name
/// field, in the spot a form usually reserves for what matters most. The
/// thirty-odd stat fields are the opposite of urgent here: collapsed behind
/// an optional expander, closed by default, for the rare case someone wants
/// to type a couple of numbers by hand instead of waiting for the print to be
/// read.
class JogadorForm extends StatefulWidget {
  const JogadorForm({required this.vm, super.key});

  /// Talks to the repository directly — unlike the stat-only version this
  /// replaces, saving here also uploads a file, and threading that result
  /// back out through a callback would just move the same decision one layer
  /// up for no benefit.
  final RosterViewModel vm;

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

  ImagemEscolhida? _imagem;
  bool _salvando = false;

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

  bool get _printMuitoGrande => (_imagem?.bytes.length ?? 0) > _limiteBytes;

  Future<void> _anexarPrint() async {
    final img = await escolherImagem();
    if (img == null) return;
    setState(() => _imagem = img);
  }

  String _nickSanitizado(String nome) {
    final limpo = nome.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '');
    return limpo.isEmpty ? 'jogador' : limpo;
  }

  String _extDe(String nomeArquivo) {
    final i = nomeArquivo.lastIndexOf('.');
    if (i == -1 || i == nomeArquivo.length - 1) return 'png';
    return nomeArquivo.substring(i + 1).toLowerCase();
  }

  Future<void> _confirmar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_printMuitoGrande) return;

    final img = _imagem;
    // The print is what the product is built around: attaching one leaves
    // the stats for the transcription that happens afterwards, and typing
    // them by hand (with no print) is the one case that counts as done now.
    final jogador = Jogador(
      id: '',
      nome: _nome.text.trim(),
      classe: _vazioParaNulo(_classe.text),
      limite: _vazioParaNulo(_limite.text),
      nivel: int.tryParse(_nivel.text.trim()),
      nivelAtaque: int.tryParse(_nivelAtaque.text.trim()),
      hp: int.tryParse(_hp.text.trim()),
      critico: _vazioParaNulo(_critico.text),
      status: img != null ? 'pendente' : 'transcrito',
    );

    String? nomeArquivo;
    if (img != null) {
      final nick = _nickSanitizado(_nome.text.trim());
      final ext = _extDe(img.nome);
      nomeArquivo = '${nick}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    }

    setState(() => _salvando = true);
    final ok = await widget.vm.adicionar(jogador, print: img?.bytes, nomeArquivo: nomeArquivo);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _salvando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagemDoGuildErro(img != null ? GuildErro.upload : GuildErro.salvar)),
      ),
    );
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nome,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nome *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _anexarPrint,
                icon: const Icon(Icons.image_outlined, color: PWColors.accent),
                label: Text(
                  _imagem == null ? 'Anexar print da ficha' : 'Trocar print',
                  style: const TextStyle(color: PWColors.accent),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: PWColors.accent),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Anexe o print da ficha — os atributos são preenchidos depois.',
                style: const TextStyle(color: PWColors.textMuted, fontSize: 12),
              ),
              if (_imagem != null) ...[
                const SizedBox(height: 6),
                Text(
                  '${_imagem!.nome} · ${(_imagem!.bytes.length / 1024).toStringAsFixed(1)} KB',
                  style: TextStyle(
                    color: _printMuitoGrande ? PWColors.danger : PWColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (_printMuitoGrande)
                  const Text(
                    'máx. 512 KB',
                    style: TextStyle(color: PWColors.danger, fontSize: 12),
                  ),
              ],
              const SizedBox(height: 16),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: const Text(
                    'Preencher manualmente (opcional)',
                    style: TextStyle(color: PWColors.textMuted, fontSize: 13),
                  ),
                  tilePadding: EdgeInsets.zero,
                  initiallyExpanded: false,
                  children: [
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: (_salvando || _printMuitoGrande) ? null : _confirmar,
          child: _salvando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Adicionar'),
        ),
      ],
    );
  }
}
