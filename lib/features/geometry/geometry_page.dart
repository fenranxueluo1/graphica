import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/math/expression.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/l10n.dart';
import '../../state/app_settings.dart';
import '../../ui/widgets/app_page_scaffold.dart';
import '../../ui/widgets/app_top_bar.dart';
import '../../ui/widgets/glass_panel.dart';
import '../../ui/widgets/segmented_control.dart';
import 'geometry_model.dart';
import 'geometry_painter.dart';

enum GeometryTool { select, point, segment, circle }

class GeometryPage extends StatefulWidget {
  const GeometryPage({super.key});

  @override
  State<GeometryPage> createState() => _GeometryPageState();
}

class _GeometryPageState extends State<GeometryPage> {
  final GeometryController _controller = GeometryController();

  GeometryTool _tool = GeometryTool.select;
  bool _snap = true;
  String? _selectedId;
  String? _pendingId;
  String? _dragId;
  Offset? _previewGraph;

  double _centerX = 0;
  double _centerY = 0;
  double _scale = 54;
  double _lastScale = 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _toGraph(Offset local, Size size) => Offset(
    _centerX + (local.dx - size.width / 2) / _scale,
    _centerY - (local.dy - size.height / 2) / _scale,
  );

  Offset _snapped(Offset graph) {
    if (!_snap) return graph;
    return Offset(
      (graph.dx * 2).roundToDouble() / 2,
      (graph.dy * 2).roundToDouble() / 2,
    );
  }

  double get _hitTolerance => 18 / _scale;

  void _handleTap(Offset local, Size size) {
    final graph = _toGraph(local, size);
    switch (_tool) {
      case GeometryTool.select:
        final hit = _controller.nearestPoint(graph, _hitTolerance);
        setState(() => _selectedId = hit?.id);
      case GeometryTool.point:
        final point = _controller.addPoint(_snapped(graph));
        setState(() => _selectedId = point.id);
      case GeometryTool.segment:
        final hit = _controller.nearestPoint(graph, _hitTolerance);
        final point = hit ?? _controller.addPoint(_snapped(graph));
        if (_pendingId == null) {
          setState(() {
            _pendingId = point.id;
            _previewGraph = graph;
          });
        } else if (_pendingId == point.id) {
          setState(() {
            _pendingId = null;
            _previewGraph = null;
          });
        } else {
          _controller.addSegment(_pendingId!, point.id);
          setState(() {
            _selectedId = point.id;
            _pendingId = null;
            _previewGraph = null;
          });
        }
      case GeometryTool.circle:
        if (_pendingId == null) {
          final hit = _controller.nearestPoint(graph, _hitTolerance);
          final point = hit ?? _controller.addPoint(_snapped(graph));
          setState(() {
            _pendingId = point.id;
            _previewGraph = graph;
          });
        } else {
          final center = _controller.pointById(_pendingId!);
          if (center != null) {
            final radius = (graph - center.position).distance;
            if (radius > 0.05) {
              _controller.addCircle(center.id, radius);
            }
          }
          setState(() {
            _pendingId = null;
            _previewGraph = null;
          });
        }
    }
  }

  void _handleLongPress(Offset local, Size size) {
    final graph = _toGraph(local, size);
    final hit = _controller.nearestPoint(graph, _hitTolerance);
    if (hit == null) return;
    _controller.removePoint(hit.id);
    setState(() {
      if (_selectedId == hit.id) _selectedId = null;
      if (_pendingId == hit.id) {
        _pendingId = null;
        _previewGraph = null;
      }
    });
  }

  void _handleScaleStart(ScaleStartDetails details, Size size) {
    _lastScale = 1;
    if (_tool == GeometryTool.select) {
      final graph = _toGraph(details.localFocalPoint, size);
      final hit = _controller.nearestPoint(graph, _hitTolerance);
      _dragId = hit?.id;
      if (hit != null) setState(() => _selectedId = hit.id);
    }
  }

  void _updatePreview(Offset local, Size size) {
    if (_pendingId == null) return;
    if (_tool != GeometryTool.segment && _tool != GeometryTool.circle) {
      return;
    }
    final graph = _toGraph(local, size);
    if (_previewGraph == graph) return;
    setState(() => _previewGraph = graph);
  }

