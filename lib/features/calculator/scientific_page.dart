import 'package:flutter/material.dart';

import '../../core/math/expression.dart';
import '../../core/math/latex.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../state/app_settings.dart';
import '../../ui/widgets/glass_panel.dart';
import '../../ui/widgets/math_view.dart';
import 'calc_button.dart';

class ScientificCalculator extends StatefulWidget {
  const ScientificCalculator({super.key});

  @override
  State<ScientificCalculator> createState() => _ScientificCalculatorState();
}

class _HistoryEntry {
  const _HistoryEntry(this.expression, this.result);

  final String expression;
  final String result;
}

class _ScientificCalculatorState extends State<ScientificCalculator> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();
  final List<_HistoryEntry> _history = [];
  double _ans = 0;
  String? _result;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _insert(String text) {
    final value = _input.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final start = selection.start.clamp(0, value.text.length);
    final end = selection.end.clamp(start, value.text.length);
    final newText = value.text.replaceRange(start, end, text);
    _input.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: start + text.length),
      composing: TextRange.empty,
    );
    setState(() {
      _result = null;
      _error = null;
    });
  }

  void _backspace() {
    final value = _input.value;
    final selection = value.selection;
    if (!selection.isValid || (selection.isCollapsed && selection.start == 0)) {
      return;
    }
    final start = selection.start;
    final end = selection.end;
    final int removeStart;
    final int removeEnd;
    if (!selection.isCollapsed) {
      removeStart = start;
      removeEnd = end;
    } else {
      removeStart = start - 1;
      removeEnd = start;
    }
    final newText = value.text.replaceRange(removeStart, removeEnd, '');
    _input.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: removeStart),
      composing: TextRange.empty,
    );
    setState(() {
      _result = null;
      _error = null;
    });
  }

  void _clear() {
    _input.clear();
    setState(() {
      _result = null;
      _error = null;
    });
  }

  void _evaluate(AngleMode angleMode) {
    final source = _input.text.trim();
    if (source.isEmpty) return;
    try {
      final value = MathEngine.evaluate(
        source,
        variables: {'ans': _ans},
        angleMode: angleMode,
      );
      final text = formatNumber(value, precision: 12);
      setState(() {
        _ans = value;
        _result = text;
        _error = null;
        _history.insert(0, _HistoryEntry(source, text));
        if (_history.length > 12) _history.removeLast();
      });
    } on MathException catch (error) {
      setState(() => _error = error.message);
    }
  }

  String? _preview(AngleMode angleMode) {
    final source = _input.text.trim();
    if (source.isEmpty) return null;
    try {
      final value = MathEngine.evaluate(
        source,
        variables: {'ans': _ans},
        angleMode: angleMode,
      );
      return formatNumber(value, precision: 12);
    } on MathException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context);
    final angleMode = settings.angleMode;
    final preview = _result ?? _preview(angleMode);

    return LayoutBuilder(
      builder: (context, constraints) {
        final keypadHeight = (constraints.maxWidth / 5 * 1.12).clamp(
          320.0,
          470.0,
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_history.isNotEmpty) ...[
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _history.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final entry = _history[index];
                      return _HistoryChip(
                        entry: entry,
                        onTap: () {
                          _input.text = entry.expression;
                          _input.selection = TextSelection.collapsed(
                            offset: _input.text.length,
                          );
                          setState(() {
                            _result = null;
                            _error = null;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
              _DisplayCard(
                input: _input,
                focusNode: _focus,
                angleMode: angleMode,
                onToggleAngle: settings.toggleAngleMode,
                onSubmitted: () => _evaluate(angleMode),
                onChange: () => setState(() {
                  _result = null;
                  _error = null;
                }),
                preview: preview,
                error: _error,
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: keypadHeight,
                child: Column(
                  children: [
                    for (final row in _buildRows(angleMode)) ...[
                      Expanded(child: row),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildRows(AngleMode angleMode) {
    Widget key(
      String label, {
      String? insert,
      VoidCallback? onTap,
      CalcTone tone = CalcTone.digit,
      double fontSize = 18,
      IconData? icon,
    }) {
      return CalcButton(
        label: label,
        tone: tone,
        fontSize: fontSize,
        icon: icon,
        onTap: onTap ?? () => _insert(insert ?? label),
      );
    }

    return [
      CalcKeyRow(
        children: [
          key(
            angleMode == AngleMode.degrees ? 'DEG' : 'RAD',
            tone: CalcTone.accent,
            fontSize: 13,
            onTap: () {
              AppScope.read(context).toggleAngleMode();
              setState(() => _result = null);
            },
          ),
          key('ANS', insert: 'ans', tone: CalcTone.accent, fontSize: 13),
          key('(', tone: CalcTone.function),
          key(')', tone: CalcTone.function),
          key(
            '⌫',
            tone: CalcTone.action,
            icon: Icons.backspace_outlined,
            onTap: _backspace,
          ),
        ],
      ),
      CalcKeyRow(
        children: [
          key('sin', insert: 'sin(', tone: CalcTone.function, fontSize: 14),
          key('cos', insert: 'cos(', tone: CalcTone.function, fontSize: 14),
          key('tan', insert: 'tan(', tone: CalcTone.function, fontSize: 14),
          key('ln', insert: 'ln(', tone: CalcTone.function, fontSize: 14),
          key('log', insert: 'log(', tone: CalcTone.function, fontSize: 14),
        ],
      ),
      CalcKeyRow(
        children: [
          key('√', insert: 'sqrt(', tone: CalcTone.function, fontSize: 17),
          key('xʸ', insert: '^', tone: CalcTone.operator),
          key('x²', insert: '^2', tone: CalcTone.function, fontSize: 15),
          key('π', insert: 'pi', tone: CalcTone.function),
          key('e', insert: 'e', tone: CalcTone.function),
        ],
      ),
      CalcKeyRow(
        children: [
          key('7'),
          key('8'),
          key('9'),
          key('÷', insert: '/', tone: CalcTone.operator),
          key('n!', insert: '!', tone: CalcTone.function, fontSize: 15),
        ],
      ),
      CalcKeyRow(
        children: [
          key('4'),
          key('5'),
          key('6'),
          key('×', insert: '*', tone: CalcTone.operator),
          key('%', insert: '/100', tone: CalcTone.function, fontSize: 15),
        ],
      ),
      CalcKeyRow(
        children: [
          key('1'),
          key('2'),
          key('3'),
          key('−', insert: '-', tone: CalcTone.operator),
          key('abs', insert: 'abs(', tone: CalcTone.function, fontSize: 13),
        ],
      ),
      CalcKeyRow(
        children: [
          key('AC', tone: CalcTone.action, fontSize: 15, onTap: _clear),
          key('0'),
          key('.', insert: '.'),
          key('+', insert: '+', tone: CalcTone.operator),
          key('=', tone: CalcTone.equals, onTap: () => _evaluate(angleMode)),
        ],
      ),
    ];
  }
}

class _DisplayCard extends StatelessWidget {
  const _DisplayCard({
    required this.input,
    required this.focusNode,
    required this.angleMode,
    required this.onToggleAngle,
    required this.onSubmitted,
    required this.onChange,
    required this.preview,
    required this.error,
  });

  final TextEditingController input;
  final FocusNode focusNode;
  final AngleMode angleMode;
  final VoidCallback onToggleAngle;
  final VoidCallback onSubmitted;
  final VoidCallback onChange;
  final String? preview;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final latex = expressionToLatex(input.text);
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onToggleAngle,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: palette.brandSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: palette.brand.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    angleMode == AngleMode.degrees ? 'DEG' : 'RAD',
                    style: context.textStyles.labelSmall?.copyWith(
                      color: palette.brand,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                context.l10n.t('calc.scientificLabel'),
                style: context.textStyles.labelSmall?.copyWith(
                  color: palette.textTertiary,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: input,
            focusNode: focusNode,
            onChanged: (_) => onChange(),
            onSubmitted: (_) => onSubmitted(),
            textAlign: TextAlign.right,
            maxLines: 1,
            style: context.textStyles.headlineSmall?.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              filled: false,
              isDense: true,
              hintText: '0',
              hintStyle: context.textStyles.headlineSmall?.copyWith(
                color: palette.textTertiary,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
            ),
          ),
          if (latex != null)
            SizedBox(
              height: 34,
              child: Align(
                alignment: Alignment.centerRight,
                child: MathView(
                  latex: latex,
                  fallback: input.text,
                  fontSize: 18,
                  color: palette.textSecondary,
                  scrollable: false,
                ),
              ),
            ),
          const SizedBox(height: 4),
          SizedBox(
            height: 40,
            child: Align(
              alignment: Alignment.centerRight,
              child: error != null
                  ? Text(
                      error!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: AppColors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: ShaderMask(
                        key: ValueKey(preview ?? 'empty'),
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [palette.brand, palette.brandAlt],
                        ).createShader(bounds),
                        child: Text(
                          preview == null ? '' : '= $preview',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({required this.entry, required this.onTap});

  final _HistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: palette.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.hairline),
          ),
          child: Text(
            '${entry.expression} = ${entry.result}',
            style: context.textStyles.labelSmall?.copyWith(
              color: palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
