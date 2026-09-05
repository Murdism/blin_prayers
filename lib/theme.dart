import 'package:flutter/material.dart';

class AppColors {
  static const ink = Color(0xFF2B211C);
  static const inkSoft = Color(0xFF5C4F46);
  static const parch = Color(0xFFF4ECDC);
  static const parch2 = Color(0xFFEFE4CF);
  static const card = Color(0xFFFBF6EA);
  static const line = Color(0xFFD9C9A8);
  static const wine = Color(0xFF7A1F2B);
  static const wineDeep = Color(0xFF611620);
  static const wineSoft = Color(0xFF9C3340);
  static const gold = Color(0xFFB58A3A);
  static const goldSoft = Color(0xFFCDA85A);
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color card;
  final Color ink;
  final Color inkMuted;
  final Color outline;
  final Color primary;
  final Color primaryDark;
  final Color primarySoft;
  final Color goldText;
  final Color goldDecorative;
  final Color marianBlue;
  final Color mercyRed;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.card,
    required this.ink,
    required this.inkMuted,
    required this.outline,
    required this.primary,
    required this.primaryDark,
    required this.primarySoft,
    required this.goldText,
    required this.goldDecorative,
    required this.marianBlue,
    required this.mercyRed,
  });

  static const parchment = AppPalette(
    background: Color(0xFFF6F0E4),
    surface: Color(0xFFFFFCF6),
    surfaceMuted: Color(0xFFF0E4CF),
    card: Color(0xFFFFFCF6),
    ink: Color(0xFF2B211C),
    inkMuted: Color(0xFF5C4F46),
    outline: Color(0xFFD9C9A8),
    primary: Color(0xFF7A1F2B),
    primaryDark: Color(0xFF57151D),
    primarySoft: Color(0xFF9C3340),
    goldText: Color(0xFF8A6423),
    goldDecorative: Color(0xFFCDA85A),
    marianBlue: Color(0xFF315F8D),
    mercyRed: Color(0xFF9F2638),
  );

  static const night = AppPalette(
    background: Color(0xFF171310),
    surface: Color(0xFF1D1815),
    surfaceMuted: Color(0xFF302622),
    card: Color(0xFF241D1A),
    ink: Color(0xFFF6EBDD),
    inkMuted: Color(0xFFC9B9A7),
    outline: Color(0xFF5B493D),
    primary: Color(0xFFE0A0AA),
    primaryDark: Color(0xFF4B1520),
    primarySoft: Color(0xFFF0B0BA),
    goldText: Color(0xFFE3C47F),
    goldDecorative: Color(0xFFD5A956),
    marianBlue: Color(0xFF9ABAE0),
    mercyRed: Color(0xFFF0A0AA),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? card,
    Color? ink,
    Color? inkMuted,
    Color? outline,
    Color? primary,
    Color? primaryDark,
    Color? primarySoft,
    Color? goldText,
    Color? goldDecorative,
    Color? marianBlue,
    Color? mercyRed,
  }) =>
      AppPalette(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surfaceMuted: surfaceMuted ?? this.surfaceMuted,
        card: card ?? this.card,
        ink: ink ?? this.ink,
        inkMuted: inkMuted ?? this.inkMuted,
        outline: outline ?? this.outline,
        primary: primary ?? this.primary,
        primaryDark: primaryDark ?? this.primaryDark,
        primarySoft: primarySoft ?? this.primarySoft,
        goldText: goldText ?? this.goldText,
        goldDecorative: goldDecorative ?? this.goldDecorative,
        marianBlue: marianBlue ?? this.marianBlue,
        mercyRed: mercyRed ?? this.mercyRed,
      );

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      card: Color.lerp(card, other.card, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      goldText: Color.lerp(goldText, other.goldText, t)!,
      goldDecorative: Color.lerp(goldDecorative, other.goldDecorative, t)!,
      marianBlue: Color.lerp(marianBlue, other.marianBlue, t)!,
      mercyRed: Color.lerp(mercyRed, other.mercyRed, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

class AppTheme {
  static const geezSerifFamily = 'NotoSerifEthiopic';
  static const geezSansFamily = 'NotoSansEthiopic';
  static const latinFamily = 'CormorantGaramond';

  /// Ge'ez serif for headings / body of prayers.
  static TextStyle geezSerif(
          {double size = 16, FontWeight w = FontWeight.w400, Color? color}) =>
      TextStyle(
          fontFamily: geezSerifFamily,
          fontSize: size,
          fontWeight: w,
          color: color);

  /// Ge'ez sans for UI labels.
  static TextStyle geezSans(
          {double size = 15, FontWeight w = FontWeight.w500, Color? color}) =>
      TextStyle(
          fontFamily: geezSansFamily,
          fontSize: size,
          fontWeight: w,
          color: color);

  /// Latin italic accent (English notes, subtitles).
  static TextStyle latin(
          {double size = 14,
          FontWeight w = FontWeight.w500,
          Color? color,
          FontStyle style = FontStyle.italic}) =>
      TextStyle(
          fontFamily: latinFamily,
          fontSize: size,
          fontWeight: w,
          fontStyle: style,
          color: color);

  static ThemeData theme({required bool dark}) {
    final palette = dark ? AppPalette.night : AppPalette.parchment;
    final brightness = dark ? Brightness.dark : Brightness.light;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.primary,
        primary: palette.primary,
        surface: palette.surface,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: palette.background,
      fontFamily: geezSansFamily,
    );
    return base.copyWith(
      extensions: [palette],
      textTheme: base.textTheme
          .apply(fontFamily: geezSansFamily)
          .apply(bodyColor: palette.ink, displayColor: palette.ink),
      dividerColor: palette.outline,
      cardColor: palette.card,
      splashFactory: InkRipple.splashFactory,
    );
  }
}