  void _handleScaleUpdate(ScaleUpdateDetails details, Size size) {
    if (_pendingId != null &&
        (_tool == GeometryTool.segment || _tool == GeometryTool.circle)) {
      _updatePreview(details.localFocalPoint, size);
      return;
    }
    if (_dragId != null) {
      final graph = _toGraph(details.localFocalPoint, size);
      _controller.movePoint(_dragId!, _snapped(graph));
      return;
    }
    final delta = details.focalPointDelta;
    if (delta != Offset.zero) {
      setState(() {
        _centerX -= delta.dx / _scale;
        _centerY += delta.dy / _scale;
      });
    }
    if (details.scale != _lastScale) {
      final focal = details.localFocalPoint;
      final gx = _centerX + (focal.dx - size.width / 2) / _scale;
      final gy = _centerY - (focal.dy - size.height / 2) / _scale;
      final next = (_scale * details.scale / _lastScale).clamp(8.0, 900.0);
      setState(() {
        _scale = next;
        _centerX = gx - (focal.dx - size.width / 2) / _scale;
        _centerY = gy + (focal.dy - size.height / 2) / _scale;
      });
      _lastScale = details.scale;
    }
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _selectedId = null;
      _pendingId = null;
      _previewGraph = null;
    });
  }

  void _resetView() {
    setState(() {
      _centerX = 0;
      _centerY = 0;
      _scale = 54;
    });
  }

  String _hintFor(L10n l10n) {
    switch (_tool) {
      case GeometryTool.select:
        return l10n.t('geometry.hint.select');
      case GeometryTool.point:
        return l10n.t('geometry.hint.point');
      case GeometryTool.segment:
        return _pendingId == null
            ? l10n.t('geometry.hint.segment1')
            : l10n.t('geometry.hint.segment2');
      case GeometryTool.circle:
        return _pendingId == null
            ? l10n.t('geometry.hint.circle1')
            : l10n.t('geometry.hint.circle2');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = AppScope.of(context);
    final l10n = context.l10n;

    return AppPageScaffold(
      child: Column(
        children: [
          AppTopBar(
            title: l10n.t('geometry.title'),
            subtitle: l10n.t('geometry.subtitle'),
            actions: [
              CircleActionButton(
                icon: Icons.center_focus_strong_rounded,
                tooltip: l10n.t('geometry.resetView'),
                onTap: _resetView,
              ),
              CircleActionButton(
                icon: Icons.delete_outline_rounded,
                tooltip: l10n.t('geometry.clear'),
                onTap: _clear,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedControl<GeometryTool>(
                    value: _tool,
                    height: 42,
                    onChanged: (tool) => setState(() {
                      _tool = tool;
                      _pendingId = null;
                      _previewGraph = null;
                    }),
                    options: [
                      SegmentOption(
                        value: GeometryTool.select,
                        label: l10n.t('geometry.select'),
                        icon: Icons.near_me_rounded,
                      ),
                      SegmentOption(
                        value: GeometryTool.point,
                        label: l10n.t('geometry.point'),
                        icon: Icons.circle,
                      ),
                      SegmentOption(
                        value: GeometryTool.segment,
                        label: l10n.t('geometry.segment'),
                        icon: Icons.show_chart_rounded,
                      ),
                      SegmentOption(
                        value: GeometryTool.circle,
                        label: l10n.t('geometry.circle'),
                        icon: Icons.circle_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _SnapToggle(
                  enabled: _snap,
                  onChanged: (value) => setState(() => _snap = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: GlassPanel(
                padding: EdgeInsets.zero,
                radius: 24,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      return Listener(
                        onPointerHover: (event) =>
                            _updatePreview(event.localPosition, size),
                        onPointerMove: (event) =>
                            _updatePreview(event.localPosition, size),
                        onPointerSignal: (event) {
                          if (event is PointerScrollEvent) {
                            final focal = event.localPosition;
                            final gx =
                                _centerX + (focal.dx - size.width / 2) / _scale;
                            final gy =
                                _centerY -
                                (focal.dy - size.height / 2) / _scale;
                            final factor = math.exp(
                              -event.scrollDelta.dy * 0.0016,
                            );
                            setState(() {
                              _scale = (_scale * factor).clamp(8.0, 900.0);
                              _centerX =
                                  gx - (focal.dx - size.width / 2) / _scale;
                              _centerY =
                                  gy + (focal.dy - size.height / 2) / _scale;
                            });
                          }
                        },
                        child: MouseRegion(
                          cursor: _tool == GeometryTool.select
                              ? SystemMouseCursors.grab
                              : SystemMouseCursors.precise,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (details) =>
                                _handleTap(details.localPosition, size),
                            onLongPressStart: (details) =>
                                _handleLongPress(details.localPosition, size),
                            onScaleStart: (details) =>
                                _handleScaleStart(details, size),
                            onScaleUpdate: (details) =>
                                _handleScaleUpdate(details, size),
                            onScaleEnd: (_) => _dragId = null,
                            child: AnimatedBuilder(
                              animation: _controller,
                              builder: (context, _) {
                                return Stack(
                                  children: [
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: GeometryPainter(
                                          controller: _controller,
                                          centerX: _centerX,
                                          centerY: _centerY,
                                          scale: _scale,
                                          gridColor: palette.textPrimary,
                                          axisColor: palette.textSecondary,
                                          labelColor: palette.textTertiary,
                                          pointColor: palette.brand,
                                          segmentColor: palette.brandAlt,
                                          circleColor: AppColors.amber,
                                          selectionColor: palette.brand,
                                          selectedPointId: _selectedId,
                                          pendingPointId: _pendingId,
                                          previewAnchor: _pendingId == null
                                              ? null
                                              : _controller
                                                    .pointById(_pendingId!)
                                                    ?.position,
                                          previewCursor: _previewGraph,
                                          previewCircle:
                                              _tool == GeometryTool.circle,
                                        ),
                                        child: const SizedBox.expand(),
                                      ),
                                    ),
                                    Positioned(
                                      left: 12,
                                      top: 12,
                                      child: _InfoPill(
                                        text:
                                            '${_controller.points.length} ${l10n.t('geometry.points')} · '
                                            '${_controller.segments.length} ${l10n.t('geometry.segments')} · '
                                            '${_controller.circles.length} ${l10n.t('geometry.circles')}',
                                      ),
                                    ),
                                    if (_selectedId != null)
                                      Positioned(
                                        right: 12,
                                        top: 12,
                                        child: _SelectedPill(
                                          point: _controller.pointById(
                                            _selectedId!,
                                          ),
                                          controller: _controller,
                                        ),
                                      ),
                                    Positioned(
                                      right: 12,
                                      bottom: 12,
                                      child: _InfoPill(
                                        text:
                                            settings.angleMode ==
                                                AngleMode.degrees
                                            ? 'DEG'
                                            : 'RAD',
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
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_controller.segments.isNotEmpty ||
                    _controller.circles.isNotEmpty)
                  SizedBox(
                    height: 30,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final segment in _controller.segments)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _MeasureChip(
                              text: _controller.measurementForSegment(segment),
                              color: palette.brandAlt,
                            ),
                          ),
                        for (final circle in _controller.circles)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _MeasureChip(
                              text: _controller.measurementForCircle(circle),
                              color: AppColors.amber,
                            ),
                          ),
                      ],
                    ),
                  ),
                if (_controller.segments.isNotEmpty ||
                    _controller.circles.isNotEmpty)
                  const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: palette.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _hintFor(l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.labelSmall?.copyWith(
                          color: palette.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapToggle extends StatelessWidget {
  const _SnapToggle({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: context.l10n.t('geometry.snap'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!enabled),
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: enabled ? palette.brandSoft : palette.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: enabled
                    ? palette.brand.withValues(alpha: 0.35)
                    : palette.hairline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.grid_4x4_rounded,
                  size: 16,
                  color: enabled ? palette.brand : palette.textTertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.t('geometry.snap'),
                  style: context.textStyles.labelSmall?.copyWith(
                    color: enabled ? palette.brand : palette.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.palette.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.palette.hairline),
      ),
      child: Text(
        text,
        style: context.textStyles.labelSmall?.copyWith(
          color: context.palette.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SelectedPill extends StatelessWidget {
  const _SelectedPill({required this.point, required this.controller});

  final GeoPoint? point;
  final GeometryController controller;

  @override
  Widget build(BuildContext context) {
    final selected = point;
    if (selected == null) return const SizedBox.shrink();
    final label = controller.labelFor(selected);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.palette.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.palette.brand.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        '$label (${formatNumber(selected.position.dx, precision: 4)}, '
        '${formatNumber(selected.position.dy, precision: 4)})',
        style: context.textStyles.labelSmall?.copyWith(
          color: context.palette.brand,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _MeasureChip extends StatelessWidget {
  const _MeasureChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        text,
        style: context.textStyles.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
