import 'package:flutter/material.dart';

import '../core/math/expression.dart';
import '../core/storage/app_store.dart';
import '../core/theme/app_palette.dart';
import '../l10n/l10n.dart';

/// Global app preferences, persisted through [AppStore].
class AppSettings extends ChangeNotifier {
  AppSettings({AppStore? store}) : _store = store {
    final data = store?.settings;
    if (data != null) {
      _themeMode = _themeFromName(data['theme']);
      _accentIndex = (data['accent'] as num?)?.toInt() ?? 0;
      _angleMode = data['angle'] == 'degrees'
          ? AngleMode.degrees
          : AngleMode.radians;
      _locale = data['locale'] == 'en' ? AppLocale.en : AppLocale.zh;
      _onboardingComplete = data['onboarding'] == true;
      if (_accentIndex < 0 || _accentIndex >= AccentPreset.presets.length) {
        _accentIndex = 0;
      }
    }
  }

  final AppStore? _store;

  ThemeMode _themeMode = ThemeMode.dark;
  int _accentIndex = 0;
  AngleMode _angleMode = AngleMode.radians;
  AppLocale _locale = AppLocale.zh;
  bool _onboardingComplete = false;

  ThemeMode get themeMode => _themeMode;
  int get accentIndex => _accentIndex;
  AngleMode get angleMode => _angleMode;
  AppLocale get locale => _locale;
  bool get onboardingComplete => _onboardingComplete;

  AccentPreset get accent => AccentPreset.presets[_accentIndex];

  AppPalette get darkPalette =>
      AppPalette.dark.tinted(accent.color, accent.alt);

  AppPalette get lightPalette =>
      AppPalette.light.tinted(accent.color, accent.alt);

  bool isDark(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _persist();
    notifyListeners();
  }

  void setAccent(int index) {
    if (_accentIndex == index ||
        index < 0 ||
        index >= AccentPreset.presets.length) {
      return;
    }
    _accentIndex = index;
    _persist();
    notifyListeners();
  }

  void setAngleMode(AngleMode mode) {
    if (_angleMode == mode) return;
    _angleMode = mode;
    _persist();
    notifyListeners();
  }

  void toggleAngleMode() {
    _angleMode = _angleMode == AngleMode.radians
        ? AngleMode.degrees
        : AngleMode.radians;
    _persist();
    notifyListeners();
  }

  void setLocale(AppLocale locale) {
    if (_locale == locale) return;
    _locale = locale;
    _persist();
    notifyListeners();
  }

  void completeOnboarding() {
    if (_onboardingComplete) return;
    _onboardingComplete = true;
    _persist();
    notifyListeners();
  }

  void resetOnboarding() {
    if (!_onboardingComplete) return;
    _onboardingComplete = false;
    _persist();
    notifyListeners();
  }

  static ThemeMode _themeFromName(Object? name) {
    return switch (name) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  String get _themeName => switch (_themeMode) {
    ThemeMode.light => 'light',
    ThemeMode.system => 'system',
    ThemeMode.dark => 'dark',
  };

  void _persist() {
    _store?.saveSettings({
      'theme': _themeName,
      'accent': _accentIndex,
      'angle': _angleMode == AngleMode.degrees ? 'degrees' : 'radians',
      'locale': _locale == AppLocale.en ? 'en' : 'zh',
      'onboarding': _onboardingComplete,
    });
  }

  @override
  void dispose() {
    _store?.flush();
    super.dispose();
  }
}

/// Exposes [AppSettings] to the widget tree.
class AppScope extends InheritedNotifier<AppSettings> {
  const AppScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found above this widget.');
    return scope!.notifier!;
  }

  static AppSettings read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found above this widget.');
    return scope!.notifier!;
  }
}

extension AppSettingsContext on BuildContext {
  AppSettings get appSettings => AppScope.of(this);

  L10n get l10n => L10n(AppScope.of(this).locale);
}
