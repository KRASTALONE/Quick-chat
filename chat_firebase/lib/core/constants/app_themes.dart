import 'package:flutter/material.dart';

enum AppThemeOption { light, dark }

class AppThemes {
  static ThemeData buildTheme({
    required AppThemeOption themeMode,
    required Color seedColor,
  }) {
    final isDark = themeMode == AppThemeOption.dark;
    final brightness = isDark ? Brightness.dark : Brightness.light;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    final scaffoldColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surfaceColor =
        isDark ? const Color(0xFF132238) : const Color(0xFFFFFFFF);
    final inputColor =
        isDark ? const Color(0xFF1A2C45) : colorScheme.surfaceContainerHighest;
    final outlineColor =
        isDark ? const Color(0xFF243B59) : const Color(0xFFE2E8F0);

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
    );

    final textTheme = baseTheme.textTheme.apply(
      fontFamily: 'regular',
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return baseTheme.copyWith(
      scaffoldBackgroundColor: scaffoldColor,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: outlineColor.withValues(alpha: 0.35)),
        ),
      ),
      dividerTheme: DividerThemeData(color: outlineColor, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputColor,
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outlineColor.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontFamily: 'bold',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.primary,
        contentTextStyle: TextStyle(
          color: colorScheme.onPrimary,
          fontFamily: 'regular',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.55),
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: textTheme.copyWith(
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontFamily: 'bold',
          fontWeight: FontWeight.w700,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontFamily: 'bold',
          fontWeight: FontWeight.w700,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontFamily: 'bold',
          fontWeight: FontWeight.w600,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontFamily: 'bold',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static String labelForMode(AppThemeOption option) {
    switch (option) {
      case AppThemeOption.light:
        return 'Light';
      case AppThemeOption.dark:
        return 'Dark';
    }
  }
}
