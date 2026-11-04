import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/platform/app_platform.dart';
import 'core/storage/app_store.dart';
import 'core/theme/app_theme.dart';
import 'l10n/l10n.dart';
import 'state/app_settings.dart';
import 'ui/shell/app_shell.dart';

class GraphicaApp extends StatefulWidget {
  const GraphicaApp({super.key, required this.store});

  final AppStore store;

  @override
  State<GraphicaApp> createState() => _GraphicaAppState();
}

class _GraphicaAppState extends State<GraphicaApp> {
  static const MethodChannel _windowChannel = MethodChannel('graphica/window');

  late final AppSettings _settings = AppSettings(store: widget.store);
  bool? _darkChrome;

  void _syncWindowChrome(bool dark) {
    if (_darkChrome == dark) return;
    _darkChrome = dark;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await _windowChannel.invokeMethod<void>('setBrightness', dark);
      } on MissingPluginException {
        // Only Windows implements native window chrome.
      } on PlatformException {
        // Non-fatal: the app theme still updates.
      }
    });
  }

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      settings: _settings,
      child: AnimatedBuilder(
        animation: _settings,
        builder: (context, _) {
          final locale = _settings.locale == AppLocale.zh
              ? const Locale('zh')
              : const Locale('en');
          return MaterialApp(
            title: '数绘',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(_settings.lightPalette),
            darkTheme: AppTheme.dark(_settings.darkPalette),
            themeMode: _settings.themeMode,
            locale: locale,
            supportedLocales: L10n.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            scrollBehavior: const AppScrollBehavior(),
            builder: (context, child) {
              _syncWindowChrome(
                Theme.of(context).brightness == Brightness.dark,
              );
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarContrastEnforced: false,
                ),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(
                    decoration: TextDecoration.none,
                    decorationColor: Colors.transparent,
                  ),
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
            home: AppShell(store: widget.store),
          );
        },
      ),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    if (AppPlatform.isIOS || AppPlatform.isMacOS) {
      return const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
    }
    return const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}
