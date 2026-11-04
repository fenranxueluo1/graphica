import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_info.dart';
import '../../core/app_section.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../state/app_settings.dart';
import '../../ui/widgets/ambient_background.dart';
import '../../ui/widgets/app_page_scaffold.dart';
import '../../ui/widgets/brand_mark.dart';
import '../../ui/widgets/frosted_surface.dart';
import '../../ui/widgets/gradient_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onNavigate});

  final ValueChanged<AppSection> onNavigate;

  static const _features = <_Feature>[
    _Feature(
      section: AppSection.graph,
      icon: Icons.show_chart_rounded,
      titleKey: 'home.feature.graph.title',
      descriptionKey: 'home.feature.graph.desc',
      accent: _FeatureAccent.brand,
    ),
    _Feature(
      section: AppSection.calculator,
      icon: Icons.functions_rounded,
      titleKey: 'home.feature.scientific.title',
      descriptionKey: 'home.feature.scientific.desc',
      accent: _FeatureAccent.cyan,
    ),
    _Feature(
      section: AppSection.calculator,
      icon: Icons.calculate_rounded,
      titleKey: 'home.feature.basic.title',
      descriptionKey: 'home.feature.basic.desc',
      accent: _FeatureAccent.amber,
    ),
    _Feature(
      section: AppSection.matrix,
      icon: Icons.grid_on_rounded,
      titleKey: 'home.feature.matrix.title',
      descriptionKey: 'home.feature.matrix.desc',
      accent: _FeatureAccent.violet,
    ),
    _Feature(
      section: AppSection.geometry,
      icon: Icons.polyline_rounded,
      titleKey: 'home.feature.geometry.title',
      descriptionKey: 'home.feature.geometry.desc',
      accent: _FeatureAccent.green,
    ),
    _Feature(
      section: AppSection.threeD,
      icon: Icons.view_in_ar_rounded,
      titleKey: 'home.feature.3d.title',
      descriptionKey: 'home.feature.3d.desc',
      accent: _FeatureAccent.pink,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = AppScope.of(context);

    return AppPageScaffold(
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopStrip(settings: settings),
                  const SizedBox(height: 22),
                  Reveal(
                    child: _Hero(
                      onNavigate: onNavigate,
                      showArt: MediaQuery.sizeOf(context).width >= 820,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.t('home.everything'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        context.l10n.t('home.modules'),
                        style: context.textStyles.labelMedium?.copyWith(
                          color: palette.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final columns = width >= 980
                          ? 3
                          : width >= 620
                          ? 2
                          : 1;
                      const gap = 14.0;
                      final itemWidth = (width - gap * (columns - 1)) / columns;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (var i = 0; i < _features.length; i++)
                            SizedBox(
                              width: itemWidth,
                              child: Reveal(
                                delay: Duration(milliseconds: 60 * i),
                                child: _FeatureCard(
                                  feature: _features[i],
                                  onTap: () => onNavigate(_features[i].section),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 26),
                  const _Footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopStrip extends StatelessWidget {
  const _TopStrip({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        const BrandMark(size: 40),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.t('app.name'),
              style: context.textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              context.l10n.t('app.tagline'),
              style: context.textStyles.labelSmall?.copyWith(
                color: palette.textTertiary,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: palette.brandSoft,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: palette.brand.withValues(alpha: 0.3)),
          ),
          child: Text(
            'MIT',
            style: context.textStyles.labelSmall?.copyWith(
              color: palette.brand,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Toggle theme',
          child: IconButton(
            onPressed: () {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              settings.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
            },
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onNavigate, required this.showArt});

  final ValueChanged<AppSection> onNavigate;
  final bool showArt;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              context.l10n.t('home.openSource'),
              style: context.textStyles.labelSmall?.copyWith(
                color: palette.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          context.l10n.t('home.title'),
          style: context.textStyles.displayMedium?.copyWith(
            fontSize: showArt ? 44 : 36,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Text(
            context.l10n.t('home.subtitle'),
            style: context.textStyles.bodyMedium?.copyWith(
              color: palette.textSecondary,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            GradientButton(
              label: context.l10n.t('home.startGraphing'),
              icon: Icons.show_chart_rounded,
              height: 48,
              onPressed: () => onNavigate(AppSection.graph),
            ),
            SoftButton(
              label: context.l10n.t('home.explore3d'),
              icon: Icons.view_in_ar_rounded,
              height: 48,
              onPressed: () => onNavigate(AppSection.threeD),
            ),
          ],
        ),
      ],
    );

    return FrostedSurface(
      radius: 30,
      opacity: 0.18,
      blur: 32,
      padding: const EdgeInsets.all(26),
      child: showArt
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: textColumn),
                const SizedBox(width: 26),
                SizedBox(
                  width: 320,
                  height: 230,
                  child: CustomPaint(
                    painter: _HeroArtPainter(
                      brand: palette.brand,
                      alt: palette.brandAlt,
                      grid: palette.textPrimary,
                    ),
                  ),
                ),
              ],
            )
          : textColumn,
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature, required this.onTap});

  final _Feature feature;
  final VoidCallback onTap;

  Color _resolve(AppPalette palette) {
    return switch (feature.accent) {
      _FeatureAccent.brand => palette.brand,
      _FeatureAccent.cyan => palette.brandAlt,
      _FeatureAccent.amber => AppColors.amber,
      _FeatureAccent.violet => AppColors.violet,
      _FeatureAccent.green => AppColors.green,
      _FeatureAccent.pink => const Color(0xFFF472B6),
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = _resolve(palette);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Haptics.tap();
          onTap();
        },
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.surface.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.hairline),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 30,
                spreadRadius: -18,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: accent.withValues(alpha: 0.28)),
                ),
                child: Icon(feature.icon, size: 21, color: accent),
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.t(feature.titleKey),
                style: context.textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.t(feature.descriptionKey),
                style: context.textStyles.bodySmall?.copyWith(
                  color: palette.textTertiary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    context.l10n.t('home.open'),
                    style: context.textStyles.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.hairline)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          Text(
            '${context.l10n.t('app.name')} ${AppInfo.version} · ${AppInfo.license}',
            style: context.textStyles.labelSmall?.copyWith(
              color: palette.textTertiary,
            ),
          ),
          Text(
            context.l10n.t('home.footer.platforms'),
            style: context.textStyles.labelSmall?.copyWith(
              color: palette.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroArtPainter extends CustomPainter {
  _HeroArtPainter({required this.brand, required this.alt, required this.grid});

  final Color brand;
  final Color alt;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(22));
    canvas.save();
    canvas.clipRRect(rrect);

    final gridPaint = Paint()
      ..color = grid.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y <= size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final axisPaint = Paint()
      ..color = grid.withValues(alpha: 0.22)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      axisPaint,
    );

    _curve(canvas, size, (t) => math.sin(t * math.pi * 2) * 0.34 + 0.5, brand);
    _curve(canvas, size, (t) => math.cos(t * math.pi * 1.4) * 0.26 + 0.5, alt);

    canvas.restore();
  }

  void _curve(
    Canvas canvas,
    Size size,
    double Function(double) fn,
    Color color,
  ) {
    final path = Path();
    for (var i = 0; i <= 120; i++) {
      final t = i / 120;
      final x = size.width * t;
      final y = size.height * (1 - fn(t));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.18),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _HeroArtPainter oldDelegate) =>
      oldDelegate.brand != brand || oldDelegate.alt != alt;
}

enum _FeatureAccent { brand, cyan, amber, violet, green, pink }

class _Feature {
  const _Feature({
    required this.section,
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
    required this.accent,
  });

  final AppSection section;
  final IconData icon;
  final String titleKey;
  final String descriptionKey;
  final _FeatureAccent accent;
}
