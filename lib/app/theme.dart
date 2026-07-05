import 'package:flutter/material.dart';

/// The Stocks Eye palette, ported 1:1 from the old `styles.css` `:root` block.
/// Dark ground with a gold accent; green/red for gain/loss.
abstract class AppColors {
  static const ground = Color(0xFF0E1420);
  static const surface = Color(0xFF1B2333);
  static const surface2 = Color(0xFF232D40);
  static const line = Color(0xFF2C3850);

  static const ink = Color(0xFFE7ECF5);
  static const ink2 = Color(0xFF9AA6BC);
  static const ink3 = Color(0xFF6C7789);

  static const accent = Color(0xFFE3A93C);
  static const accentDim = Color(0xFF8A6A25);

  static const gain = Color(0xFF34C08A);
  static const loss = Color(0xFFF26D6D);

  /// Hover / raised border used on tiles.
  static const lineHover = Color(0xFF3A4A68);
}

/// Monospace family used for all numeric/tabular values (tabular figures).
const kMonoFonts = <String>[
  'SF Mono',
  'Cascadia Code',
  'Roboto Mono',
  'Menlo',
  'monospace',
];

abstract class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColors.ground,
      primary: AppColors.accent,
      error: AppColors.loss,
      outline: AppColors.line,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.ground,
      canvasColor: AppColors.ground,
      dividerColor: AppColors.line,
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        textStyle: TextStyle(color: AppColors.ink, fontSize: 11),
      ),
    );
  }
}

/// Reusable text styles that recur across the UI.
abstract class AppText {
  /// Uppercase section label — `.lbl` in the old CSS.
  static const label = TextStyle(
    fontSize: 11,
    letterSpacing: 1.76, // ~0.16em
    color: AppColors.ink3,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// Tabular monospace for prices, %s, tickers.
  static const mono = TextStyle(
    fontFamilyFallback: kMonoFonts,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
