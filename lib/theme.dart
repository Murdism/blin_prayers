import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

class AppTheme {
  /// Ge'ez serif for headings / body of prayers.
  static TextStyle geezSerif(
          {double size = 16, FontWeight w = FontWeight.w400, Color? color}) =>
      GoogleFonts.notoSerifEthiopic(
          fontSize: size, fontWeight: w, color: color ?? AppColors.ink);

  /// Ge'ez sans for UI labels.
  static TextStyle geezSans(
          {double size = 15, FontWeight w = FontWeight.w500, Color? color}) =>
      GoogleFonts.notoSansEthiopic(
          fontSize: size, fontWeight: w, color: color ?? AppColors.ink);

  /// Latin italic accent (English notes, subtitles).
  static TextStyle latin(
          {double size = 14,
          FontWeight w = FontWeight.w500,
          Color? color,
          FontStyle style = FontStyle.italic}) =>
      GoogleFonts.cormorantGaramond(
          fontSize: size,
          fontWeight: w,
          fontStyle: style,
          color: color ?? AppColors.inkSoft);

  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.wine,
        primary: AppColors.wine,
        surface: AppColors.parch,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.parch,
    );
    return base.copyWith(
      textTheme: GoogleFonts.notoSansEthiopicTextTheme(base.textTheme)
          .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
