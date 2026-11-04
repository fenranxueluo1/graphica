import 'package:flutter/material.dart';

import '../../core/math/matrix.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../l10n/l10n.dart';
import '../../state/app_settings.dart';
import '../../ui/widgets/app_page_scaffold.dart';
import '../../ui/widgets/app_top_bar.dart';
import '../../ui/widgets/frosted_surface.dart';
import '../../ui/widgets/glass_panel.dart';

class MatrixPage extends StatefulWidget {
  const MatrixPage({super.key});

  @override
  State<MatrixPage> createState() => _MatrixPageState();
}

class _MatrixPageState extends State<MatrixPage> {
  int _rowsA = 2;
  int _colsA = 2;
  int _rowsB = 2;
  int _colsB = 2;

  late List<List<TextEditingController>> _aControllers;
  late List<List<TextEditingController>> _bControllers;
  final TextEditingController _scalar = TextEditingController(text: '2');

  Matrix? _resultMatrix;
  double? _resultScalar;
  String _resultLabel = 'Result';
  String? _error;

  @override
  void initState() {
    super.initState();
    _aControllers = _createControllers(2, 2, const [
      ['1', '2'],
      ['3', '4'],
    ]);
    _bControllers = _createControllers(2, 2, const [
      ['1', '0'],
      ['0', '1'],
    ]);
  }

  List<List<TextEditingController>> _createControllers(
    int rows,
    int cols, [
    List<List<String>>? values,
  ]) {
    return List.generate(rows, (r) {
      return List.generate(cols, (c) {
        final text = values != null && r < values.length && c < values[r].length
            ? values[r][c]
            : '0';
        return TextEditingController(text: text);
      });
    });
  }

  @override
  void dispose() {
    for (final row in _aControllers) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    for (final row in _bControllers) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    _scalar.dispose();
    super.dispose();
  }

