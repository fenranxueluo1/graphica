import 'package:flutter/material.dart';

/// Design tokens shared by every platform build.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.bgSecondary,
    required this.surface,
    required this.surfaceElevated,
    required this.hairline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.brand,
    required this.brandAlt,
    required this.brandSoft,
    required this.glow,
    required this.shadow,
  });

  final Color bg;
  final Color bgSecondary;
  final Color surface;
  final Color surfaceElevated;
  final Color hairline;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color brand;
  final Color brandAlt;
  final Color brandSoft;
  final Color glow;
  final Color shadow;

  static const dark = AppPalette(
    bg: Color(0xFF070910),
    bgSecondary: Color(0xFF0B0E17),
    surface: Color(0xFF11141E),
    surfaceElevated: Color(0xFF181C28),
    hairline: Color(0x1FFFFFFF),
    textPrimary: Color(0xFFF2F5FF),
    textSecondary: Color(0xFFA2AABF),
    textTertiary: Color(0xFF6D7589),
    brand: Color(0xFF5EA8FF),
    brandAlt: Color(0xFF22D3EE),
    brandSoft: Color(0x2E2F80ED),
    glow: Color(0x4D2F80ED),
    shadow: Color(0x66000000),
  );

  static const light = AppPalette(
    bg: Color(0xFFF3F5FB),
    bgSecondary: Color(0xFFEAEDF7),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF7F9FF),
    hairline: Color(0xFFE3E7F1),
    textPrimary: Color(0xFF0E1220),
    textSecondary: Color(0xFF596174),
    textTertiary: Color(0xFF8A91A3),
    brand: Color(0xFF1D6FE8),
    brandAlt: Color(0xFF0891B2),
    brandSoft: Color(0x142F80ED),
    glow: Color(0x332F80ED),
    shadow: Color(0x140E1220),
  );

  /// Returns a palette re-tinted with the selected accent colour.
  AppPalette tinted(Color accent, Color alt) {
    return copyWith(
      brand: accent,
      brandAlt: alt,
      brandSoft: accent.withValues(alpha: 0.18),
      glow: accent.withValues(alpha: 0.30),
    );
  }

  @override
  AppPalette copyWith({
    Color? bg,
    Color? bgSecondary,
    Color? surface,
    Color? surfaceElevated,
    Color? hairline,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? brand,
    Color? brandAlt,
    Color? brandSoft,
    Color? glow,
    Color? shadow,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      bgSecondary: bgSecondary ?? this.bgSecondary,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      hairline: hairline ?? this.hairline,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      brand: brand ?? this.brand,
      brandAlt: brandAlt ?? this.brandAlt,
      brandSoft: brandSoft ?? this.brandSoft,
      glow: glow ?? this.glow,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppPalette lerp(covariant ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      bgSecondary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandAlt: Color.lerp(brandAlt, other.brandAlt, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

class AppColors {
  const AppColors._();

  static const brand = Color(0xFF2F80ED);
  static const sky = Color(0xFF54C5F8);
  static const cyan = Color(0xFF22D3EE);
  static const teal = Color(0xFF2DD4BF);
  static const blue = Color(0xFF3B82F6);
  static const violet = Color(0xFF8B5CF6);
  static const amber = Color(0xFFFBBF24);
  static const orange = Color(0xFFFB923C);
  static const green = Color(0xFF34D399);
  static const red = Color(0xFFFF5F6D);
}

/// Accent choices offered in settings.
class AccentPreset {
  const AccentPreset(this.id, this.name, this.color, this.alt);

  final String id;
  final String name;
  final Color color;
  final Color alt;

  static const presets = <AccentPreset>[
    AccentPreset('aurora', 'Aurora', Color(0xFF2F80ED), Color(0xFF22D3EE)),
    AccentPreset('violet', 'Violet', Color(0xFF8B5CF6), Color(0xFF22D3EE)),
    AccentPreset('mint', 'Mint', Color(0xFF10B981), Color(0xFF22D3EE)),
    AccentPreset('sunset', 'Sunset', Color(0xFFF97316), Color(0xFFF43F5E)),
    AccentPreset('rose', 'Rose', Color(0xFFF43F5E), Color(0xFF8B5CF6)),
  ];
}

extension AppThemeContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  TextTheme get textStyles => Theme.of(this).textTheme;
}
