import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';

enum CalcTone { digit, operator, function, action, accent, equals }

class CalcButton extends StatelessWidget {
  const CalcButton({
    super.key,
    required this.label,
    required this.onTap,
    this.tone = CalcTone.digit,
    this.fontSize = 18,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final CalcTone tone;
  final double fontSize;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dark = context.isDark;

    Color background;
    Color foreground;
    Gradient? gradient;
    Border? border;

    switch (tone) {
      case CalcTone.digit:
        background = dark ? palette.surfaceElevated : palette.surfaceElevated;
        foreground = palette.textPrimary;
        border = Border.all(color: palette.hairline);
      case CalcTone.operator:
        background = palette.brandSoft;
        foreground = palette.brand;
        border = Border.all(color: palette.brand.withValues(alpha: 0.22));
      case CalcTone.function:
        background = palette.surface.withValues(alpha: 0.75);
        foreground = palette.textSecondary;
        border = Border.all(color: palette.hairline);
      case CalcTone.action:
        background = AppColors.red.withValues(alpha: 0.12);
        foreground = AppColors.red;
        border = Border.all(color: AppColors.red.withValues(alpha: 0.28));
      case CalcTone.accent:
        background = palette.brandSoft;
        foreground = palette.brand;
        border = Border.all(color: palette.brand.withValues(alpha: 0.35));
      case CalcTone.equals:
        background = Colors.transparent;
        foreground = Colors.white;
        gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.brand, palette.brandAlt],
        );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Haptics.tap();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: gradient == null ? background : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            border: gradient == null ? border : null,
            boxShadow: tone == CalcTone.equals
                ? [
                    BoxShadow(
                      color: palette.brand.withValues(alpha: 0.30),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, size: fontSize + 4, color: foreground)
                : Text(
                    label,
                    textAlign: TextAlign.center,
                    style: context.textStyles.titleMedium?.copyWith(
                      color: foreground,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Row of keys that share the available width.
class CalcKeyRow extends StatelessWidget {
  const CalcKeyRow({
    super.key,
    required this.children,
    this.spacing = 8,
    this.flexes,
  });

  final List<Widget> children;
  final double spacing;
  final List<int>? flexes;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(flex: flexes?[i] ?? 1, child: children[i]),
        ],
      ],
    );
  }
}
