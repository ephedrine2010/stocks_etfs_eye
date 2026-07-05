import 'dart:convert';

import 'package:dio/dio.dart';

import '../../app/format.dart';
import '../config/markets.dart';
import '../models/models.dart';
import 'ai_source.dart';
import 'net.dart';

/// Direct DeepSeek client for the desktop/mobile app when a key is supplied via
/// a local `.env` (see [loadDotEnv]). Same behaviour as the proxy's AI endpoints
/// — Morning Brief live (cached a day), per-market Takes gated off by default —
/// so the app can do live AI WITHOUT the proxy. Never used on Web (no key there).
///
/// A null return means "use mock", which the repository honours.
class DeepSeekSource implements AiSource {
  final String apiKey;
  const DeepSeekSource(this.apiKey);

  static const _url = 'https://api.deepseek.com/chat/completions';
  static const _model = 'deepseek-chat';

  // Cost control — mirror the proxy: brief live, takes mock.
  static const _liveTakes = false;
  static const _liveBrief = true;

  /// Morning Brief style: a multi-agent panel (a fundamental, a sentiment, and a
  /// technical analyst each file a view, then a chief editor reconciles them into
  /// the final brief) instead of a single pass. Costs 4 model calls per brief but
  /// it's cached 24h (once/day). Flip to `false` to fall back to the one-shot
  /// brief. `final` (not `const`) so the one-shot path isn't flagged as dead code.
  static final bool _multiAgent = true;

  /// The three analyst lenses on the desk. Each id is stable so the brief cache
  /// and the citation chips line up; the label drives its prompt + the UI chip.
  static const _desks = <(String, String, String)>[
    ('fundamental', 'Fundamental desk',
        'macro & fundamentals — read each move against the broad regime (rates, '
        'growth, sector rotation), using only the given numbers'),
    ('sentiment', 'Sentiment desk',
        'sentiment & risk — read the risk-on/risk-off tone and cross-market '
        'momentum behind the moves'),
    ('technical', 'Technical desk',
        'technicals & price action — weigh the size and direction of each day\'s '
        'move and relative strength across markets'),
  ];

  static const _system = '''
You are a market analyst for a dashboard called Stocks Eye.
Rules:
- Use ONLY the numbers provided in the snapshot for prices and levels. NEVER invent figures.
- You have NO live web access. Do not fabricate news, URLs, or citations. Leave citations empty
  unless you are naming a well-known general source of context.
- Output is informational, NOT investment advice.
- Reply with ONLY a compact JSON object, no prose before or after.''';

  /// System prompt for one analyst lens on the multi-agent desk.
  static String _analystSystem(String lens) => '''
You are the $lens analyst on a markets desk for a dashboard called Stocks Eye.
Rules:
- Use ONLY the numbers in the snapshot. NEVER invent prices, levels, or figures.
- You have NO live web access. Do not fabricate news or citations.
- Judge every market strictly through your assigned lens.
- Output is informational, NOT investment advice.
- Reply with ONLY a compact JSON object, no prose before or after.''';

  /// System prompt for the chief editor who reconciles the three desks.
  static const _editorSystem = '''
You are the chief editor of a markets desk for a dashboard called Stocks Eye.
Three analysts — fundamental, sentiment, and technical — have each filed a view.
Rules:
- Use ONLY the numbers in the snapshots. NEVER invent figures.
- Reconcile the desks: where they disagree, note it briefly and take a balanced stance.
- You have NO live web access. Do not fabricate news, URLs, or citations.
- Output is informational, NOT investment advice.
- Reply with ONLY a compact JSON object, no prose before or after.''';

