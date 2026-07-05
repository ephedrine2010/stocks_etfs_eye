import '../../app/format.dart';
import '../config/markets.dart';
import '../models/models.dart';
import 'ai_source.dart';
import 'net.dart';

/// Client for the thin proxy's AI endpoints. The DeepSeek key lives on the proxy
/// — never in the app — so all live AI goes through here. A null return means
/// "use mock" (the proxy signalled mock, or the call failed), which the
/// repository honours by falling back to [MockSource].
class AiProxySource implements AiSource {
  final String baseUrl;
  const AiProxySource(this.baseUrl);

  @override

  /// Roll-up Morning Brief. Returns null to signal mock.
  Future<Brief?> fetchBrief(List<Map<String, dynamic>> snapshots) async {
    try {
      final res = await dio.post(
        '$baseUrl/api/ai/brief',
        data: {'snapshots': snapshots},
      );
      final data = res.data;
      if (data is! Map || data['source'] == 'mock') return null;
      return _parseBrief(data);
    } catch (_) {
      return null;
    }
  }

  /// Per-market AI Take. Returns null to signal mock (incl. the 204 gate).
  @override
  Future<Take?> fetchTake(
    MarketConfig market,
    Map<String, dynamic> snapshot,
  ) async {
    try {
      final res = await dio.post(
        '$baseUrl/api/ai/take',
        data: {
          'market': {'id': market.id, 'name': market.name},
          'snapshot': snapshot,
        },
      );
      if (res.statusCode == 204) return null;
      final data = res.data;
      if (data is! Map || data['source'] == 'mock') return null;
      return Take(
        sentiment: sentimentFromString(data['sentiment'] as String?),
        text: (data['text'] as String?) ?? '',
        citations: _stringList(data['citations']),
        source: (data['source'] as String?) ?? 'deepseek-chat',
        asOf: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  Brief _parseBrief(Map data) {
    final lines = <BriefLine>[];
    for (final raw in (data['lines'] as List? ?? const [])) {
      if (raw is! Map) continue;
      final id = (raw['id'] as String?) ?? '';
      // Prefer the canonical flag from the market config over the model's.
      final flag = marketConfigById(id)?.flag ?? (raw['flag'] as String?) ?? '';
      lines.add(BriefLine(
        id: id,
        flag: flag,
        name: (raw['name'] as String?) ?? '',
        sentiment: sentimentFromString(raw['s'] as String?),
        text: (raw['text'] as String?) ?? '',
      ));
    }
    return Brief(
      lead: (data['lead'] as String?) ?? '',
      lines: lines,
      hint: (data['hint'] as String?) ?? '',
      citations: _stringList(data['citations']),
      source: (data['source'] as String?) ?? 'deepseek-chat',
      asOf: DateTime.now(),
    );
  }

  static List<String> _stringList(dynamic v) =>
      v is List ? v.map((e) => e.toString()).toList() : const [];
}
