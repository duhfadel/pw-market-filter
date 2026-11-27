import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/pw_colors.dart';
import '../../../domain/financeiro/lancamento.dart';
import '../../../domain/jogador.dart';
import '../fin_view_model.dart';
import '../rotulos_financeiro.dart';

/// Reads a typed value as TCC: every character that is not a digit is
/// dropped, which is what lets someone type `1.500` or `1500` and get the
/// same 1500 either way — the brief's "strip dots" taken one step further,
/// since a comma or a stray space is just as common a typo and costs
/// nothing extra to tolerate.
int? _parseValor(String texto) {
  final digitos = texto.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitos.isEmpty) return null;
  return int.tryParse(digitos);
}

/// The value field every dialog below shares — digits only, so the parse
/// above never has anything but digits and whatever separator somebody
/// typed to disregard.
class _CampoValor extends StatelessWidget {
  const _CampoValor({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    key: const Key('campo_valor'),
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    onChanged: (_) => onChanged(),
    style: const TextStyle(color: PWColors.papel),
    decoration: const InputDecoration(labelText: 'Valor (TCC)'),
  );
}

class _ChipsPote extends StatelessWidget {
  const _ChipsPote({required this.selecionado, required this.onSelect});

  final Pote selecionado;
  final ValueChanged<Pote> onSelect;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    children: [
      for (final p in Pote.values)
        ChoiceChip(
          key: Key('pote_${p.name}'),
          label: Text(rotuloPote(p)),
          selected: selecionado == p,
          onSelected: (_) => onSelect(p),
          labelStyle: TextStyle(
            fontSize: 13,
            color: selecionado == p ? PWColors.background : PWColors.papel,
          ),
          selectedColor: PWColors.accent,
          backgroundColor: PWColors.elevado,
          showCheckmark: false,
        ),
    ],
  );
}

class _ChipsCategoria extends StatelessWidget {
  const _ChipsCategoria({required this.selecionada, required this.onSelect});

  final CategoriaEntrada selecionada;
  final ValueChanged<CategoriaEntrada> onSelect;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final c in CategoriaEntrada.values)
        ChoiceChip(
          key: Key('categoria_${c.name}'),
          label: Text(rotuloCategoria(c)),
          selected: selecionada == c,
          onSelected: (_) => onSelect(c),
          labelStyle: TextStyle(
            fontSize: 13,
            color: selecionada == c ? PWColors.background : PWColors.papel,
          ),
          selectedColor: PWColors.accent,
          backgroundColor: PWColors.elevado,
          showCheckmark: false,
        ),
    ],
  );
}

class _RotuloCampo extends StatelessWidget {
  const _RotuloCampo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      texto,
      style: const TextStyle(color: PWColors.apagado, fontSize: 12),
    ),
  );
}

/// The `fixo` checkbox, shared by the two dialogs that offer it — a
/// recurring expense or staff payment, never an income or a transfer.
class _SeloFixo extends StatelessWidget {
  const _SeloFixo({required this.valor, required this.onChanged});

  final bool valor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    key: const Key('fixo'),
    value: valor,
    onChanged: (v) => onChanged(v ?? false),
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    dense: true,
    title: const Text(
      'Gasto fixo (mensal)',
      style: TextStyle(color: PWColors.papel, fontSize: 13),
    ),
  );
}

class _AcoesDialogo extends StatelessWidget {
  const _AcoesDialogo({
    required this.podeConfirmar,
    required this.onConfirmar,
    this.rotulo = 'Confirmar',
  });

  final bool podeConfirmar;
  final VoidCallback onConfirmar;
  final String rotulo;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      const SizedBox(width: 8),
      FilledButton(
        key: const Key('confirmar'),
        onPressed: podeConfirmar ? onConfirmar : null,
        child: Text(rotulo),
      ),
    ],
  );
}

AlertDialog _casco({required String titulo, required Widget content}) =>
    AlertDialog(
      backgroundColor: PWColors.surface,
      title: Text(titulo, style: const TextStyle(color: PWColors.papel)),
      content: SingleChildScrollView(child: content),
    );

/// Opens "Adicionar dinheiro": a value, which pot it lands in, what kind of
/// income it is, and an optional note.
void mostrarDialogoEntrada(BuildContext context, FinanceiroViewModel vm) {
  showDialog<void>(
    context: context,
    builder: (_) => _DialogoEntrada(vm: vm),
  );
}

class _DialogoEntrada extends StatefulWidget {
  const _DialogoEntrada({required this.vm});

  final FinanceiroViewModel vm;

  @override
  State<_DialogoEntrada> createState() => _DialogoEntradaState();
}

