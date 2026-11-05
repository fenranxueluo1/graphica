import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/math/latex.dart';
import '../../core/storage/app_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/png_export.dart';
import '../../state/app_settings.dart';
import '../../ui/widgets/app_page_scaffold.dart';
import '../../ui/widgets/app_top_bar.dart';
import '../../ui/widgets/glass_panel.dart';
import '../../ui/widgets/gradient_button.dart';
import '../../ui/widgets/math_view.dart';
import 'surface3d_controller.dart';
import 'surface3d_painter.dart';
import 'surface3d_panel.dart';

class Surface3DPage extends StatefulWidget {
  const Surface3DPage({super.key, required this.store});

  final AppStore store;

  @override
  State<Surface3DPage> createState() => _Surface3DPageState();
}

class _Surface3DPageState extends State<Surface3DPage> {
  late final Surface3DController _controller = Surface3DController(
    store: widget.store,
  );
  late final TextEditingController _xMin = TextEditingController(
    text: _format(_controller.xMin),
  );
  late final TextEditingController _xMax = TextEditingController(
    text: _format(_controller.xMax),
  );
  late final TextEditingController _yMin = TextEditingController(
    text: _format(_controller.yMin),
  );
  late final TextEditingController _yMax = TextEditingController(
    text: _format(_controller.yMax),
  );

  final GlobalKey _exportKey = GlobalKey();
  final ValueNotifier<_Camera> _camera = ValueNotifier(
    const _Camera(0.7, -0.5, 1),
  );
  double _lastScale = 1;

  @override
  void dispose() {
    _controller.dispose();
    _camera.dispose();
    _xMin.dispose();
    _xMax.dispose();
    _yMin.dispose();
    _yMax.dispose();
    super.dispose();
  }

  String _format(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toString();
  }

  void _resetCamera() {
    _camera.value = const _Camera(0.7, -0.5, 1);
  }

