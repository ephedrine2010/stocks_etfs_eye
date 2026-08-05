import 'package:flutter/material.dart';

/// The Stocks Eye palette, ported 1:1 from the old `styles.css` `:root` block.
/// Dark ground with a gold accent; green/red for gain/loss.
///
/// This is the only place a colour is chosen. Widgets never write `Colors.*`,
/// `Color(0x…)` or `.shade*` — those don't respond to the palette and are how a
/// surface ends up glowing white on a dark ground.
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

  /// Money moved in our favour / against it. Deliberately separate from any
  /// "error" colour — a red day is not a failure.
  static const gain = Color(0xFF34C08A);
  static const loss = Color(0xFFF26D6D);

  /// Hover / raised border used on tiles.
  static const lineHover = Color(0xFF3A4A68);

  /// The standard 12% wash behind a coloured icon, pill or chip.
  static Color tint(Color c) => c.withValues(alpha: 0.12);
}

/// Spacing scale. No 10, 14, 18, 25 — if a value isn't here, use the nearest
/// one that is.
abstract class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const huge = 32.0;
}

/// Corner radii.
abstract class AppRadius {
  static const xs = 6.0;
  static const sm = 8.0;

  /// The tinted icon chip — a square-ish glyph plate.
  static const iconChip = 11.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;

  /// A fully-round pill.
  static const pill = 99.0;
}

/// Icon sizes — pick by context, never freehand.
abstract class AppIconSize {
  static const inline = 16.0; // inside a table cell or dense row
  static const dense = 18.0; // field prefix, small button
  static const standard = 20.0; // button, app-bar action
  static const chip = 22.0; // tinted icon chip
  static const header = 28.0; // dialog header
  static const empty = 44.0; // empty state — the only decorative size
}

abstract class AppMotion {
  static const fast = Duration(milliseconds: 180);
  static const panel = Duration(milliseconds: 300);
  static const curve = Curves.easeInOut;
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
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.xs)),
        ),
        textStyle: TextStyle(color: AppColors.ink, fontSize: 11),
      ),
    );
  }
}

/// The type scale. Widgets pick a named style instead of setting `fontSize:`
/// freehand, so the same thing is the same size on every screen.
abstract class AppText {
  /// Screen / brand title.
  static const headline = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: AppColors.ink,
    height: 1.2,
  );

  /// Dialog and panel title.
  static const title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.25,
  );

  /// Card title, market name, item name.
  static const titleSmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  /// Default body / table cell.
  static const body = TextStyle(fontSize: 13, color: AppColors.ink, height: 1.45);

  /// Secondary body — company names, descriptions.
  static const bodyMuted =
      TextStyle(fontSize: 12.5, color: AppColors.ink2, height: 1.45);

  /// Hint, caption, footnote.
  static const caption =
      TextStyle(fontSize: 11, color: AppColors.ink3, height: 1.5);

  /// Tag, badge, micro-label.
  static const micro = TextStyle(fontSize: 10, color: AppColors.ink3);

  /// Uppercase section label — `.lbl` in the old CSS.
  static const label = TextStyle(
    fontSize: 11,
    letterSpacing: 1.76, // ~0.16em
    color: AppColors.ink3,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// Column header inside a table.
  static const columnHeader = TextStyle(
    fontSize: 10,
    letterSpacing: 0.6,
    color: AppColors.ink3,
    fontWeight: FontWeight.w600,
  );

  /// Tabular monospace for prices, %s, tickers. Every number a person compares
  /// down a column gets this — without it the digits jitter between rows.
  static const mono = TextStyle(
    fontFamilyFallback: kMonoFonts,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// A number in a table cell.
  static const numCell = TextStyle(
    fontFamilyFallback: kMonoFonts,
    fontFeatures: [FontFeature.tabularFigures()],
    fontSize: 12.5,
    color: AppColors.ink,
  );

  /// The headline price on a tile / dialog header.
  static const numHeadline = TextStyle(
    fontFamilyFallback: kMonoFonts,
    fontFeatures: [FontFeature.tabularFigures()],
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: AppColors.ink,
  );
}