class _DialogoEntradaState extends State<_DialogoEntrada> {
  final _valor = TextEditingController();
  final _obs = TextEditingController();
  Pote _pote = Pote.caixa;
  CategoriaEntrada _categoria = CategoriaEntrada.guildAtiva;

  @override
  void dispose() {
    _valor.dispose();
    _obs.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final valor = _parseValor(_valor.text);
    if (valor == null || valor <= 0) return;
    await widget.vm.adicionar(
      Lancamento(
        id: '',
        tipo: TipoLancamento.entrada,
        pote: _pote,
        valor: valor,
        categoria: _categoria,
        descricao: _obs.text.trim().isEmpty ? null : _obs.text.trim(),
        data: DateTime.now(),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final valido = (_parseValor(_valor.text) ?? 0) > 0;
    return _casco(
      titulo: 'Adicionar dinheiro',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CampoValor(controller: _valor, onChanged: () => setState(() {})),
          const SizedBox(height: 14),
          const _RotuloCampo('Pote'),
          _ChipsPote(
            selecionado: _pote,
            onSelect: (p) => setState(() => _pote = p),
          ),
          const SizedBox(height: 14),
          const _RotuloCampo('Categoria'),
          _ChipsCategoria(
            selecionada: _categoria,
            onSelect: (c) => setState(() => _categoria = c),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _obs,
            style: const TextStyle(color: PWColors.papel),
            decoration: const InputDecoration(
              labelText: 'Observação (opcional)',
            ),
          ),
          const SizedBox(height: 16),
          _AcoesDialogo(
            podeConfirmar: valido,
            onConfirmar: _confirmar,
            rotulo: 'Adicionar',
          ),
        ],
      ),
    );
  }
}

/// Opens "Adicionar despesa": a value, which pot it leaves, and a
/// description that cannot be empty — a despesa with no description tells
/// nobody what the guild's money went to.
void mostrarDialogoDespesa(BuildContext context, FinanceiroViewModel vm) {
  showDialog<void>(
    context: context,
    builder: (_) => _DialogoDespesa(vm: vm),
  );
}

class _DialogoDespesa extends StatefulWidget {
  const _DialogoDespesa({required this.vm});

  final FinanceiroViewModel vm;

  @override
  State<_DialogoDespesa> createState() => _DialogoDespesaState();
}

class _DialogoDespesaState extends State<_DialogoDespesa> {
  final _valor = TextEditingController();
  final _descricao = TextEditingController();
  Pote _pote = Pote.caixa;
  bool _fixo = false;

  @override
  void dispose() {
    _valor.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final valor = _parseValor(_valor.text);
    final descricao = _descricao.text.trim();
    if (valor == null || valor <= 0 || descricao.isEmpty) return;
    await widget.vm.adicionar(
      Lancamento(
        id: '',
        tipo: TipoLancamento.despesa,
        pote: _pote,
        valor: valor,
        descricao: descricao,
        fixo: _fixo,
        data: DateTime.now(),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final valido =
        (_parseValor(_valor.text) ?? 0) > 0 &&
        _descricao.text.trim().isNotEmpty;
    return _casco(
      titulo: 'Adicionar despesa',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CampoValor(controller: _valor, onChanged: () => setState(() {})),
          const SizedBox(height: 14),
          const _RotuloCampo('Pote'),
          _ChipsPote(
            selecionado: _pote,
            onSelect: (p) => setState(() => _pote = p),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('campo_descricao'),
            controller: _descricao,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: PWColors.papel),
            decoration: const InputDecoration(labelText: 'Descrição'),
          ),
          const SizedBox(height: 4),
          _SeloFixo(valor: _fixo, onChanged: (v) => setState(() => _fixo = v)),
          const SizedBox(height: 12),
          _AcoesDialogo(
            podeConfirmar: valido,
            onConfirmar: _confirmar,
            rotulo: 'Adicionar',
          ),
        ],
      ),
    );
  }
}

/// Opens "Pagar staff": a value, which pot pays it, who from the roster is
/// being paid, an optional description and the same `fixo` selo a recurring
/// despesa carries.
void mostrarDialogoPagamentoStaff(
  BuildContext context,
  FinanceiroViewModel vm,
  List<Jogador> jogadores,
) {
  showDialog<void>(
    context: context,
    builder: (_) => _DialogoPagamentoStaff(vm: vm, jogadores: jogadores),
  );
}

class _DialogoPagamentoStaff extends StatefulWidget {
  const _DialogoPagamentoStaff({required this.vm, required this.jogadores});

  final FinanceiroViewModel vm;
  final List<Jogador> jogadores;

  @override
  State<_DialogoPagamentoStaff> createState() => _DialogoPagamentoStaffState();
}

