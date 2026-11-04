import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_info.dart';
import '../../core/app_section.dart';
import '../../core/storage/app_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../state/app_settings.dart';
import '../../features/calculator/calculator_page.dart';
import '../../features/geometry/geometry_page.dart';
import '../../features/graphing/graph_page.dart';
import '../../features/home/home_page.dart';
import '../../features/matrix/matrix_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/three_d/surface3d_page.dart';
import '../widgets/brand_mark.dart';
import '../widgets/frosted_surface.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});

  final AppStore store;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppSection _section = AppSection.home;

  static const _primary = <AppSection>[
    AppSection.home,
    AppSection.graph,
    AppSection.calculator,
    AppSection.matrix,
  ];

  void _select(AppSection section) {
    if (_section == section) return;
    Haptics.tap();
    setState(() => _section = section);
  }

  IconData _iconFor(AppSection section) => switch (section) {
    AppSection.home => Icons.home_rounded,
    AppSection.graph => Icons.show_chart_rounded,
    AppSection.calculator => Icons.calculate_rounded,
    AppSection.matrix => Icons.grid_on_rounded,
    AppSection.geometry => Icons.polyline_rounded,
    AppSection.threeD => Icons.view_in_ar_rounded,
    AppSection.settings => Icons.settings_rounded,
  };

  void _showMoreSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: sheetContext.palette.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: sheetContext.palette.hairline),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: sheetContext.palette.hairline,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    sheetContext.l10n.t('shell.moreTools'),
                    style: sheetContext.textStyles.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final section in const [
                    AppSection.geometry,
                    AppSection.threeD,
                    AppSection.settings,
                  ])
                    _MoreTile(
                      icon: _iconFor(section),
                      section: section,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _select(section);
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context);
    final pages = <Widget>[
      HomePage(onNavigate: _select),
      GraphPage(store: widget.store),
      const CalculatorPage(),
      const MatrixPage(),
      const GeometryPage(),
      Surface3DPage(store: widget.store),
      const SettingsPage(),
    ];

    final layouts = <ShortcutActivator, VoidCallback>{
      for (var i = 0; i < AppSection.values.length; i++) ...{
        SingleActivator(
          LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + i),
          control: true,
        ): () =>
            _select(AppSection.values[i]),
        SingleActivator(
          LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + i),
          meta: true,
        ): () =>
            _select(AppSection.values[i]),
      },
    };

    final shell = CallbackShortcuts(
      bindings: layouts,
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: context.palette.bg,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final content = IndexedStack(
                index: _section.index,
                children: pages,
              );
              if (width >= 1000) {
                return Row(
                  children: [
                    _Sidebar(
                      section: _section,
                      onSelect: _select,
                      iconFor: _iconFor,
                    ),
                    Expanded(child: content),
                  ],
                );
              }
              if (width >= 680) {
                return Row(
                  children: [
                    _Rail(
                      section: _section,
                      onSelect: _select,
                      iconFor: _iconFor,
                    ),
                    Expanded(child: content),
                  ],
                );
              }
              return Column(
                children: [
                  Expanded(child: content),
                  _BottomBar(
                    section: _section,
                    primary: _primary,
                    isMore: !_primary.contains(_section),
                    onSelect: _select,
                    onMore: _showMoreSheet,
                    iconFor: _iconFor,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    if (settings.onboardingComplete) return shell;
    return Stack(
      children: [
        shell,
        Positioned.fill(
          child: OnboardingPage(onFinish: settings.completeOnboarding),
        ),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.section,
    required this.onSelect,
    required this.iconFor,
  });

  final AppSection section;
  final ValueChanged<AppSection> onSelect;
  final IconData Function(AppSection) iconFor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      child: SizedBox(
        width: 248,
        child: FrostedSurface(
          radius: 26,
          opacity: 0.20,
          blur: 30,
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    const BrandMark(size: 38),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.t('app.name'),
                            style: context.textStyles.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            context.l10n.t('app.tagline'),
                            style: context.textStyles.labelSmall?.copyWith(
                              color: palette.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: AppSection.values.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final item = AppSection.values[index];
                    return _NavItem(
                      icon: iconFor(item),
                      label: item.label(context.l10n),
                      selected: section == item,
                      onTap: () => onSelect(item),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Container(height: 1, color: palette.hairline),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: _SidebarFooter(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: palette.brandSoft,
                borderRadius: BorderRadius.circular(7),
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
            Text(
              'v${AppInfo.version}',
              style: context.textStyles.labelSmall?.copyWith(
                color: palette.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.t('shell.openSource'),
          style: context.textStyles.labelSmall?.copyWith(
            color: palette.textTertiary,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? palette.brandSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? palette.brand.withValues(alpha: 0.30)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: selected ? palette.brand : palette.textSecondary,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.labelLarge?.copyWith(
                    color: selected
                        ? palette.textPrimary
                        : palette.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.brand,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.section,
    required this.onSelect,
    required this.iconFor,
  });

  final AppSection section;
  final ValueChanged<AppSection> onSelect;
  final IconData Function(AppSection) iconFor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 0, 12),
      child: SizedBox(
        width: 76,
        child: FrostedSurface(
          radius: 24,
          opacity: 0.18,
          blur: 28,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              const BrandMark(size: 36),
              const SizedBox(height: 18),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final item in AppSection.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _RailItem(
                          icon: iconFor(item),
                          label: item.label(context.l10n),
                          selected: section == item,
                          onTap: () => onSelect(item),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 46,
            decoration: BoxDecoration(
              color: selected ? palette.brandSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected
                    ? palette.brand.withValues(alpha: 0.30)
                    : Colors.transparent,
              ),
            ),
            child: Icon(
              icon,
              size: 21,
              color: selected ? palette.brand : palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.section,
    required this.primary,
    required this.isMore,
    required this.onSelect,
    required this.onMore,
    required this.iconFor,
  });

  final AppSection section;
  final List<AppSection> primary;
  final bool isMore;
  final ValueChanged<AppSection> onSelect;
  final VoidCallback onMore;
  final IconData Function(AppSection) iconFor;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, 10 + bottomInset),
      child: FrostedSurface(
        radius: 20,
        opacity: 0.45,
        blur: 26,
        padding: const EdgeInsets.all(5),
        child: Row(
          children: [
            for (final item in primary)
              Expanded(
                child: _BottomItem(
                  icon: iconFor(item),
                  label: item.label(context.l10n),
                  selected: section == item,
                  onTap: () => onSelect(item),
                ),
              ),
            Expanded(
              child: _BottomItem(
                icon: Icons.apps_rounded,
                label: context.l10n.t('shell.more'),
                selected: isMore,
                onTap: onMore,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 54,
          decoration: BoxDecoration(
            color: selected ? palette.brandSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? palette.brand.withValues(alpha: 0.28)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? palette.brand : palette.textTertiary,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.labelSmall?.copyWith(
                  fontSize: 10,
                  color: selected ? palette.brand : palette.textTertiary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.section,
    required this.onTap,
  });

  final IconData icon;
  final AppSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.brandSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: palette.brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.label(context.l10n),
                      style: context.textStyles.labelLarge?.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      section.description(context.l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.labelSmall?.copyWith(
                        color: palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: palette.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
