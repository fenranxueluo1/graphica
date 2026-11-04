import 'package:flutter/material.dart';

import '../../core/math/expression.dart';
import '../../core/math/latex.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../state/app_settings.dart';
import '../../ui/widgets/frosted_surface.dart';
import '../../ui/widgets/math_keyboard.dart';
import '../../ui/widgets/math_view.dart';
import 'surface3d_controller.dart';

/// Multi-expression editor for 3D surfaces.
class SurfaceExpressionPanel extends StatefulWidget {
  const SurfaceExpressionPanel({super.key, required this.controller});

  final Surface3DController controller;

  @override
  State<SurfaceExpressionPanel> createState() => _SurfaceExpressionPanelState();
}

class _SurfaceExpressionPanelState extends State<SurfaceExpressionPanel> {
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  int? _activeId;
  bool _keyboardVisible = true;

  @override
  void initState() {
    super.initState();
    _syncControllers();
    _activeId = widget.controller.expressions.isEmpty
        ? null
        : widget.controller.expressions.first.id;
  }

  void _syncControllers() {
    for (final expression in widget.controller.expressions) {
      final controller = _controllers.putIfAbsent(
        expression.id,
        () => TextEditingController(text: expression.input),
      );
      final node = _focusNodes.putIfAbsent(expression.id, () {
        final focus = FocusNode();
        focus.addListener(() {
          if (focus.hasFocus && mounted) {
            setState(() {
              _activeId = expression.id;
              _keyboardVisible = true;
            });
          }
        });
        return focus;
      });
      if (controller.text != expression.input && !node.hasFocus) {
        controller.text = expression.input;
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _addExpression() {
    widget.controller.addExpression();
    final expressions = widget.controller.expressions;
    if (expressions.isEmpty) return;
    final id = expressions.last.id;
    _syncControllers();
    setState(() {
      _activeId = id;
      _keyboardVisible = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[id]?.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        _syncControllers();
        final expressions = widget.controller.expressions;
        final activeId = expressions.any((e) => e.id == _activeId)
            ? _activeId
            : (expressions.isEmpty ? null : expressions.first.id);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('surface.expressions'),
                        style: context.textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.count(
                          expressions.length,
                          '个曲面',
                          'surface',
                          'surfaces',
                        ),
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.palette.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                _RoundIcon(
                  icon: Icons.keyboard_alt_outlined,
                  tooltip: l10n.t('mathKeyboard.title'),
                  highlighted: _keyboardVisible,
                  onTap: () =>
                      setState(() => _keyboardVisible = !_keyboardVisible),
                ),
                const SizedBox(width: 6),
                _RoundIcon(
                  icon: Icons.add_rounded,
                  tooltip: l10n.t('surface.add'),
                  highlighted: true,
                  onTap: _addExpression,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (expressions.isEmpty)
              FrostedSurface(
                radius: 16,
                opacity: 0.3,
                blur: 0,
                backdrop: false,
                shadow: false,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.view_in_ar_rounded,
                      size: 28,
                      color: context.palette.textTertiary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.t('surface.emptyList'),
                      textAlign: TextAlign.center,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.palette.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _addExpression,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(l10n.t('surface.add')),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: expressions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final expression = expressions[index];
                  return _SurfaceCard(
                    controller: widget.controller,
                    expression: expression,
                    textController: _controllers[expression.id]!,
                    focusNode: _focusNodes[expression.id]!,
                    showKeyboard: _keyboardVisible && activeId == expression.id,
                    onKeyboardChanged: () => widget.controller.updateInput(
                      expression.id,
                      _controllers[expression.id]!.text,
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.controller,
    required this.expression,
    required this.textController,
    required this.focusNode,
    required this.showKeyboard,
    required this.onKeyboardChanged,
  });

  final Surface3DController controller;
  final SurfaceExpression expression;
  final TextEditingController textController;
  final FocusNode focusNode;
  final bool showKeyboard;
  final VoidCallback onKeyboardChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final source = expression.input.trim();
    final error = source.isEmpty ? null : MathEngine.validate(source);
    final bodyLatex = error == null && source.isNotEmpty
        ? expressionToLatex(source)
        : null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: expression.visible ? 1 : 0.55,
      child: FrostedSurface(
        radius: 16,
        opacity: 0.32,
        blur: 0,
        backdrop: false,
        shadow: false,
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ColorDot(
                  color: expression.color,
                  onPick: (color) =>
                      controller.updateColor(expression.id, color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: textController,
                    focusNode: focusNode,
                    onChanged: (value) =>
                        controller.updateInput(expression.id, value),
                    autocorrect: false,
                    enableSuggestions: false,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      hintText: l10n.t('surface.inputHint'),
                      hintStyle: context.textStyles.bodyMedium?.copyWith(
                        color: palette.textTertiary,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
                _RoundIcon(
                  icon: expression.visible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: 32,
                  onTap: () => controller.toggleVisible(expression.id),
                ),
                _RoundIcon(
                  icon: Icons.close_rounded,
                  size: 32,
                  onTap: () => controller.removeExpression(expression.id),
                ),
              ],
            ),
            if (bodyLatex != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 28, right: 6),
                child: MathView(
                  latex: 'z = $bodyLatex',
                  fallback: 'z = $source',
                  fontSize: 17,
                  color: palette.textPrimary,
                ),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 13,
                      color: AppColors.red.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        error,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.labelSmall?.copyWith(
                          color: AppColors.red.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (showKeyboard) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.keyboard_alt_outlined,
                    size: 13,
                    color: palette.textTertiary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    l10n.t('mathKeyboard.title'),
                    style: context.textStyles.labelSmall?.copyWith(
                      color: palette.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              MathKeyboard(
                controller: textController,
                onChanged: onKeyboardChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, required this.onPick});

  final Color color;
  final ValueChanged<Color> onPick;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Color>(
      tooltip: context.l10n.t('surface.colour'),
      onSelected: onPick,
      color: context.palette.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.palette.hairline),
      ),
      itemBuilder: (context) => [
        for (final option in Surface3DController.palette)
          PopupMenuItem<Color>(
            value: option,
            height: 38,
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: option,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(context.l10n.t('surface.colour')),
              ],
            ),
          ),
      ],
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 34,
    this.highlighted = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Haptics.tap();
          onTap();
        },
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlighted ? palette.brandSoft : Colors.transparent,
            border: highlighted
                ? Border.all(color: palette.brand.withValues(alpha: 0.35))
                : null,
          ),
          child: Icon(
            icon,
            size: size * 0.5,
            color: highlighted ? palette.brand : palette.textSecondary,
          ),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Domain, resolution, rendering and preset controls shared by both layouts.
class SurfaceOptionsPanel extends StatelessWidget {
  const SurfaceOptionsPanel({
    super.key,
    required this.controller,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
  });

  final Surface3DController controller;
  final TextEditingController xMin;
  final TextEditingController xMax;
  final TextEditingController yMin;
  final TextEditingController yMax;

  static const presets = <(String, String)>[
    ('surface.preset.ripple', 'sin(sqrt(x^2 + y^2))'),
    ('surface.preset.saddle', 'x^2 - y^2'),
    ('surface.preset.waves', 'sin(x) * cos(y)'),
    ('surface.preset.cone', 'sqrt(x^2 + y^2)'),
    ('surface.preset.bowl', '(x^2 + y^2) / 8'),
  ];

  double _num(TextEditingController controller, double fallback) {
    return double.tryParse(controller.text.trim()) ?? fallback;
  }

  void _applyPreset(String expression) {
    SurfaceExpression? empty;
    for (final candidate in controller.expressions) {
      if (candidate.input.trim().isEmpty) {
        empty = candidate;
        break;
      }
    }
    if (empty != null) {
      controller.updateInput(empty.id, expression);
    } else {
      controller.addExpression(input: expression);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final xInvalid = _num(xMin, -5) >= _num(xMax, 5);
    final yInvalid = _num(yMin, -5) >= _num(yMax, 5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.t('surface.settings'),
          style: context.textStyles.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DomainField(
                label: l10n.t('surface.xMin'),
                controller: xMin,
                onChanged: () =>
                    controller.setDomain(xMin: _num(xMin, controller.xMin)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DomainField(
                label: l10n.t('surface.xMax'),
                controller: xMax,
                onChanged: () =>
                    controller.setDomain(xMax: _num(xMax, controller.xMax)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _DomainField(
                label: l10n.t('surface.yMin'),
                controller: yMin,
                onChanged: () =>
                    controller.setDomain(yMin: _num(yMin, controller.yMin)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DomainField(
                label: l10n.t('surface.yMax'),
                controller: yMax,
                onChanged: () =>
                    controller.setDomain(yMax: _num(yMax, controller.yMax)),
              ),
            ),
          ],
        ),
        if (xInvalid)
          _ErrorText(text: l10n.t('surface.xRange'))
        else if (yInvalid)
          _ErrorText(text: l10n.t('surface.yRange')),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              l10n.t('surface.resolution'),
              style: context.textStyles.labelMedium?.copyWith(
                color: palette.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '${controller.resolution.round()}',
              style: context.textStyles.labelMedium?.copyWith(
                color: palette.brand,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Slider(
          value: controller.resolution,
          min: 10,
          max: 60,
          divisions: 25,
          onChanged: controller.setResolution,
        ),
        Row(
          children: [
            Icon(
              controller.wireframe
                  ? Icons.grid_4x4_rounded
                  : Icons.gradient_rounded,
              size: 18,
              color: palette.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                controller.wireframe
                    ? l10n.t('surface.wireframe')
                    : l10n.t('surface.shaded'),
                style: context.textStyles.bodySmall?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ),
            Switch(
              value: controller.wireframe,
              onChanged: controller.setWireframe,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          l10n.t('surface.presets'),
          style: context.textStyles.labelMedium?.copyWith(
            color: palette.textTertiary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in presets)
              _PresetChip(
                label: l10n.t(preset.$1),
                onTap: () => _applyPreset(preset.$2),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          l10n.t('surface.hint'),
          style: context.textStyles.labelSmall?.copyWith(
            color: palette.textTertiary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _DomainField extends StatelessWidget {
  const _DomainField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      style: context.textStyles.bodySmall?.copyWith(
        color: context.palette.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: context.textStyles.labelSmall?.copyWith(color: AppColors.red),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});

  final String label;
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: palette.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.hairline),
          ),
          child: Text(
            label,
            style: context.textStyles.labelSmall?.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
