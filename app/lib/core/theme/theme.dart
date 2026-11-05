import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

const _brandSeed = Color(0xFF7B1E3A);

/// One shape scale, used everywhere instead of ad hoc per-widget radii.
class AppRadius {
  const AppRadius._();
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const pill = 999.0;
}

/// One spacing scale (8dp base), used everywhere instead of raw numbers.
class AppSpace {
  const AppSpace._();
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 16.0;
  static const l = 24.0;
  static const xl = 32.0;
}

ThemeData buildLightTheme() => _buildTheme(
  ColorScheme.fromSeed(seedColor: _brandSeed),
);

ThemeData buildDarkTheme() => _buildTheme(
  ColorScheme.fromSeed(seedColor: _brandSeed, brightness: Brightness.dark),
);

ThemeData _buildTheme(ColorScheme scheme) {
  final colorScheme = scheme.copyWith(
    tertiary: AppColors.brand.saleAccent,
    onTertiary: AppColors.brand.onSaleAccent,
  );

  final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);

  // Playfair Display carries the editorial, fashion-magazine feel for
  // headlines and hero moments; Manrope stays the legible workhorse for
  // everything else. Two families, each with one clear job.
  final displayTextTheme = GoogleFonts.playfairDisplayTextTheme(base.textTheme);
  final bodyTextTheme = GoogleFonts.manropeTextTheme(base.textTheme);
  final textTheme = bodyTextTheme.copyWith(
    displayLarge: displayTextTheme.displayLarge,
    displayMedium: displayTextTheme.displayMedium,
    displaySmall: displayTextTheme.displaySmall,
    headlineLarge: displayTextTheme.headlineLarge,
    headlineMedium: displayTextTheme.headlineMedium,
    headlineSmall: displayTextTheme.headlineSmall,
    titleLarge: displayTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
  );

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      backgroundColor: colorScheme.surface,
      side: BorderSide(color: colorScheme.outlineVariant),
      labelStyle: textTheme.labelLarge,
      showCheckmark: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.l,
          vertical: AppSpace.m,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.l,
          vertical: AppSpace.m,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      showDragHandle: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    extensions: const [AppColors.brand],
  );
}