  void _resize(bool isA, {int? rows, int? cols}) {
    final currentRows = isA ? _rowsA : _rowsB;
    final currentCols = isA ? _colsA : _colsB;
    final controllers = isA ? _aControllers : _bControllers;
    final nextRows = (rows ?? currentRows).clamp(1, 6);
    final nextCols = (cols ?? currentCols).clamp(1, 6);
    if (nextRows == currentRows && nextCols == currentCols) return;

    final values = <List<String>>[
      for (var r = 0; r < nextRows; r++)
        [
          for (var c = 0; c < nextCols; c++)
            (r < currentRows && c < currentCols) ? controllers[r][c].text : '0',
        ],
    ];
    final next = _createControllers(nextRows, nextCols, values);

    setState(() {
      if (isA) {
        _aControllers = next;
        _rowsA = nextRows;
        _colsA = nextCols;
      } else {
        _bControllers = next;
        _rowsB = nextRows;
        _colsB = nextCols;
      }
      _resultMatrix = null;
      _resultScalar = null;
      _error = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final row in controllers) {
        for (final controller in row) {
          controller.dispose();
        }
      }
    });
  }

  Matrix _read(
    List<List<TextEditingController>> controllers,
    int rows,
    int cols,
    String name,
  ) {
    final values = <List<double>>[];
    for (var r = 0; r < rows; r++) {
      final row = <double>[];
      for (var c = 0; c < cols; c++) {
        final text = controllers[r][c].text.trim();
        final value = text.isEmpty ? 0.0 : double.tryParse(text);
        if (value == null) {
          throw MatrixException('matrix.error.invalidCell', <String, String>{
            'name': name,
            'row': '${r + 1}',
            'col': '${c + 1}',
          });
        }
        row.add(value);
      }
      values.add(row);
    }
    return Matrix.fromRows(values);
  }

  void _run(String operation) {
    Haptics.tap();
    try {
      final a = _read(_aControllers, _rowsA, _colsA, 'A');
      final b = _read(_bControllers, _rowsB, _colsB, 'B');
      Matrix? matrix;
      double? scalar;
      var label = operation;

      switch (operation) {
        case 'A + B':
          matrix = a + b;
        case 'A − B':
          matrix = a - b;
        case 'A × B':
          matrix = a * b;
        case 'k · A':
          final factor = double.tryParse(_scalar.text.trim());
          if (factor == null) {
            throw const MatrixException('matrix.error.scalar');
          }
          matrix = a.scale(factor);
          label = '${formatNumber(factor)} · A';
        case 'Aᵀ':
          matrix = a.transpose();
        case 'A⁻¹':
          matrix = a.inverse();
        case 'det(A)':
          scalar = a.determinant();
        case 'trace(A)':
          scalar = a.trace;
        case 'Bᵀ':
          matrix = b.transpose();
        case 'B⁻¹':
          matrix = b.inverse();
        case 'det(B)':
          scalar = b.determinant();
      }

      setState(() {
        _error = null;
        _resultLabel = label;
        _resultMatrix = matrix;
        _resultScalar = scalar;
      });
    } on MatrixException catch (error) {
      setState(() {
        _error = _translateMatrixError(error, context.l10n);
        _resultMatrix = null;
        _resultScalar = null;
      });
    }
  }

  /// Fills the `{...}` placeholders of the localized error template. The `op`
  /// detail is itself an l10n key and is translated before substitution.
  static String _translateMatrixError(MatrixException error, L10n l10n) {
    var text = l10n.t(error.code);
    for (final entry in error.details.entries) {
      final value = entry.key == 'op' ? l10n.t(entry.value) : entry.value;
      text = text.replaceAll('{${entry.key}}', value);
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppPageScaffold(
      child: Column(
        children: [
          AppTopBar(
            title: l10n.t('matrix.title'),
            subtitle: l10n.t('matrix.subtitle'),
            actions: [
              CircleActionButton(
                icon: Icons.restart_alt_rounded,
                tooltip: l10n.t('matrix.clearResult'),
                onTap: () => setState(() {
                  _resultMatrix = null;
                  _resultScalar = null;
                  _error = null;
                }),
              ),
            ],
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                final editors = [
                  _MatrixEditor(
                    name: 'A',
                    controllers: _aControllers,
                    rows: _rowsA,
                    cols: _colsA,
                    onRows: (value) => _resize(true, rows: value),
                    onCols: (value) => _resize(true, cols: value),
                  ),
                  _MatrixEditor(
                    name: 'B',
                    controllers: _bControllers,
                    rows: _rowsB,
                    cols: _colsB,
                    onRows: (value) => _resize(false, rows: value),
                    onCols: (value) => _resize(false, cols: value),
                  ),
                ];
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: editors[0]),
                            const SizedBox(width: 14),
                            Expanded(child: editors[1]),
                          ],
                        )
                      else ...[
                        editors[0],
                        const SizedBox(height: 14),
                        editors[1],
                      ],
                      const SizedBox(height: 14),
                      _OperationPanel(scalar: _scalar, onRun: _run),
                      const SizedBox(height: 14),
                      _ResultCard(
                        label: _resultLabel,
                        matrix: _resultMatrix,
                        scalar: _resultScalar,
                        error: _error,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.t('matrix.tip'),
                        style: context.textStyles.labelSmall?.copyWith(
                          color: context.palette.textTertiary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MatrixEditor extends StatelessWidget {
  const _MatrixEditor({
    required this.name,
    required this.controllers,
    required this.rows,
    required this.cols,
    required this.onRows,
    required this.onCols,
  });

  final String name;
  final List<List<TextEditingController>> controllers;
  final int rows;
  final int cols;
  final ValueChanged<int> onRows;
  final ValueChanged<int> onCols;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: palette.brandSoft,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: palette.brand.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    name,
                    style: context.textStyles.labelLarge?.copyWith(
                      color: palette.brand,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$rows × $cols',
                style: context.textStyles.titleSmall?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              const Spacer(),
              _Stepper(label: 'R', value: rows, onChanged: onRows),
              const SizedBox(width: 8),
              _Stepper(label: 'C', value: cols, onChanged: onCols),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 7.0;
              final cellWidth =
                  ((constraints.maxWidth - gap * (cols - 1)) / cols).clamp(
                    38.0,
                    150.0,
                  );
              return Column(
                children: [
                  for (var r = 0; r < rows; r++) ...[
                    if (r > 0) const SizedBox(height: gap),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var c = 0; c < cols; c++) ...[
                          if (c > 0) const SizedBox(width: gap),
                          SizedBox(
                            width: cellWidth,
                            height: 44,
                            child: _MatrixCell(controller: controllers[r][c]),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MatrixCell extends StatelessWidget {
  const _MatrixCell({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      style: context.textStyles.bodyMedium?.copyWith(
        color: palette.textPrimary,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: palette.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: palette.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: palette.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: palette.brand),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: palette.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.textStyles.labelSmall?.copyWith(
              color: palette.textTertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
          _MiniButton(
            icon: Icons.remove_rounded,
            onTap: value > 1 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 18,
            child: Center(
              child: Text(
                '$value',
                style: context.textStyles.labelMedium?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          _MiniButton(
            icon: Icons.add_rounded,
            onTap: value < 6 ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: SizedBox(
        width: 24,
        height: 28,
        child: Icon(
          icon,
          size: 15,
          color: onTap == null
              ? context.palette.textTertiary.withValues(alpha: 0.4)
              : context.palette.textSecondary,
        ),
      ),
    );
  }
}

class _OperationPanel extends StatelessWidget {
  const _OperationPanel({required this.scalar, required this.onRun});

  final TextEditingController scalar;
  final ValueChanged<String> onRun;

  static const _operations = <String>[
    'A + B',
    'A − B',
    'A × B',
    'Aᵀ',
    'A⁻¹',
    'det(A)',
    'trace(A)',
    'Bᵀ',
    'B⁻¹',
    'det(B)',
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 18, color: palette.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.t('matrix.operations'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 96,
                height: 34,
                child: TextField(
                  controller: scalar,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  style: context.textStyles.labelMedium?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'k',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: palette.hairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: palette.hairline),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _OpChip(
                label: 'k · A',
                onTap: () => onRun('k · A'),
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final operation in _operations)
                _OpChip(label: operation, onTap: () => onRun(operation)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OpChip extends StatelessWidget {
  const _OpChip({
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 9 : 12),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 7 : 9,
          ),
          decoration: BoxDecoration(
            color: palette.surfaceElevated,
            borderRadius: BorderRadius.circular(compact ? 9 : 12),
            border: Border.all(color: palette.hairline),
          ),
          child: Text(
            label,
            style: context.textStyles.labelMedium?.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.label,
    required this.matrix,
    required this.scalar,
    required this.error,
  });

  final String label;
  final Matrix? matrix;
  final double? scalar;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasResult = matrix != null || scalar != null;
    return FrostedSurface(
      radius: 22,
      opacity: 0.34,
      blur: 0,
      backdrop: false,
      shadow: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                hasResult ? label : context.l10n.t('matrix.result'),
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (matrix != null)
                Text(
                  '${matrix!.rows} × ${matrix!.cols}',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: palette.textTertiary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (error != null)
            Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: AppColors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error!,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: AppColors.red,
                    ),
                  ),
                ),
              ],
            )
          else if (scalar != null)
            Text(
              formatNumber(scalar!, precision: 10),
              style: context.textStyles.headlineMedium?.copyWith(
                color: palette.brand,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (matrix != null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                matrix!.display(),
                style: context.textStyles.bodyLarge?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  height: 1.6,
                ),
              ),
            )
          else
            Text(
              context.l10n.t('matrix.choose'),
              style: context.textStyles.bodySmall?.copyWith(
                color: palette.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}
