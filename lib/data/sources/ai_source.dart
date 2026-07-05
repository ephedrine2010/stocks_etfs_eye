import '../models/models.dart';

/// Common interface for the two AI backends — [DeepSeekSource] (direct, desktop
/// with a local key) and [AiProxySource] (via the proxy). A null return means
/// "use mock", which the repository honours.
abstract interface class AiSource {
  Future<Brief?> fetchBrief(List<Map<String, dynamic>> snapshots);
  Future<Take?> fetchTake(MarketConfig market, Map<String, dynamic> snapshot);
}
