import 'package:equatable/equatable.dart';

import '../../app/format.dart';

/// A string the AI returns in both languages. [resolve] picks by locale and
/// falls back to English if the Arabic side is missing (a partial model reply
/// still renders). Use [LocalizedText.mono] when only one language is available
/// (e.g. a plain-string fallback in the parser).
class LocalizedText extends Equatable {
  final String en;
  final String ar;

  const LocalizedText({required this.en, required this.ar});
  const LocalizedText.mono(String text)
      : en = text,
        ar = text;

  String resolve(bool arabic) => arabic && ar.isNotEmpty ? ar : en;

  @override
  List<Object?> get props => [en, ar];
}

/// Per-market AI advice. Ported from `normalizer.makeTake`.
class Take extends Equatable {
  final Sentiment sentiment;
  final String text;
  final List<String> citations;
  final String source;
  final DateTime asOf;

  const Take({
    required this.text,
    this.sentiment = Sentiment.neut,
    this.citations = const [],
    this.source = 'mock',
    required this.asOf,
  });

  @override
  List<Object?> get props => [sentiment, text, citations, source, asOf];
}

/// One market's line in the roll-up Morning Brief. [name] stays a short Latin
/// label (e.g. "USA", "Gold") in both languages — it sits in a narrow fixed-width
/// slot; only the sentence [text] is bilingual.
class BriefLine extends Equatable {
  final String id;
  final String flag;
  final String name;
  final Sentiment sentiment;
  final LocalizedText text;

  const BriefLine({
    required this.id,
    required this.flag,
    required this.name,
    required this.sentiment,
    required this.text,
  });

  @override
  List<Object?> get props => [id, flag, name, sentiment, text];
}

/// The daily cross-market AI Morning Brief. [lead] and [hint] are bilingual so
/// the UI toggles language with no refetch; the 24h cache holds both.
class Brief extends Equatable {
  final LocalizedText lead;
  final List<BriefLine> lines;
  final LocalizedText hint;
  final List<String> citations;
  final String source;
  final DateTime asOf;

  const Brief({
    required this.lead,
    required this.lines,
    required this.hint,
    this.citations = const [],
    this.source = 'mock',
    required this.asOf,
  });

  @override
  List<Object?> get props => [lead, lines, hint, citations, source, asOf];
}
