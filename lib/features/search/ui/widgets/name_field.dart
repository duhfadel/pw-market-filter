import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';

/// *Filtrar por nome* — a fragment of the character's own nickname.
///
/// The same trap `NumberField` documents applies here and bites harder:
/// `TextFormField(initialValue: …)` reads its argument once, so a field
/// written that way would still show `Leite` after *limpar tudo* had emptied
/// the query, and the screen would name a filter that is no longer in force.
/// The controller is re-synced only when the value coming in stops agreeing
/// with the text on screen, so typing is never interrupted.
///
/// **The comparison is against the trimmed value, not the raw text.** A
/// trailing space the visitor just typed means the query is unchanged, and
/// rewriting the field there would eat the space as it was typed and jump the
/// caret to the end.
class NameField extends StatefulWidget {
  const NameField({required this.value, required this.onChanged, super.key});

  /// `null` or blank means nothing is being asked.
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  State<NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<NameField> {
  late final _controller = TextEditingController(text: widget.value ?? '');

  @override
  void didUpdateWidget(NameField oldWidget) {
    super.didUpdateWidget(oldWidget);

    final incoming = widget.value ?? '';
    if (_controller.text.trim() != incoming.trim()) {
      _controller.text = incoming;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      labelText: 'Filtrar por nome',
      hintText: 'trecho do apelido',
      prefixIcon: const Icon(Icons.search, size: 18, color: PWColors.textMuted),
      // A way out that does not cost a trip to the chips above, because this
      // is the one control somebody uses twice in a row — type a name, read
      // the grid, try another.
      suffixIcon: (widget.value ?? '').isEmpty
          ? null
          : IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: PWColors.textMuted,
              tooltip: 'Limpar o nome',
              onPressed: () => widget.onChanged(null),
            ),
    ),
    onChanged: (raw) => widget.onChanged(raw.trim().isEmpty ? null : raw),
  );
}
