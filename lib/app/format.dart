import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';

import 'theme.dart';

/// Market/news sentiment. Mirrors the old `'bull' | 'bear' | 'neut'` strings.
enum Sentiment { bull, bear, neut }

Sentiment sentimentFromString(String? s) => switch (s) {
  'bull' => Sentiment.bull,
  'bear' => Sentiment.bear,
  _ => Sentiment.neut,
};

extension SentimentX on Sentiment {
  String get label => switch (this) {
    Sentiment.bull => 'Bullish',
    Sentiment.bear => 'Bearish',
    Sentiment.neut => 'Neutral',
  };

  /// Tabler icon glyph replacing the old ▲ / ▼ / ● emoji.
  IconData get icon => switch (this) {
    Sentiment.bull => TablerIcons.trending_up,
    Sentiment.bear => TablerIcons.trending_down,
    Sentiment.neut => TablerIcons.minus,
  };

  Color get color => switch (this) {
    Sentiment.bull => AppColors.gain,
    Sentiment.bear => AppColors.loss,
    Sentiment.neut => AppColors.ink3,
  };
}

/// Shared formatting helpers, ported from the old `format.js`.
abstract class Fmt {
  /// Price formatting: 2 decimals under 100, else grouped integer-ish.
  /// Mirrors `fmt` — fraction digits depend on magnitude.
  static String price(num n) {
    final maxFrac = 2;
    final minFrac = n.abs() < 100 ? 2 : 0;
    final f = NumberFormat.decimalPattern('en_US')
      ..minimumFractionDigits = minFrac
      ..maximumFractionDigits = maxFrac;
    return f.format(n);
  }

  /// Big signed change for headline values: "▲ +0.62%" → here caller pairs it
  /// with the sentiment icon; this returns just the "+0.62%" / "-0.31%" text.
  static String signedPct(num c) =>
      '${c >= 0 ? '+' : '-'}${c.abs().toStringAsFixed(2)}%';

  /// Compact signed percent for movers/watch: "+2.1%".
  static String compactPct(num c) =>
      '${c >= 0 ? '+' : ''}${c.toStringAsFixed(1)}%';

  static Color gainLoss(num c) => c >= 0 ? AppColors.gain : AppColors.loss;

  static Sentiment sentimentOfChange(num c) =>
      c >= 0 ? Sentiment.bull : Sentiment.bear;
}
