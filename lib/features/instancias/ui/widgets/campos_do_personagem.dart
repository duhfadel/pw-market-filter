import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../domain/campo_personalizado.dart';
import '../../domain/personagem_de_instancia.dart';
import '../../domain/plano_de_instancias.dart';

/// As fichas dos campos personalizados, numa linha por baixo do nome de um
/// personagem.
///
/// **Fichas e não colunas, e isto foi uma decisão de layout.** A tabela de
/// números já é larga; cada campo novo como coluna estouraria a largura assim
/// que houvesse alguns. Fichas numa linha que quebra para a seguinte escalam
/// para muitos campos sem partir a tabela, e vivem igual no largo e no cartão.
///
/// A marcação e a escolha são fichas (`Wrap`, porque quebram); a nota é texto
/// e vai numa linha própria por baixo, porque é comprida e não cabe numa
/// ficha.
class CamposDoPersonagem extends StatelessWidget {
  const CamposDoPersonagem({
    required this.campos,
    required this.quem,
    required this.onde,
    required this.aoDefinir,
    super.key,
  });

  final List<CampoPersonalizado> campos;
  final PersonagemDeInstancia quem;
  final Morada onde;

  /// Define (ou limpa, com `null`) o valor de um campo neste personagem.
  final void Function(Morada, String campoId, String? valor) aoDefinir;

  @override
  Widget build(BuildContext context) {
    if (campos.isEmpty) return const SizedBox.shrink();

    final fichas = campos
        .where((c) => c.tipo != CampoTipo.nota)
        .toList(growable: false);
    final notas = campos
        .where((c) => c.tipo == CampoTipo.nota)
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fichas.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in fichas)
                  if (c.tipo == CampoTipo.marcacao)
                    _ChipMarcacao(
                      campo: c,
                      ligado: quem.marcado(c.id),
                      aoTocar: () => aoDefinir(
                        onde,
                        c.id,
                        quem.marcado(c.id) ? null : '1',
                      ),
                    )
                  else
                    _ChipEscolha(
                      campo: c,
                      valor: quem.extra(c.id),
                      aoEscolher: (v) => aoDefinir(onde, c.id, v),
                    ),
              ],
            ),
          for (final c in notas)
            _LinhaNota(
              campo: c,
              valor: quem.extra(c.id),
              aoMudar: (v) => aoDefinir(onde, c.id, v),
            ),
        ],
      ),
    );
  }
}

/// Uma marcação: liga/desliga ao toque. Dourada quando ligada.
class _ChipMarcacao extends StatelessWidget {
  const _ChipMarcacao({
    required this.campo,
    required this.ligado,
    required this.aoTocar,
  });

  final CampoPersonalizado campo;
  final bool ligado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: aoTocar,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: ligado ? PWColors.accent.withValues(alpha: 0.14) : null,
        border: Border.all(color: ligado ? PWColors.accent : PWColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ligado ? Icons.check_box : Icons.check_box_outline_blank,
            size: 15,
            color: ligado ? PWColors.accent : PWColors.textMuted,
          ),
          const SizedBox(width: 5),
          Text(
            campo.nome,
            style: TextStyle(
              fontSize: 12,
              color: ligado ? PWColors.accent : PWColors.textMuted,
              fontWeight: ligado ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Uma escolha: mostra o valor atual e abre as opções ao toque.
class _ChipEscolha extends StatelessWidget {
  const _ChipEscolha({
    required this.campo,
    required this.valor,
    required this.aoEscolher,
  });

  final CampoPersonalizado campo;
  final String? valor;

  /// Recebe a opção escolhida, ou `null` para limpar.
  final void Function(String?) aoEscolher;

  @override
  Widget build(BuildContext context) {
    final escolhido = valor != null && campo.opcoes.contains(valor);
    return PopupMenuButton<String>(
      tooltip: campo.nome,
      onSelected: (v) => aoEscolher(v.isEmpty ? null : v),
      itemBuilder: (_) => [
        for (final o in campo.opcoes) PopupMenuItem(value: o, child: Text(o)),
        const PopupMenuDivider(),
        const PopupMenuItem(value: '', child: Text('— limpar —')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: escolhido ? PWColors.surfaceRaised : null,
          border: Border.all(
            color: escolhido ? PWColors.accent : PWColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${campo.nome}: ',
              style: const TextStyle(color: PWColors.textMuted, fontSize: 12),
            ),
            Text(
              escolhido ? valor! : '—',
              style: TextStyle(
                fontSize: 12,
                color: escolhido ? PWColors.accent : PWColors.textMuted,
                fontWeight: escolhido ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: PWColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Uma nota: o nome do campo e o texto, numa linha própria. Toca para editar.
class _LinhaNota extends StatelessWidget {
  const _LinhaNota({
    required this.campo,
    required this.valor,
    required this.aoMudar,
  });

  final CampoPersonalizado campo;
  final String? valor;
  final void Function(String?) aoMudar;

  Future<void> _editar(BuildContext context) async {
    final c = TextEditingController(text: valor ?? '');
    final novo = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: PWColors.surface,
        title: Text(campo.nome),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLines: null,
          decoration: InputDecoration(hintText: campo.nome),
        ),
        actions: [
          // Sentinela de um espaço: o diálogo devolve ' ' para dizer *limpar*,
          // distinto de `null` que é *cancelar*.
          TextButton(
            onPressed: () => Navigator.of(d).pop(' '),
            child: const Text('Limpar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(d).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(d).pop(c.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (novo == null) return;
    aoMudar(novo == ' ' ? null : novo);
  }

  @override
  Widget build(BuildContext context) {
    final temTexto = valor != null && valor!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: InkWell(
        onTap: () => _editar(context),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.sticky_note_2_outlined,
                size: 14,
                color: PWColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${campo.nome}: ',
                        style: const TextStyle(
                          color: PWColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: temTexto ? valor : 'tocar para escrever',
                        style: TextStyle(
                          color: temTexto ? PWColors.text : PWColors.textMuted,
                          fontSize: 12,
                          fontStyle: temTexto ? null : FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
