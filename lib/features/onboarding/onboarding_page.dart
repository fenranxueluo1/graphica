import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../state/app_settings.dart';
import '../../ui/widgets/ambient_background.dart';
import '../../ui/widgets/brand_mark.dart';
import '../../ui/widgets/frosted_surface.dart';
import '../../ui/widgets/gradient_button.dart';

/// First-run walkthrough shown once, then dismissible from settings.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onFinish});

  final VoidCallback onFinish;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _pageCount = 7;
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index >= _pageCount - 1) {
      widget.onFinish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_index == 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final last = _index == _pageCount - 1;

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final pages = PageView.builder(
                controller: _controller,
                itemCount: _pageCount,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) {
                  return _PageCard(index: index, wide: wide);
                },
              );

              return Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const BrandMark(size: 34),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.t('app.name'),
                                  style: context.textStyles.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  l10n.t('app.tagline'),
                                  style: context.textStyles.labelSmall
                                      ?.copyWith(
                                        color: context.palette.textTertiary,
                                      ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (!last)
                              TextButton(
                                onPressed: widget.onFinish,
                                child: Text(l10n.t('onboarding.skip')),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: wide
                              ? Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(
                                      width: 320,
                                      child: _HeroPanel(),
                                    ),
                                    const SizedBox(width: 18),
                                    Expanded(child: pages),
                                  ],
                                )
                              : pages,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _Dots(count: _pageCount, index: _index),
                            const Spacer(),
                            if (_index > 0) ...[
                              SoftButton(
                                label: l10n.t('onboarding.back'),
                                height: 46,
                                onPressed: _back,
                              ),
                              const SizedBox(width: 10),
                            ],
                            GradientButton(
                              label: last
                                  ? l10n.t('onboarding.start')
                                  : l10n.t('onboarding.next'),
                              icon: last
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              height: 46,
                              onPressed: _next,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PageCard extends StatelessWidget {
  const _PageCard({required this.index, required this.wide});

  final int index;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final modules = [
      _ModuleData(
        icon: Icons.show_chart_rounded,
        color: const Color(0xFF5EA8FF),
        title: l10n.t('section.graph.label'),
        description: l10n.t('section.graph.description'),
        steps: [
          l10n.t('onboarding.module.graph.step1'),
          l10n.t('onboarding.module.graph.step2'),
          l10n.t('onboarding.module.graph.step3'),
          l10n.t('onboarding.module.graph.step4'),
        ],
      ),
      _ModuleData(
        icon: Icons.calculate_rounded,
        color: const Color(0xFF22D3EE),
        title: l10n.t('section.calculator.label'),
        description: l10n.t('section.calculator.description'),
        steps: [
          l10n.t('onboarding.module.calculator.step1'),
          l10n.t('onboarding.module.calculator.step2'),
          l10n.t('onboarding.module.calculator.step3'),
        ],
      ),
      _ModuleData(
        icon: Icons.grid_on_rounded,
        color: const Color(0xFF8B5CF6),
        title: l10n.t('section.matrix.label'),
        description: l10n.t('section.matrix.description'),
        steps: [
          l10n.t('onboarding.module.matrix.step1'),
          l10n.t('onboarding.module.matrix.step2'),
          l10n.t('onboarding.module.matrix.step3'),
        ],
      ),
      _ModuleData(
        icon: Icons.polyline_rounded,
        color: const Color(0xFF34D399),
        title: l10n.t('section.geometry.label'),
        description: l10n.t('section.geometry.description'),
        steps: [
          l10n.t('onboarding.module.geometry.step1'),
          l10n.t('onboarding.module.geometry.step2'),
          l10n.t('onboarding.module.geometry.step3'),
        ],
      ),
      _ModuleData(
        icon: Icons.view_in_ar_rounded,
        color: const Color(0xFFF472B6),
        title: l10n.t('section.threeD.label'),
        description: l10n.t('section.threeD.description'),
        steps: [
          l10n.t('onboarding.module.surface.step1'),
          l10n.t('onboarding.module.surface.step2'),
          l10n.t('onboarding.module.surface.step3'),
          l10n.t('onboarding.module.surface.step4'),
        ],
      ),
    ];
    final isWelcome = index == 0;
    final isPlatform = index == 6;
    final module = index >= 1 && index <= 5 ? modules[index - 1] : null;
    final title = isWelcome
        ? l10n.t('onboarding.page.welcome.title')
        : isPlatform
        ? l10n.t('onboarding.page.platform.title')
        : module!.title;
    final body = isWelcome
        ? l10n.t('onboarding.page.welcome.body')
        : isPlatform
        ? l10n.t('onboarding.page.platform.body')
        : module!.description;

    return FrostedSurface(
      radius: 30,
      opacity: 0.20,
      blur: 30,
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isWelcome && !wide) ...[
                    const BrandMark(size: 68),
                    const SizedBox(height: 18),
                  ],
                  if (isWelcome) ...[
                    _VersionBadge(label: l10n.t('onboarding.version')),
                    const SizedBox(height: 14),
                  ],
                  if (module != null)
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: module.color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: module.color.withValues(alpha: 0.30),
                            ),
                          ),
                          child: Icon(
                            module.icon,
                            size: 23,
                            color: module.color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: context.textStyles.displaySmall?.copyWith(
                              fontSize: wide ? 30 : 26,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      title,
                      style: context.textStyles.displaySmall?.copyWith(
                        fontSize: wide ? 32 : 27,
                        height: 1.15,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    style: context.textStyles.bodyLarge?.copyWith(
                      color: palette.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (isWelcome)
                    const _WelcomeStats()
                  else if (module != null)
                    _ModuleGuide(module: module)
                  else
                    const _PlatformCards(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    return FrostedSurface(
      radius: 30,
      opacity: 0.22,
      blur: 30,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandMark(size: 78),
          const SizedBox(height: 20),
          Text(
            l10n.t('app.name'),
            style: context.textStyles.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.t('app.tagline'),
            style: context.textStyles.titleMedium?.copyWith(
              color: palette.brand,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _MiniIcon(
                icon: Icons.show_chart_rounded,
                color: Color(0xFF5EA8FF),
              ),
              _MiniIcon(
                icon: Icons.calculate_rounded,
                color: Color(0xFF22D3EE),
              ),
              _MiniIcon(icon: Icons.grid_on_rounded, color: Color(0xFF8B5CF6)),
              _MiniIcon(icon: Icons.polyline_rounded, color: Color(0xFF34D399)),
              _MiniIcon(
                icon: Icons.view_in_ar_rounded,
                color: Color(0xFFF472B6),
              ),
              _MiniIcon(
                icon: Icons.functions_rounded,
                color: Color(0xFFFBBF24),
              ),
            ],
          ),
          const Spacer(),
          Text(
            l10n.t('onboarding.version'),
            style: context.textStyles.labelSmall?.copyWith(
              color: palette.textTertiary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  const _MiniIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _VersionBadge extends StatelessWidget {
  const _VersionBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.brandSoft,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: palette.brand.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: context.textStyles.labelSmall?.copyWith(
          color: palette.brand,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _WelcomeStats extends StatelessWidget {
  const _WelcomeStats();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _Stat(icon: Icons.widgets_rounded, label: l10n.t('home.modules')),
        _Stat(
          icon: Icons.devices_rounded,
          label: l10n.t('onboarding.statsPlatforms'),
        ),
        _Stat(
          icon: Icons.volunteer_activism_outlined,
          label: l10n.t('onboarding.version'),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: palette.brand),
          const SizedBox(width: 7),
          Text(
            label,
            style: context.textStyles.labelMedium?.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleData {
  const _ModuleData({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.steps,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final List<String> steps;
}

class _ModuleGuide extends StatelessWidget {
  const _ModuleGuide({required this.module});

  final _ModuleData module;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.t('onboarding.howTo'),
          style: context.textStyles.labelMedium?.copyWith(
            color: context.palette.textTertiary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < module.steps.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _StepRow(number: i + 1, text: module.steps[i], color: module.color),
        ],
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.text,
    required this.color,
  });

  final int number;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.14),
            border: Border.all(color: color.withValues(alpha: 0.30)),
          ),
          child: Text(
            '$number',
            style: context.textStyles.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.palette.textSecondary,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlatformCards extends StatelessWidget {
  const _PlatformCards();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final cards = [
      (Icons.phone_android_rounded, l10n.t('onboarding.platform.harmony')),
      (Icons.desktop_windows_rounded, l10n.t('onboarding.platform.desktop')),
      (Icons.phone_iphone_rounded, l10n.t('onboarding.platform.mobile')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final card in cards)
              Container(
                width: 190,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.hairline),
                ),
                child: Row(
                  children: [
                    Icon(card.$1, size: 20, color: palette.brand),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        card.$2,
                        style: context.textStyles.labelSmall?.copyWith(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          l10n.t('onboarding.ready'),
          style: context.textStyles.titleSmall?.copyWith(
            color: palette.brand,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == index ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index
                  ? palette.brand
                  : palette.textTertiary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ],
    );
  }
}
