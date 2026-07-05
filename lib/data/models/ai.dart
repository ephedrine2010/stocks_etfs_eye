import 'package:equatable/equatable.dart';

import '../../app/format.dart';

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

/// One market's line in the roll-up Morning Brief.
class BriefLine extends Equatable {
  final String id;
  final String flag;
  final String name;
  final Sentiment sentiment;
  final String text;

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

/// The daily cross-market AI Morning Brief.
class Brief extends Equatable {
  final String lead;
  final List<BriefLine> lines;
  final String hint;
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
