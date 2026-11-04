import 'package:flutter/material.dart';

import '../../core/math/expression.dart';
import '../../core/math/latex.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../l10n/l10n.dart';
import '../../state/app_settings.dart';
import '../../ui/widgets/frosted_surface.dart';
import '../../ui/widgets/gradient_button.dart';
import '../../ui/widgets/math_keyboard.dart';
import '../../ui/widgets/math_view.dart';
import 'graph_controller.dart';

/// Editable list of graph expressions with colour, visibility, kind controls,
/// typeset previews and an on-screen math keyboard.
class GraphExpressionPanel extends StatefulWidget {
  const GraphExpressionPanel({
    super.key,
    required this.controller,
    this.padding = const EdgeInsets.all(18),
    this.onClose,
  });

  final GraphController controller;
  final EdgeInsetsGeometry padding;

  /// When non-null the panel is shown inside a closable overlay (bottom sheet)
  /// and a confirm button that invokes it is rendered at the bottom.
  final VoidCallback? onClose;

  @override
  State<GraphExpressionPanel> createState() => _GraphExpressionPanelState();
}

class _GraphExpressionPanelState extends State<GraphExpressionPanel> {
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
                        l10n.t('graph.expressions'),
                        style: context.textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.count(
                          expressions.length,
                          '条曲线',
                          'curve',
                          'curves',
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
                  onTap: () => setState(() {
                    _keyboardVisible = !_keyboardVisible;
                  }),
                ),
                const SizedBox(width: 6),
                _RoundIcon(
                  icon: Icons.add_rounded,
                  tooltip: l10n.t('graph.add'),
                  highlighted: true,
                  onTap: _addExpression,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: expressions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final expression = expressions[index];
                  final controller = _controllers[expression.id]!;
                  final focusNode = _focusNodes[expression.id]!;
                  return _ExpressionCard(
                    controller: widget.controller,
                    expression: expression,
                    textController: controller,
                    focusNode: focusNode,
                    showKeyboard: _keyboardVisible && activeId == expression.id,
                    onKeyboardChanged: () => widget.controller.updateInput(
                      expression.id,
                      controller.text,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 15,
                  color: context.palette.textTertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.t('graph.hint'),
                    style: context.textStyles.labelSmall?.copyWith(
                      color: context.palette.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.onClose != null) ...[
              const SizedBox(height: 14),
              GradientButton(
                label: l10n.t('graph.done'),
                icon: Icons.check_rounded,
                expanded: true,
                height: 48,
                onPressed: widget.onClose,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ExpressionCard extends StatelessWidget {
  const _ExpressionCard({
    required this.controller,
    required this.expression,
    required this.textController,
    required this.focusNode,
    required this.showKeyboard,
    required this.onKeyboardChanged,
  });

  final GraphController controller;
  final GraphExpression expression;
  final TextEditingController textController;
  final FocusNode focusNode;
  final bool showKeyboard;
  final VoidCallback onKeyboardChanged;

  String? get _error {
    final body = expression.body;
    if (body.isEmpty) return null;
    if (expression.kind == GraphExpressionKind.implicit) {
      final (left, right) = expression.implicitSides;
      return MathEngine.validate(left) ?? MathEngine.validate(right);
    }
    return MathEngine.validate(body);
  }

  String? get _latex {
    if (expression.kind == GraphExpressionKind.implicit) {
      return equationToLatex(expression.body);
    }
    final bodyLatex = expressionToLatex(expression.body);
    if (bodyLatex == null) return null;
    return expression.kind == GraphExpressionKind.cartesian
        ? 'y = $bodyLatex'
        : 'r = $bodyLatex';
  }

  String get _fallback {
    if (expression.kind == GraphExpressionKind.implicit) {
      return expression.body;
    }
    return '${expression.kind.prefix} ${expression.body}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final error = _error;
    final hasBody = expression.body.isNotEmpty;

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
                _KindChip(
                  kind: expression.kind,
                  onChanged: (kind) =>
                      controller.updateKind(expression.id, kind),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: textController,
                    focusNode: focusNode,
                    onChanged: (value) =>
                        controller.updateInput(expression.id, value),
                    keyboardType: TextInputType.text,
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
                      hintText: switch (expression.kind) {
                        GraphExpressionKind.cartesian => 'sin(x)',
                        GraphExpressionKind.polar => '2cos(3theta)',
                        GraphExpressionKind.implicit => 'x^2 + y^2 = 9',
                      },
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
            if (hasBody) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 28, right: 6),
                child: MathView(
                  latex: _latex,
                  fallback: _fallback,
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
      tooltip: context.l10n.t('graph.colour'),
      onSelected: onPick,
      color: context.palette.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.palette.hairline),
      ),
      itemBuilder: (context) {
        return [
          for (final option in GraphController.curveColors)
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
                  Text(context.l10n.t('graph.colour')),
                ],
              ),
            ),
        ];
      },
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

class _KindChip extends StatelessWidget {
  const _KindChip({required this.kind, required this.onChanged});

  final GraphExpressionKind kind;
  final ValueChanged<GraphExpressionKind> onChanged;

  static String label(GraphExpressionKind kind, L10n l10n) {
    return switch (kind) {
      GraphExpressionKind.cartesian => l10n.t('graph.cartesian'),
      GraphExpressionKind.polar => l10n.t('graph.polar'),
      GraphExpressionKind.implicit => l10n.t('graph.implicit'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    return PopupMenuButton<GraphExpressionKind>(
      tooltip: l10n.t('graph.type'),
      onSelected: onChanged,
      color: palette.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: palette.hairline),
      ),
      itemBuilder: (context) => [
        for (final option in GraphExpressionKind.values)
          PopupMenuItem<GraphExpressionKind>(
            value: option,
            height: 40,
            child: Text(label(option, l10n)),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: palette.hairline),
        ),
        child: Text(
          kind.prefix,
          style: context.textStyles.labelSmall?.copyWith(
            color: palette.brand,
            fontWeight: FontWeight.w700,
          ),
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
