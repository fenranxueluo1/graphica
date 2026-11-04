import 'package:flutter/material.dart';

import '../../core/math/expression.dart';
import '../../core/storage/app_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/png_export.dart';
import '../../state/app_settings.dart';
import '../../ui/widgets/app_page_scaffold.dart';
import '../../ui/widgets/app_top_bar.dart';
import '../../ui/widgets/glass_panel.dart';
import 'graph_canvas.dart';
import 'graph_controller.dart';
import 'graph_expression_panel.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key, required this.store});

  final AppStore store;

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  late final GraphController _controller = GraphController(store: widget.store);
  final GlobalKey _exportKey = GlobalKey();
  Size _canvasSize = const Size(800, 600);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openExpressions() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.88,
          child: Container(
            decoration: BoxDecoration(
              color: context.palette.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(color: context.palette.hairline),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                child: GraphExpressionPanel(
                  controller: _controller,
                  onClose: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportPng() async {
    final l10n = context.l10n;
    final directory = await widget.store.exportDirectory();
    final path = await exportPng(_exportKey, directory, 'shuhui-graph');
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

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context);
    final l10n = context.l10n;

    return AppPageScaffold(
      child: Column(
        children: [
          AppTopBar(
            title: l10n.t('graph.title'),
            subtitle: l10n.t('graph.subtitle'),
            actions: [
              CircleActionButton(
                icon: Icons.zoom_in_rounded,
                tooltip: l10n.t('graph.zoomIn'),
                onTap: () => _controller.zoomBy(1.35),
              ),
              CircleActionButton(
                icon: Icons.zoom_out_rounded,
                tooltip: l10n.t('graph.zoomOut'),
                onTap: () => _controller.zoomBy(1 / 1.35),
              ),
              CircleActionButton(
                icon: Icons.center_focus_strong_rounded,
                tooltip: l10n.t('graph.fit'),
                onTap: () => _controller.fitView(_canvasSize),
              ),
              CircleActionButton(
                icon: Icons.restart_alt_rounded,
                tooltip: l10n.t('graph.reset'),
                onTap: _controller.resetView,
              ),
              CircleActionButton(
                icon: Icons.download_rounded,
                tooltip: l10n.t('graph.export'),
                onTap: _exportPng,
              ),
            ],
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 940;
                final graph = RepaintBoundary(
                  key: _exportKey,
                  child: GlassPanel(
                    padding: EdgeInsets.zero,
                    radius: 24,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: LayoutBuilder(
                        builder: (context, inner) {
                          _canvasSize = Size(inner.maxWidth, inner.maxHeight);
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: GraphCanvas(
                                  controller: _controller,
                                  angleMode: settings.angleMode,
                                ),
                              ),
                              Positioned(
                                right: 14,
                                bottom: 14,
                                child: _ModeBadge(
                                  label: settings.angleMode == AngleMode.degrees
                                      ? 'DEG'
                                      : 'RAD',
                                ),
                              ),
                              if (!wide)
                                Positioned(
                                  left: 14,
                                  top: 14,
                                  child: _ExpressionsButton(
                                    count: _controller.expressions.length,
                                    onTap: _openExpressions,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                );

                if (wide) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(child: graph),
                        const SizedBox(width: 14),
                        SizedBox(
                          width: 360,
                          child: GlassPanel(
                            padding: const EdgeInsets.all(18),
                            radius: 24,
                            child: GraphExpressionPanel(
                              controller: _controller,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: graph,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.label});

  final String label;

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
        label,
        style: context.textStyles.labelSmall?.copyWith(
          color: context.palette.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _ExpressionsButton extends StatelessWidget {
  const _ExpressionsButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.palette.surface.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.palette.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.functions_rounded,
                size: 16,
                color: context.palette.brand,
              ),
              const SizedBox(width: 6),
              Text(
                '${context.l10n.t('graph.expressions')} · $count',
                style: context.textStyles.labelMedium?.copyWith(
                  color: context.palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