  Future<void> _exportPng() async {
    final l10n = context.l10n;
    final directory = await widget.store.exportDirectory();
    final path = await exportPng(_exportKey, directory, 'shuhui-surface');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          path == null
              ? l10n.t('graph.exportFailed')
              : '${l10n.t('graph.exported')} $path',
        ),
      ),
    );
  }

  Widget _panel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SurfaceExpressionPanel(controller: _controller),
        const SizedBox(height: 16),
        Divider(color: context.palette.hairline, height: 1),
        const SizedBox(height: 16),
        SurfaceOptionsPanel(
          controller: _controller,
          xMin: _xMin,
          xMax: _xMax,
          yMin: _yMin,
          yMax: _yMax,
        ),
      ],
    );
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final l10n = context.l10n;
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  color: context.palette.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border.all(color: context.palette.hairline),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _panel(context),
                        const SizedBox(height: 16),
                        GradientButton(
                          label: l10n.t('surface.done'),
                          icon: Icons.check_rounded,
                          expanded: true,
                          height: 48,
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<SurfaceLayer> get _layers => [
    for (final expression in _controller.visibleLayers)
      SurfaceLayer(expression: expression.input, color: expression.color),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    final palette = context.palette;
    final settings = AppScope.of(context);
    final l10n = context.l10n;
    final layers = _layers;

    Widget buildCanvas(bool wide) {
      return Padding(
        padding: EdgeInsets.zero,
        child: RepaintBoundary(
          key: _exportKey,
          child: GlassPanel(
            padding: EdgeInsets.zero,
            radius: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: LayoutBuilder(
                builder: (context, inner) {
                  final size = Size(inner.maxWidth, inner.maxHeight);
                  return Listener(
                    onPointerSignal: (event) {
                      if (event is PointerScrollEvent) {
                        final camera = _camera.value;
                        _camera.value = _Camera(
                          camera.yaw,
                          camera.pitch,
                          (camera.zoom *
                                  math.exp(-event.scrollDelta.dy * 0.0016))
                              .clamp(0.45, 3.2),
                        );
                      }
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: (_) => _lastScale = 1,
                      onScaleUpdate: (details) {
                        final camera = _camera.value;
                        var yaw = camera.yaw;
                        var pitch = camera.pitch;
                        var zoom = camera.zoom;
                        final delta = details.focalPointDelta;
                        if (delta != Offset.zero) {
                          yaw += delta.dx * 0.009;
                          pitch += delta.dy * 0.007;
                        }
                        if (details.scale != _lastScale) {
                          zoom = (zoom * details.scale / _lastScale).clamp(
                            0.45,
                            3.2,
                          );
                          _lastScale = details.scale;
                        }
                        _camera.value = _Camera(yaw, pitch, zoom);
                      },
                      onDoubleTap: _resetCamera,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: RepaintBoundary(
                              child: ValueListenableBuilder<_Camera>(
                                valueListenable: _camera,
                                builder: (context, camera, _) {
                                  return CustomPaint(
                                    painter: Surface3DPainter(
                                      layers: layers,
                                      angleMode: settings.angleMode,
                                      xMin: _controller.xMin,
                                      xMax: _controller.xMax,
                                      yMin: _controller.yMin,
                                      yMax: _controller.yMax,
                                      resolution: _controller.resolution
                                          .round(),
                                      yaw: camera.yaw,
                                      pitch: camera.pitch,
                                      zoom: camera.zoom,
                                      wireframe: _controller.wireframe,
                                      axisColor: palette.textSecondary,
                                      labelColor: palette.textTertiary,
                                    ),
                                    child: const SizedBox.expand(),
                                  );
                                },
                              ),
                            ),
                          ),
                          if (layers.isNotEmpty)
                            Positioned(
                              left: 14,
                              top: 14,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: size.width * 0.62,
                                ),
                                child: _FormulaStack(layers: layers),
                              ),
                            ),
                          Positioned(
                            left: 14,
                            bottom: 14,
                            child: _Pill(
                              icon: Icons.threed_rotation_rounded,
                              text:
                                  '${_controller.resolution.round()} × ${_controller.resolution.round()} · '
                                  '${_controller.wireframe ? l10n.t('surface.wireframe') : l10n.t('surface.shaded')}',
                            ),
                          ),
                          if (!wide)
                            Positioned(
                              right: 14,
                              bottom: 14,
                              child: _SettingsFab(
                                label: l10n.t('surface.settingsButton'),
                                onTap: _openSettings,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    return AppPageScaffold(
      child: Column(
        children: [
          AppTopBar(
            title: l10n.t('surface.title'),
            subtitle: l10n.t('surface.subtitle'),
            actions: [
              CircleActionButton(
                icon: Icons.restart_alt_rounded,
                tooltip: l10n.t('surface.resetCamera'),
                onTap: _resetCamera,
              ),
              CircleActionButton(
                icon: Icons.download_rounded,
                tooltip: l10n.t('surface.export'),
                onTap: _exportPng,
              ),
            ],
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                final padded = Padding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 16 : 12,
                    0,
                    wide ? 0 : 12,
                    16,
                  ),
                  child: buildCanvas(wide),
                );

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: padded),
                      SizedBox(
                        width: 372,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
                          child: GlassPanel(
                            padding: const EdgeInsets.all(18),
                            radius: 24,
                            child: SingleChildScrollView(
                              child: _panel(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return padded;
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Camera {
  const _Camera(this.yaw, this.pitch, this.zoom);

  final double yaw;
  final double pitch;
  final double zoom;
}

class _FormulaStack extends StatelessWidget {
  const _FormulaStack({required this.layers});

  final List<SurfaceLayer> layers;

  @override
  Widget build(BuildContext context) {
    final shown = layers.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          _FormulaPill(
            color: shown[i].color,
            latex: expressionToLatex(shown[i].expression),
            fallback: 'z = ${shown[i].expression}',
          ),
        ],
        if (layers.length > shown.length) ...[
          const SizedBox(height: 6),
          _Pill(
            icon: Icons.layers_rounded,
            text: '+${layers.length - shown.length}',
          ),
        ],
      ],
    );
  }
}

class _FormulaPill extends StatelessWidget {
  const _FormulaPill({
    required this.color,
    required this.latex,
    required this.fallback,
  });

  final Color color;
  final String? latex;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: MathView(
                latex: latex == null ? null : 'z = $latex',
                fallback: fallback,
                fontSize: 14,
                color: palette.textPrimary,
                scrollable: false,
                display: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: palette.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.labelSmall?.copyWith(
                color: palette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsFab extends StatelessWidget {
  const _SettingsFab({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [palette.brand, palette.brandAlt]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: palette.brand.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tune_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: context.textStyles.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
