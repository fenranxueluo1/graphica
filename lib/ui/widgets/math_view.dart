import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Renders LaTeX when available and falls back to the raw text otherwise.
class MathView extends StatelessWidget {
  const MathView({
    super.key,
    required this.latex,
    required this.fallback,
    this.fontSize = 18,
    this.color,
    this.scrollable = true,
    this.display = true,
    this.maxWidth,
  });

  final String? latex;
  final String fallback;
  final double fontSize;
  final Color? color;
  final bool scrollable;
  final bool display;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? Theme.of(context).textTheme.bodyMedium?.color;
    final tex = latex;
    if (tex == null || tex.trim().isEmpty) {
      return Text(
        fallback,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: fontSize,
          color: textColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    }

    Widget child;
    try {
      child = Math.tex(
        tex,
        mathStyle: display ? MathStyle.display : MathStyle.text,
        textStyle: TextStyle(fontSize: fontSize, color: textColor),
        onErrorFallback: (error) {
          return Text(
            fallback,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: fontSize, color: textColor),
          );
        },
      );
    } catch (_) {
      child = Text(
        fallback,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: fontSize, color: textColor),
      );
    }

    if (maxWidth != null) {
      child = SizedBox(width: maxWidth, child: child);
    }
    if (!scrollable) return child;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: child,
    );
  }
}
