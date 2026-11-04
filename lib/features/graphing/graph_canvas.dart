import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/math/expression.dart';
import '../../core/theme/app_palette.dart';

import '../../core/utils/formatters.dart';
import '../../ui/widgets/frosted_surface.dart';
import 'graph_controller.dart';
import 'graph_painter.dart';

/// Interactive graph surface: drag to pan, pinch or scroll to zoom.
class GraphCanvas extends StatefulWidget {
  const GraphCanvas({
    super.key,
    required this.controller,
    required this.angleMode,
  });

  final GraphController controller;
  final AngleMode angleMode;

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas> {
  Offset? _cursor;
  double _lastScale = 1;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              final factor = math.exp(-event.scrollDelta.dy * 0.0016);
              widget.controller.zoomAt(factor, event.localPosition, size);
            }
          },
          child: MouseRegion(
            onHover: (event) {
              if (_cursor != event.localPosition) {
                setState(() => _cursor = event.localPosition);
              }
            },
            onExit: (_) {
              if (_cursor != null) setState(() => _cursor = null);
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (_) => _lastScale = 1,
              onScaleUpdate: (details) {
                final delta = details.focalPointDelta;
                if (delta != Offset.zero) {
                  widget.controller.panByPixels(delta.dx, delta.dy);
                }
                if (details.scale != _lastScale) {
                  final factor = details.scale / _lastScale;
                  widget.controller.zoomAt(
                    factor,
                    details.localFocalPoint,
                    size,
                  );
                  _lastScale = details.scale;
                }
              },
              onDoubleTap: () => widget.controller.resetView(),
              child: AnimatedBuilder(
                animation: widget.controller,
                builder: (context, _) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: GraphPainter(
                              controller: widget.controller,
                              angleMode: widget.angleMode,
                              gridColor: palette.textPrimary,
                              axisColor: palette.textSecondary,
                              labelColor: palette.textTertiary.withValues(
                                alpha: 0.9,
                              ),
                              crosshairColor: palette.brand,
                              cursor: _cursor,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                      if (_cursor != null)
                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: _Readout(
                            controller: widget.controller,
                            cursor: _cursor!,
                            size: size,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({
    required this.controller,
    required this.cursor,
    required this.size,
  });

  final GraphController controller;
  final Offset cursor;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final x =
        controller.centerX + (cursor.dx - size.width / 2) / controller.scale;
    final y =
        controller.centerY - (cursor.dy - size.height / 2) / controller.scale;

    return FrostedSurface(
      radius: 12,
      opacity: 0.55,
      blur: 16,
      shadow: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'x = ${formatNumber(x, precision: 5)}',
            style: context.textStyles.labelSmall?.copyWith(
              color: context.palette.textSecondary,
              fontFeatures: const [ui.FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'y = ${formatNumber(y, precision: 5)}',
            style: context.textStyles.labelSmall?.copyWith(
              color: context.palette.textSecondary,
              fontFeatures: const [ui.FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
