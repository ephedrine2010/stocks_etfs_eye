import '../../app/format.dart';
import '../models/models.dart';
import 'net.dart';

/// Minimal RSS reader — fetch + light XML parsing (no dependency), ported from
/// the old `services/news/rss.js`. RSS items default to neutral sentiment until
/// FinBERT is wired. Returns items or throws so the repository falls back to mock.
class RssSource {
  /// Fetch and parse a feed into news items. [source] labels the outlet.
  static Future<List<NewsItem>> fetchFeed(
    String url,
    String source, {
    int limit = 4,
    String? proxyBase,
  }) {
    return netCache.wrap('rss:$url', const Duration(minutes: 15), () async {
      final res = await dio.get<String>(viaProxyUrl(url, proxyBase));
      final xml = res.data ?? '';
      final blocks = xml.split(RegExp(r'<item[\s>]', caseSensitive: false));
      final items = <NewsItem>[];
      for (final block in blocks.skip(1).take(limit)) {
        final headline = _tag(block, 'title');
        if (headline.isEmpty) continue;
        items.add(NewsItem(
          headline: headline,
          url: _tag(block, 'link').isEmpty ? '#' : _tag(block, 'link'),
          source: source,
          sentiment: Sentiment.neut,
          published: _relativeTime(_tag(block, 'pubDate')),
        ));
      }
      if (items.isEmpty) throw Exception('RSS: no items');
      return items;
    });
  }

  static String _tag(String block, String name) {
    final m = RegExp('<$name[^>]*>([\\s\\S]*?)</$name>', caseSensitive: false)
        .firstMatch(block);
    if (m == null) return '';
    var s = m.group(1) ?? '';
    s = s.replaceAllMapped(
      RegExp(r'<!\[CDATA\[([\s\S]*?)\]\]>'),
      (m) => m.group(1) ?? '',
    );
    s = s.replaceAll(RegExp(r'<[^>]+>'), '');
    s = s
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'&#39;|&apos;'), "'")
        .replaceAll('&quot;', '"');
    // Numeric entities (e.g. &#8217; curly apostrophe) — common in WordPress feeds.
    s = s.replaceAllMapped(
      RegExp(r'&#x([0-9a-f]+);', caseSensitive: false),
      (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
    );
    s = s.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (m) => String.fromCharCode(int.parse(m.group(1)!)),
    );
    return s.trim();
  }

  static String _relativeTime(String dateStr) {
    final d = DateTime.tryParse(dateStr) ?? _parseRfc822(dateStr);
    if (d == null) return '';
    final mins = ((DateTime.now().difference(d).inSeconds) / 60).round();
    final m = mins < 1 ? 1 : mins;
    if (m < 60) return '${m}m';
    final h = (m / 60).round();
    if (h < 24) return '${h}h';
    return '${(h / 24).round()}d';
  }

  /// RFC-822 dates (e.g. "Mon, 05 Jul 2026 13:30:00 GMT") that DateTime.parse
  /// can't handle. Best-effort; returns null if unparseable.
  static DateTime? _parseRfc822(String s) {
    final m = RegExp(r'(\d{1,2})\s+(\w{3})\s+(\d{4})\s+(\d{2}):(\d{2})')
        .firstMatch(s);
    if (m == null) return null;
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final mon = months[m.group(2)];
    if (mon == null) return null;
    return DateTime.utc(
      int.parse(m.group(3)!),
      mon,
      int.parse(m.group(1)!),
      int.parse(m.group(4)!),
      int.parse(m.group(5)!),
    );
  }
}
