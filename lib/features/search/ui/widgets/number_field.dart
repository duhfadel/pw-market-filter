import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A numeric field that survives a rebuild and still obeys the state.
///
/// `TextFormField(initialValue: …)` only reads its argument on the first
/// build, so a field written that way keeps whatever was typed after
/// "limpar tudo" empties the query — the screen then shows a filter that is no
/// longer in force. The controller here is re-synced whenever the value coming
/// in stops agreeing with the text on screen, and only then, so typing is
/// never interrupted.
class NumberField extends StatefulWidget {
  const NumberField({
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    super.key,
  });

  /// `null` means "no limit" — which is not the same as zero.
  final int? value;
  final ValueChanged<int?> onChanged;
  final String? label;
  final String? hint;

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  late final _controller = TextEditingController(text: _textFor(widget.value));

  static String _textFor(int? value) => value?.toString() ?? '';

  @override
  void didUpdateWidget(NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);

    final expected = _textFor(widget.value);
    // Comparing against the parsed text, not against the old widget, is what
    // keeps the cursor still while the user types: `07` and `7` are the same
    // value, and rewriting the field would jump the caret to the end.
    final onScreen = _controller.text.isEmpty
        ? null
        : int.tryParse(_controller.text);
    if (onScreen != widget.value) _controller.text = expected;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: widget.label, hintText: widget.hint),
    onChanged: (raw) =>
        widget.onChanged(raw.isEmpty ? null : int.tryParse(raw)),
  );
}
