import 'package:flutter/widgets.dart';

/// Inserts [text] at the current selection of [controller].
void insertAtSelection(
  TextEditingController controller,
  String text,
  TextRange? fallbackSelection,
) {
  final value = controller.value;
  final selection = value.selection.isValid
      ? value.selection
      : (fallbackSelection ??
            TextSelection.collapsed(offset: value.text.length));
  final start = selection.start.clamp(0, value.text.length);
  final end = selection.end.clamp(start, value.text.length);
  final newText = value.text.replaceRange(start, end, text);
  controller.value = value.copyWith(
    text: newText,
    selection: TextSelection.collapsed(offset: start + text.length),
    composing: TextRange.empty,
  );
}

/// Deletes the selection, or one character before the caret.
void backspaceSelection(TextEditingController controller) {
  final value = controller.value;
  final selection = value.selection;
  if (!selection.isValid) {
    if (value.text.isEmpty) return;
    final newText = value.text.substring(0, value.text.length - 1);
    controller.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
      composing: TextRange.empty,
    );
    return;
  }
  if (selection.isCollapsed && selection.start == 0) return;
  final removeStart = selection.isCollapsed
      ? selection.start - 1
      : selection.start;
  final removeEnd = selection.end;
  final newText = value.text.replaceRange(removeStart, removeEnd, '');
  controller.value = value.copyWith(
    text: newText,
    selection: TextSelection.collapsed(offset: removeStart),
    composing: TextRange.empty,
  );
}
