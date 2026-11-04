import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/text_input.dart';

/// Compact on-screen keyboard for entering mathematical formulas.
///
/// Inserts symbols at the caret so it works on phones, tablets and desktops.
class MathKeyboard extends StatelessWidget {
  const MathKeyboard({super.key, required this.controller, this.onChanged});

  final TextEditingController controller;
  final VoidCallback? onChanged;

  void _insert(String text) {
    insertAtSelection(controller, text, null);
    onChanged?.call();
  }

  void _backspace() {
    backspaceSelection(controller);
    onChanged?.call();
  }

  void _clear() {
    controller.clear();
    onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row([
          _spec('sin', insert: 'sin(', tone: _Tone.function),
          _spec('cos', insert: 'cos(', tone: _Tone.function),
          _spec('tan', insert: 'tan(', tone: _Tone.function),
          _spec('ln', insert: 'ln(', tone: _Tone.function),
          _spec('log', insert: 'log(', tone: _Tone.function),
          _spec('=', insert: '=', tone: _Tone.operator),
        ]),
        const SizedBox(height: 5),
        _row([
          _spec('√', insert: 'sqrt(', tone: _Tone.function),
          _spec('^', insert: '^', tone: _Tone.operator),
          _spec('(', insert: '(', tone: _Tone.function),
          _spec(')', insert: ')', tone: _Tone.function),
          _spec('π', insert: 'pi', tone: _Tone.function),
          _spec('⌫', action: _backspace, tone: _Tone.action),
        ]),
        const SizedBox(height: 5),
        _row([
          _spec('x', insert: 'x', tone: _Tone.variable),
          _spec('y', insert: 'y', tone: _Tone.variable),
          _spec('θ', insert: 'theta', tone: _Tone.variable),
          _spec('e', insert: 'e', tone: _Tone.function),
          _spec(',', insert: ',', tone: _Tone.function),
          _spec('AC', action: _clear, tone: _Tone.action),
        ]),
        const SizedBox(height: 5),
        _row([
          _spec('7'),
          _spec('8'),
          _spec('9'),
          _spec('÷', insert: '/', tone: _Tone.operator),
          _spec('×', insert: '*', tone: _Tone.operator),
          _spec('x²', insert: '^2', tone: _Tone.function),
        ]),
        const SizedBox(height: 5),
        _row([
          _spec('4'),
          _spec('5'),
          _spec('6'),
          _spec('+', insert: '+', tone: _Tone.operator),
          _spec('−', insert: '-', tone: _Tone.operator),
          _spec('|x|', insert: 'abs(', tone: _Tone.function),
        ]),
        const SizedBox(height: 5),
        _row([
          _spec('1'),
          _spec('2'),
          _spec('3'),
          _spec('0'),
          _spec('.', insert: '.'),
          _spec('!', insert: '!', tone: _Tone.function),
        ]),
      ],
    );
  }

  _KeySpec _spec(
    String label, {
    String? insert,
    VoidCallback? action,
    _Tone tone = _Tone.digit,
  }) {
    return _KeySpec(label, insert: insert, action: action, tone: tone);
  }

  Widget _row(List<_KeySpec> specs) {
    return Row(
      children: [
        for (var i = 0; i < specs.length; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
            child: _KeyboardKey(
              spec: specs[i],
              onTap: () {
                Haptics.tap();
                if (specs[i].action != null) {
                  specs[i].action!();
                } else {
                  _insert(specs[i].insert ?? specs[i].label);
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}

enum _Tone { digit, operator, function, variable, action }

class _KeySpec {
  const _KeySpec(
    this.label, {
    this.insert,
    this.action,
    this.tone = _Tone.digit,
  });

  final String label;
  final String? insert;
  final VoidCallback? action;
  final _Tone tone;
}

class _KeyboardKey extends StatelessWidget {
  const _KeyboardKey({required this.spec, required this.onTap});

  final _KeySpec spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dark = context.isDark;
    final Color background;
    final Color foreground;
    switch (spec.tone) {
      case _Tone.digit:
        background = dark ? palette.surfaceElevated : palette.surfaceElevated;
        foreground = palette.textPrimary;
      case _Tone.operator:
        background = palette.brandSoft;
        foreground = palette.brand;
      case _Tone.function:
        background = palette.surface.withValues(alpha: 0.8);
        foreground = palette.textSecondary;
      case _Tone.variable:
        background = palette.brandSoft;
        foreground = palette.brand;
      case _Tone.action:
        background = AppColors.red.withValues(alpha: 0.12);
        foreground = AppColors.red;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Ink(
          height: 38,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: palette.hairline),
          ),
          child: Center(
            child: Text(
              spec.label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: foreground,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
