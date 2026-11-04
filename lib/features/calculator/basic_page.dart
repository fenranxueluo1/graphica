import 'package:flutter/material.dart';

import '../../core/math/expression.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../state/app_settings.dart';
import '../../ui/widgets/glass_panel.dart';
import 'calc_button.dart';

class BasicCalculator extends StatefulWidget {
  const BasicCalculator({super.key});

  @override
  State<BasicCalculator> createState() => _BasicCalculatorState();
}

class _TapeEntry {
  const _TapeEntry(this.expression, this.result);

  final String expression;
  final String result;
}

class _BasicCalculatorState extends State<BasicCalculator> {
  String _expression = '';
  String? _result;
  String? _error;
  final List<_TapeEntry> _tape = [];

  void _append(String text) {
    setState(() {
      _expression += text;
      _result = null;
      _error = null;
    });
  }

  void _backspace() {
    if (_expression.isEmpty) return;
    setState(() {
      _expression = _expression.substring(0, _expression.length - 1);
      _result = null;
      _error = null;
    });
  }

  void _clear() {
    setState(() {
      _expression = '';
      _result = null;
      _error = null;
    });
  }

  void _evaluate() {
    final source = _expression.trim();
    if (source.isEmpty) return;
    try {
      final value = MathEngine.evaluate(source);
      final text = formatNumber(value, precision: 12);
      setState(() {
        _result = text;
        _error = null;
        _tape.insert(0, _TapeEntry(source, text));
        if (_tape.length > 10) _tape.removeLast();
        _expression = text;
      });
    } on MathException catch (error) {
      setState(() => _error = error.message);
    }
  }

  String? _preview() {
    final source = _expression.trim();
    if (source.isEmpty) return null;
    try {
      return formatNumber(MathEngine.evaluate(source), precision: 12);
    } on MathException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final preview = _result ?? _preview();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          GlassPanel(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            radius: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      context.l10n.t('calc.fourFunction'),
                      style: context.textStyles.labelSmall?.copyWith(
                        color: palette.textTertiary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const Spacer(),
                    if (_tape.isNotEmpty)
                      Text(
                        '${context.l10n.t('calc.tape')} · ${_tape.length}',
                        style: context.textStyles.labelSmall?.copyWith(
                          color: palette.textTertiary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _expression.isEmpty ? '0' : _expression,
                      maxLines: 1,
                      style: context.textStyles.displaySmall?.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 26,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _error != null
                        ? Text(
                            _error!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.bodySmall?.copyWith(
                              color: AppColors.red,
                            ),
                          )
                        : Text(
                            preview == null ? '' : '= $preview',
                            style: context.textStyles.titleMedium?.copyWith(
                              color: palette.brand,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (_tape.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _tape.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final entry = _tape[index];
                  return _TapeChip(
                    entry: entry,
                    onTap: () => setState(() {
                      _expression = entry.result;
                      _result = null;
                      _error = null;
                    }),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gap = 10.0;
                final rows = _rows();
                final rowHeight =
                    (constraints.maxHeight - gap * (rows.length - 1)) /
                    rows.length;
                return Column(
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0) SizedBox(height: gap),
                      SizedBox(height: rowHeight, child: rows[i]),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _rows() {
    Widget digit(String label, {String? insert}) => CalcButton(
      label: label,
      fontSize: 24,
      onTap: () => _append(insert ?? label),
    );

    Widget op(String label) => CalcButton(
      label: label,
      tone: CalcTone.operator,
      fontSize: 24,
      onTap: () => _append(label),
    );

    return [
      CalcKeyRow(
        spacing: 10,
        children: [
          CalcButton(
            label: 'AC',
            tone: CalcTone.action,
            fontSize: 18,
            onTap: _clear,
          ),
          CalcButton(
            label: '⌫',
            tone: CalcTone.action,
            icon: Icons.backspace_outlined,
            onTap: _backspace,
          ),
          CalcButton(
            label: '%',
            tone: CalcTone.function,
            fontSize: 20,
            onTap: () => _append('/100'),
          ),
          op('÷'),
        ],
      ),
      CalcKeyRow(
        spacing: 10,
        children: [digit('7'), digit('8'), digit('9'), op('×')],
      ),
      CalcKeyRow(
        spacing: 10,
        children: [digit('4'), digit('5'), digit('6'), op('−')],
      ),
      CalcKeyRow(
        spacing: 10,
        children: [digit('1'), digit('2'), digit('3'), op('+')],
      ),
      CalcKeyRow(
        spacing: 10,
        children: [
          CalcButton(
            label: '±',
            tone: CalcTone.function,
            fontSize: 20,
            onTap: () => _append('-'),
          ),
          digit('0'),
          digit('.'),
          CalcButton(
            label: '=',
            tone: CalcTone.equals,
            fontSize: 24,
            onTap: _evaluate,
          ),
        ],
      ),
    ];
  }
}

class _TapeChip extends StatelessWidget {
  const _TapeChip({required this.entry, required this.onTap});

  final _TapeEntry entry;
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
