import 'package:flutter/material.dart';

import '../../core/app_info.dart';
import '../../core/math/expression.dart';
import '../../core/theme/app_palette.dart';
import '../../l10n/l10n.dart';
import '../../state/app_settings.dart';
import '../../ui/widgets/app_page_scaffold.dart';
import '../../ui/widgets/app_top_bar.dart';
import '../../ui/widgets/brand_mark.dart';
import '../../ui/widgets/glass_panel.dart';
import '../../ui/widgets/segmented_control.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context);
    final palette = context.palette;
    final l10n = context.l10n;

    return AppPageScaffold(
      child: Column(
        children: [
          AppTopBar(
            title: l10n.t('settings.title'),
            subtitle: l10n.t('settings.subtitle'),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlassPanel(
                        padding: const EdgeInsets.all(20),
                        radius: 26,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(
                              icon: Icons.palette_outlined,
                              title: l10n.t('settings.appearance'),
                            ),
                            const SizedBox(height: 14),
                            SegmentedControl<ThemeMode>(
                              value: settings.themeMode,
                              onChanged: settings.setThemeMode,
                              options: [
                                SegmentOption(
                                  value: ThemeMode.system,
                                  label: l10n.t('settings.system'),
                                  icon: Icons.brightness_auto_outlined,
                                ),
                                SegmentOption(
                                  value: ThemeMode.light,
                                  label: l10n.t('settings.light'),
                                  icon: Icons.light_mode_outlined,
                                ),
                                SegmentOption(
                                  value: ThemeMode.dark,
                                  label: l10n.t('settings.dark'),
                                  icon: Icons.dark_mode_outlined,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              l10n.t('settings.accent'),
                              style: context.textStyles.labelMedium?.copyWith(
                                color: palette.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                for (
                                  var i = 0;
                                  i < AccentPreset.presets.length;
                                  i++
                                )
                                  _AccentSwatch(
                                    preset: AccentPreset.presets[i],
                                    label: l10n.t(
                                      'settings.accent.${AccentPreset.presets[i].id}',
                                    ),
                                    selected: settings.accentIndex == i,
                                    onTap: () => settings.setAccent(i),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            _SettingRow(
                              title: l10n.t('settings.language'),
                              control: SegmentedControl<AppLocale>(
                                value: settings.locale,
                                onChanged: settings.setLocale,
                                options: const [
                                  SegmentOption(
                                    value: AppLocale.zh,
                                    label: '中文',
                                  ),
                                  SegmentOption(
                                    value: AppLocale.en,
                                    label: 'English',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  size: 18,
                                  color: palette.textTertiary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.t('settings.replayGuide'),
                                        style: context.textStyles.labelMedium
                                            ?.copyWith(
                                              color: palette.textPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        l10n.t('settings.guideDesc'),
                                        style: context.textStyles.bodySmall
                                            ?.copyWith(
                                              color: palette.textTertiary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: settings.resetOnboarding,
                                  child: Text(l10n.t('home.open')),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      GlassPanel(
                        padding: const EdgeInsets.all(20),
                        radius: 26,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(
                              icon: Icons.functions_rounded,
                              title: l10n.t('settings.math'),
                            ),
                            const SizedBox(height: 14),
                            _SettingRow(
                              title: l10n.t('settings.angleUnit'),
                              description: l10n.t('settings.angleDesc'),
                              control: SegmentedControl<AngleMode>(
                                value: settings.angleMode,
                                onChanged: settings.setAngleMode,
                                options: [
                                  SegmentOption(
                                    value: AngleMode.radians,
                                    label: l10n.t('settings.radians'),
                                  ),
                                  SegmentOption(
                                    value: AngleMode.degrees,
                                    label: l10n.t('settings.degrees'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            _InfoRow(
                              icon: Icons.calculate_outlined,
                              title: l10n.t('settings.engine'),
                              description: l10n.t('settings.engineDesc'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      GlassPanel(
                        padding: const EdgeInsets.all(20),
                        radius: 26,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(
                              icon: Icons.info_outline_rounded,
                              title: l10n.t('settings.about'),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const BrandMark(size: 52),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.t('app.name'),
                                        style: context.textStyles.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${l10n.t('settings.version')} '
                                        '${AppInfo.version} · ${AppInfo.license}',
                                        style: context.textStyles.bodySmall
                                            ?.copyWith(
                                              color: palette.textTertiary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                _LicenseBadge(
                                  label: 'MIT',
                                  onTap: () => _showLicense(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              l10n.t('home.subtitle'),
                              style: context.textStyles.bodySmall?.copyWith(
                                color: palette.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _InfoRow(
                              icon: Icons.devices_rounded,
                              title: l10n.t('settings.platforms'),
                              description: l10n.t('settings.platformsDesc'),
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.volunteer_activism_outlined,
                              title: l10n.t('settings.openSource'),
                              description: l10n.t('settings.openSourceDesc'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          '${l10n.t('app.name')} ${AppInfo.version} · '
                          '${AppInfo.copyright}',
                          style: context.textStyles.labelSmall?.copyWith(
                            color: palette.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLicense(BuildContext context) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.t('settings.license')),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: SelectableText(
                AppInfo.licenseText,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.palette.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.t('settings.close')),
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: context.palette.brandSoft,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: context.palette.brand),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.preset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AccentPreset preset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? context.palette.textPrimary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [preset.color, preset.alt],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: preset.color.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: selected
                ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}

class _LicenseBadge extends StatelessWidget {
  const _LicenseBadge({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: context.palette.brandSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: context.palette.brand.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: context.textStyles.labelMedium?.copyWith(
              color: context.palette.brand,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.control,
    this.description,
  });

  final String title;
  final String? description;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textStyles.bodyMedium?.copyWith(
            color: palette.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 2),
          Text(
            description!,
            style: context.textStyles.bodySmall?.copyWith(
              color: palette.textTertiary,
            ),
          ),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              text,
              const SizedBox(height: 12),
              control,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: text),
            const SizedBox(width: 16),
            SizedBox(width: 240, child: control),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: palette.textTertiary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textStyles.labelMedium?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: context.textStyles.bodySmall?.copyWith(
                  color: palette.textTertiary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
