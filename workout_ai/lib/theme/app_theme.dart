import 'package:flutter/material.dart';

abstract class AppColors {
  static const background = Color(0xFF000000);
  static const surface = Color(0xFF1C1C1E);
  static const surfaceElevated = Color(0xFF262628);
  static const surfaceHighest = Color(0xFF363638);
  static const primary = Color(0xFFD5FF63);
  static const primaryDim = Color(0xFFB5D950);
  static const primaryGlow = Color(0x20D5FF63);
  static const accent = Color(0xFFB9A5EF);
  static const accentGlow = Color(0x20B9A5EF);
  static const good = Color(0xFFC6F45C);
  static const goodGlow = Color(0x20C6F45C);
  static const warning = Color(0xFFFFD66B);
  static const warningGlow = Color(0x20FFD66B);
  static const error = Color(0xFFFF4F78);
  static const errorGlow = Color(0x20FF4F78);
  static const info = Color(0xFF69BEF6);
  static const infoGlow = Color(0x2069BEF6);
  static const textPrimary = Color(0xFFF8F8F8);
  static const textSecondary = Color(0xFFB5B5BA);
  static const textMuted = Color(0xFF99999F);
  static const divider = Color(0xFF343437);
  static const border = Color(0xFF39393C);
  static const demoChip = Color(0xFFB9A5EF);
  static const demoChipGlow = Color(0x20B9A5EF);
}

abstract class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 28;
  static const double xxl = 100;
}

abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    const text =
        TextStyle(color: AppColors.textPrimary, letterSpacing: 0, height: 1.25);
    final textTheme = base.textTheme.copyWith(
      displayLarge: text.copyWith(
          fontSize: 38, fontWeight: FontWeight.w700, letterSpacing: -1.3),
      displayMedium: text.copyWith(
          fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -1),
      displaySmall: text.copyWith(
          fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.7),
      headlineMedium: text.copyWith(fontSize: 21, fontWeight: FontWeight.w600),
      headlineSmall: text.copyWith(fontSize: 19, fontWeight: FontWeight.w600),
      titleLarge: text.copyWith(fontSize: 19, fontWeight: FontWeight.w600),
      titleMedium: text.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge:
          text.copyWith(fontSize: 17, height: 1.5, fontWeight: FontWeight.w400),
      bodyMedium: text.copyWith(
          fontSize: 15,
          color: AppColors.textSecondary,
          height: 1.5,
          fontWeight: FontWeight.w400),
      labelLarge: text.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      labelSmall: text.copyWith(
          fontSize: 13,
          color: AppColors.textSecondary,
          letterSpacing: 0.1,
          height: 1.4,
          fontWeight: FontWeight.w500),
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
          surface: AppColors.surface,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          error: AppColors.error,
          onSurface: AppColors.textPrimary,
          onPrimary: AppColors.background),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 64,
          titleSpacing: 16,
          titleTextStyle: textTheme.headlineMedium,
          iconTheme: const IconThemeData(color: AppColors.textPrimary)),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.surfaceHighest,
        labelTextStyle: WidgetStateProperty.resolveWith((states) =>
            textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: states.contains(WidgetState.selected)
                    ? AppColors.primary
                    : AppColors.textSecondary)),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            size: 26,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary)),
      ),
      iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              minimumSize: const Size(48, 48),
              shape: const CircleBorder())),
      dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          titleTextStyle: textTheme.headlineMedium,
          contentTextStyle: textTheme.bodyMedium),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceElevated,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary))),
      chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceElevated,
          labelStyle: textTheme.labelSmall,
          side: BorderSide.none,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      tabBarTheme: TabBarThemeData(
          dividerColor: Colors.transparent,
          labelColor: AppColors.background,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(100))),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary, linearTrackColor: AppColors.surfaceHighest),
      dividerTheme:
          const DividerThemeData(color: AppColors.divider, thickness: 0.5),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.background,
              textStyle: textTheme.labelLarge,
              minimumSize: const Size(0, 54),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: const StadiumBorder())),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              textStyle: textTheme.labelLarge,
              shape: const StadiumBorder(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16))),
    );
  }
}
