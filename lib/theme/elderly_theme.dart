import 'package:flutter/material.dart';

/// 高齢者向けの配色定義。
/// パステル背景を使いつつ、文字色と操作ボタンは十分に濃くして視認性を確保する。
class ElderlyPalette {
  ElderlyPalette._();

  static const background = Color(0xFFFFFCF6);
  static const cardSurface = Color(0xFFF2F6EA);
  static const accentSurface = Color(0xFFE7F5EE);
  static const successSurface = Color(0xFFE4F4E8);
  static const alertSurface = Color(0xFFFFF0E3);
  static const primary = Color(0xFF1E5B45);
  static const secondary = Color(0xFF214A72);
  static const primaryText = Color(0xFF15211A);
  static const secondaryText = Color(0xFF2F4034);
  static const subtleBorder = Color(0xFF9BB8A8);
  static const blocked = Color(0xFF9D3F16);
  static const blockedBackground = Color(0xFF7D2319);
  static const blockedSurface = Color(0xFFA43121);
  static const overlayScrim = Color(0xB215211A);
}

/// 高齢者向けテーマ。
/// 最小文字サイズを 18pt 相当に寄せ、主要な見出しは 24-26pt 以上に設定する。
class ElderlyTheme {
  ElderlyTheme._();

  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: ElderlyPalette.primary,
      onPrimary: Colors.white,
      secondary: ElderlyPalette.secondary,
      onSecondary: Colors.white,
      error: ElderlyPalette.blocked,
      onError: Colors.white,
      surface: ElderlyPalette.background,
      onSurface: ElderlyPalette.primaryText,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ElderlyPalette.background,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );

    const textTheme = TextTheme(
      displaySmall: TextStyle(
        fontSize: 56,
        fontWeight: FontWeight.w800,
        height: 1.1,
        color: ElderlyPalette.primaryText,
      ),
      headlineMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: ElderlyPalette.primaryText,
      ),
      headlineSmall: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: ElderlyPalette.primaryText,
      ),
      titleLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: ElderlyPalette.primaryText,
      ),
      titleMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: ElderlyPalette.primaryText,
      ),
      bodyLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: ElderlyPalette.primaryText,
      ),
      bodyMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: ElderlyPalette.primaryText,
      ),
      bodySmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: ElderlyPalette.secondaryText,
      ),
      labelLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: ElderlyPalette.background,
        foregroundColor: ElderlyPalette.primaryText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 72,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: ElderlyPalette.primaryText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ElderlyPalette.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(80),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ElderlyPalette.secondary,
          minimumSize: const Size.fromHeight(80),
          side: const BorderSide(color: ElderlyPalette.secondary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(const Size(60, 60)),
          iconSize: WidgetStatePropertyAll(32),
          foregroundColor: WidgetStatePropertyAll(ElderlyPalette.primaryText),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ElderlyPalette.subtleBorder,
        thickness: 1.5,
      ),
    );
  }
}