class _DialogoPagamentoStaffState extends State<_DialogoPagamentoStaff> {
  final _valor = TextEditingController();
  final _descricao = TextEditingController();
  Pote _pote = Pote.caixa;
  bool _fixo = false;
  String? _membroId;

  late final List<Jogador> _ordenados = [...widget.jogadores]
    ..sort((a, b) => a.nome.compareTo(b.nome));

  @override
  void dispose() {
    _valor.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final valor = _parseValor(_valor.text);
    final membro = _membroId;
    if (valor == null || valor <= 0 || membro == null) return;
    await widget.vm.adicionar(
      Lancamento(
        id: '',
        tipo: TipoLancamento.pagamentoStaff,
        pote: _pote,
        valor: valor,
        membro: membro,
        descricao: _descricao.text.trim().isEmpty
            ? null
            : _descricao.text.trim(),
        fixo: _fixo,
        data: DateTime.now(),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final valido = (_parseValor(_valor.text) ?? 0) > 0 && _membroId != null;
    return _casco(
      titulo: 'Pagar staff',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CampoValor(controller: _valor, onChanged: () => setState(() {})),
          const SizedBox(height: 14),
          const _RotuloCampo('Pote'),
          _ChipsPote(
            selecionado: _pote,
            onSelect: (p) => setState(() => _pote = p),
          ),
          const SizedBox(height: 14),
          const _RotuloCampo('Membro'),
          if (_ordenados.isEmpty)
            const Text(
              'Nenhum jogador no roster.',
              style: TextStyle(color: PWColors.apagado, fontSize: 12),
            )
          else
            DropdownButtonFormField<String>(
              key: const Key('campo_membro'),
              initialValue: _membroId,
              isExpanded: true,
              dropdownColor: PWColors.surfaceRaised,
              decoration: const InputDecoration(labelText: 'Escolher membro'),
              items: [
                for (final j in _ordenados)
                  DropdownMenuItem(
                    value: j.id,
                    child: Text(
                      j.nome,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: PWColors.papel),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _membroId = v),
            ),
          const SizedBox(height: 14),
          TextField(
            controller: _descricao,
            style: const TextStyle(color: PWColors.papel),
            decoration: const InputDecoration(
              labelText: 'Descrição (opcional)',
            ),
          ),
          const SizedBox(height: 4),
          _SeloFixo(valor: _fixo, onChanged: (v) => setState(() => _fixo = v)),
          const SizedBox(height: 12),
          _AcoesDialogo(
            podeConfirmar: valido,
            onConfirmar: _confirmar,
            rotulo: 'Pagar',
          ),
        ],
      ),
    );
  }
}

/// Opens "Transferir": a value moves from one pot to the other. With only
/// two pots, the destination is never a choice of its own — it is whichever
/// one the origin is not — so the dialog offers an origin and flips the
/// destination automatically, which is what rules out the one invalid state
/// (the same pot on both sides) by construction rather than by validation.
void mostrarDialogoTransferencia(BuildContext context, FinanceiroViewModel vm) {
  showDialog<void>(
    context: context,
    builder: (_) => _DialogoTransferencia(vm: vm),
  );
}

class _DialogoTransferencia extends StatefulWidget {
  const _DialogoTransferencia({required this.vm});

  final FinanceiroViewModel vm;

  @override
  State<_DialogoTransferencia> createState() => _DialogoTransferenciaState();
}

class _DialogoTransferenciaState extends State<_DialogoTransferencia> {
  final _valor = TextEditingController();
  Pote _origem = Pote.caixa;

  Pote get _destino => _origem == Pote.caixa ? Pote.reserva : Pote.caixa;

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final valor = _parseValor(_valor.text);
    if (valor == null || valor <= 0) return;
    await widget.vm.adicionar(
      Lancamento(
        id: '',
        tipo: TipoLancamento.transferencia,
        pote: _origem,
        poteDestino: _destino,
        valor: valor,
        data: DateTime.now(),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final valido = (_parseValor(_valor.text) ?? 0) > 0;
    return _casco(
      titulo: 'Transferir',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CampoValor(controller: _valor, onChanged: () => setState(() {})),
          const SizedBox(height: 14),
          const _RotuloCampo('Origem'),
          _ChipsPote(
            selecionado: _origem,
            onSelect: (p) => setState(() => _origem = p),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Destino: ',
                style: TextStyle(color: PWColors.apagado, fontSize: 13),
              ),
              Text(
                rotuloPote(_destino),
                key: const Key('transferencia_destino'),
                style: const TextStyle(
                  color: PWColors.papel,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AcoesDialogo(
            podeConfirmar: valido,
            onConfirmar: _confirmar,
            rotulo: 'Transferir',
          ),
        ],
      ),
    );
  }
}
