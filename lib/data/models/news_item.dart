import 'package:equatable/equatable.dart';

import '../../app/format.dart';

/// A news headline with sentiment. Ported from `normalizer.makeNews`.
class NewsItem extends Equatable {
  final String headline;
  final String url;
  final String source;
  final Sentiment sentiment;

  /// Relative "time ago" label as produced upstream (e.g. "18m").
  final String? published;

  const NewsItem({
    required this.headline,
    required this.source,
    this.url = '#',
    this.sentiment = Sentiment.neut,
    this.published,
  });

  bool get hasLink => url.isNotEmpty && url != '#';

  @override
  List<Object?> get props => [headline, url, source, sentiment, published];
}