  Future<String> _chat(String user, int maxTokens, {String? system}) async {
    final res = await dio.post(
      _url,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        responseType: ResponseType.json,
      ),
      data: {
        'model': _model,
        'max_tokens': maxTokens,
        'temperature': 0.7,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': system ?? _system},
          {'role': 'user', 'content': user},
        ],
      },
    );
    return res.data?['choices']?[0]?['message']?['content'] as String? ?? '';
  }

  static Map<String, dynamic> _parseJson(String text) {
    final cleaned = text.replaceAll(RegExp(r'```json|```'), '').trim();
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start == -1 || end == -1) throw const FormatException('no json');
    return jsonDecode(cleaned.substring(start, end + 1)) as Map<String, dynamic>;
  }

  /// Roll-up Morning Brief (cached 24h in-memory; only successful live results).
  /// Runs the multi-agent desk when [_multiAgent] is on, else a single pass.
  /// Returns null to signal mock.
  @override
  Future<Brief?> fetchBrief(List<Map<String, dynamic>> snapshots) async {
    if (!_liveBrief) return null;
    final key = _multiAgent ? 'deepseek:brief:panel' : 'deepseek:brief';
    try {
      return await netCache.wrap(key, const Duration(hours: 24), () async {
        return _multiAgent
            ? _panelBrief(snapshots)
            : _soloBrief(snapshots);
      });
    } catch (_) {
      return null;
    }
  }

  /// Single-pass brief (the original behaviour; kept for the [_multiAgent] flag).
  Future<Brief> _soloBrief(List<Map<String, dynamic>> snapshots) async {
    final user =
        'Snapshots (ground truth):\n${jsonEncode(snapshots)}\n\n'
        'Write today\'s roll-up Morning Brief across all markets. Reply as JSON: '
        '{"lead":"...","lines":[{"id":"","name":"","s":"bull|bear|neut","text":""}],"hint":"...","citations":[]}.';
    return _parseBrief(_parseJson(await _chat(user, 4000)));
  }

  /// Multi-agent brief: the three desks assess the same snapshots in parallel,
  /// then the chief editor reconciles their filings into the final brief. The
  /// desks become the brief's citations so the panel is visible in the UI.
  Future<Brief> _panelBrief(List<Map<String, dynamic>> snapshots) async {
    final ground = jsonEncode(snapshots);
    final filings = await Future.wait(_desks.map((d) => _deskFiling(d, ground)));
    final desk = {
      for (var i = 0; i < _desks.length; i++) _desks[i].$1: filings[i],
    };
    final user =
        'Snapshots (ground truth):\n$ground\n\n'
        'Analyst desk filings:\n${jsonEncode(desk)}\n\n'
        'Write today\'s roll-up Morning Brief across all markets, reconciling the '
        'three desks. Reply as JSON: {"lead":"2-3 sentences","lines":[{"id":"",'
        '"name":"","s":"bull|bear|neut","text":"one sentence"}],'
        '"hint":"one actionable, non-advice reminder"}.';
    final data = _parseJson(await _chat(user, 4000, system: _editorSystem));
    return _parseBrief(
      data,
      source: '$_model · 3-desk panel',
      citations: [for (final d in _desks) d.$2],
    );
  }

  /// One analyst desk's filing over the shared snapshot, as a compact map.
  /// Failure yields an empty filing so one desk never sinks the whole brief.
  Future<Map<String, dynamic>> _deskFiling(
      (String, String, String) desk, String ground) async {
    try {
      final user =
          'Snapshots (ground truth):\n$ground\n\n'
          'As the ${desk.$2} (${desk.$3}), assess each market through your lens. '
          'Reply as JSON: {"view":"<=25 words overall stance","markets":'
          '[{"id":"<market id>","s":"bull|bear|neut","note":"<=14 words"}]}.';
      return _parseJson(await _chat(user, 900, system: _analystSystem(desk.$3)));
    } catch (_) {
      return const {'view': '', 'markets': []};
    }
  }

  /// Per-market Take. Gated off by default → returns null (mock).
  @override
  Future<Take?> fetchTake(MarketConfig market, Map<String, dynamic> snapshot) async {
    if (!_liveTakes) return null;
    try {
      final user =
          'Market snapshot (ground truth):\n${jsonEncode(snapshot)}\n\n'
          'Write today\'s AI Take for ${market.name}. Reply as JSON: '
          '{"sentiment":"bull|bear|neut","text":"1-2 sentences","citations":["Source"]}.';
      final obj = _parseJson(await _chat(user, 1024));
      return Take(
        sentiment: sentimentFromString(obj['sentiment'] as String?),
        text: (obj['text'] as String?) ?? '',
        citations: _stringList(obj['citations']),
        source: _model,
        asOf: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Build a [Brief] from an editor/solo JSON payload. [source] and [citations]
  /// can be overridden (the panel supplies its desks as the citations).
  Brief _parseBrief(
    Map<String, dynamic> data, {
    String source = _model,
    List<String>? citations,
  }) {
    final lines = <BriefLine>[];
    for (final raw in (data['lines'] as List? ?? const [])) {
      if (raw is! Map) continue;
      final id = (raw['id'] as String?) ?? '';
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
      citations: citations ?? _stringList(data['citations']),
      source: source,
      asOf: DateTime.now(),
    );
  }

  static List<String> _stringList(dynamic v) =>
      v is List ? v.map((e) => e.toString()).toList() : const [];
}
