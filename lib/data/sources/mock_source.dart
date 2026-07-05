import '../../app/format.dart';
import '../models/models.dart';

/// The guaranteed-fallback mock dataset, ported from
/// `backend/services/mock/marketData.js`. Every live source degrades to this so
/// a tile is never blank. Sentiment strings: 'bull' | 'bear' | 'neut'.
abstract class MockSource {
  /// Headline quote from a market's baked-in mock block.
  static Quote quote(MarketConfig m) => Quote(
    price: m.mock.price,
    changePct: m.mock.changePct,
    spark: m.mock.spark,
    source: 'mock',
    currency: m.currency,
    asOf: DateTime.now(),
  );

  static List<Mover> movers(String id) =>
      (_movers[id] ?? const [])
          .map((r) => Mover(
                symbol: r.$1,
                name: r.$2,
                changePct: r.$3,
              ))
          .toList(growable: false);

  static List<NewsItem> news(String id) =>
      (_news[id] ?? const [])
          .map((n) => NewsItem(
                headline: n.$2,
                source: n.$3,
                sentiment: sentimentFromString(n.$1),
                published: n.$4,
              ))
          .toList(growable: false);

  static Take? take(String id) {
    final a = _advice[id];
    if (a == null) return null;
    return Take(
      sentiment: sentimentFromString(a.$1),
      text: a.$3,
      citations: a.$2,
      source: 'mock',
      asOf: DateTime.now(),
    );
  }

  static List<WatchRow> watchlist() => _watchlist;

  static Brief brief() => _brief;
}

// (symbol, name, changePct)
const Map<String, List<(String, String, double)>> _movers = {
  'us': [
    ('NVDA', 'NVIDIA', 2.8),
    ('MSFT', 'Microsoft', 1.1),
    ('TSLA', 'Tesla', -1.9),
    ('AMZN', 'Amazon', 0.7),
  ],
  'sa': [
    ('1120', 'Al Rajhi', 0.8),
    ('2010', 'SABIC', -1.2),
    ('7010', 'STC', 0.4),
    ('1010', 'Riyad Bank', -0.6),
  ],
  'ae': [
    ('EMAAR', 'Emaar', 0.3),
    ('DIB', 'Dubai Islamic', 0.9),
    ('EAND', 'e&', -0.5),
    ('ADCB', 'ADCB', 0.2),
  ],
  'eg': [
    ('COMI', 'CIB', 1.7),
    ('HRHO', 'EFG', 2.3),
    ('SWDY', 'Elsewedy', -0.8),
    ('TMGH', 'TMG', 1.1),
  ],
  'cn': [
    ('600519', 'Moutai', -0.6),
    ('601318', 'Ping An', 0.5),
    ('600036', 'CMB', -0.9),
    ('000858', 'Wuliangye', 0.3),
  ],
  'au': [
    ('GLD', 'SPDR Gold ETF', 0.4),
    ('IAU', 'iShares Gold', 0.4),
    ('NEM', 'Newmont', 1.3),
    ('GOLD', 'Barrick', -0.7),
  ],
  'cr': [
    ('BTC', 'Bitcoin', 2.1),
    ('ETH', 'Ethereum', 3.4),
    ('SOL', 'Solana', 5.6),
    ('BNB', 'BNB', 1.2),
    ('XRP', 'XRP', -1.8),
  ],
};

// (sentiment, headline, source, timeAgo)
const Map<String, List<(String, String, String, String)>> _news = {
  'us': [
    ('bull', 'Nvidia extends rally as AI-chip demand outlook lifts megacaps', 'Finnhub', '18m'),
    ('bear', 'Treasury yields tick up ahead of Fed minutes, weighing on tech', 'Reuters', '1h'),
    ('neut', 'S&P 500 drifts near record as traders await payrolls data', 'Alpha Vantage', '2h'),
  ],
  'sa': [
    ('bear', 'TASI slips as banks retreat; Aramco steadies after dividend note', 'Argaam', '32m'),
    ('bull', 'Al Rajhi leads gainers on stronger Q2 lending growth', 'Mubasher', '1h'),
    ('neut', 'Saudi PIF-linked listing pipeline stays active into H2', 'Zawya', '3h'),
  ],
  'ae': [
    ('bull', 'Emaar climbs as Dubai property transactions hit fresh high', 'Arabian Business', '25m'),
    ('neut', 'DFM turnover steady; Dubai Islamic Bank in focus pre-earnings', 'Zawya', '2h'),
    ('bear', 'ADX drifts lower as energy names track softer crude', 'Mubasher', '4h'),
  ],
  'eg': [
    ('bull', 'EGX 30 jumps as CIB and EFG rally on foreign inflows', 'Mubasher', '12m'),
    ('neut', 'Newly listed petroleum firms on EGX to trade in USD, minister says', 'Zawya', '1h'),
    ('bear', 'Pound pressure keeps some blue chips capped despite index gains', 'Marketaux', '5h'),
  ],
  'cn': [
    ('bear', 'SSE Composite eases as property drag offsets stimulus hopes', 'akshare · Sina', '20m'),
    ('neut', 'Kweichow Moutai steadies after liquor-sector volatility', 'Eastmoney', '2h'),
    ('bull', 'Ping An gains on buyback signal; brokers turn constructive', 'akshare', '3h'),
  ],
  'au': [
    ('bull', 'Gold firms as softer dollar and rate-cut bets support bullion', 'Kitco', '15m'),
    ('neut', 'XAU/USD holds range ahead of US inflation print', 'Marketaux', '1h'),
    ('bear', 'Gold pares gains as Treasury yields rebound intraday', 'Investing.com', '4h'),
  ],
  'cr': [
    ('bull', 'Bitcoin pushes higher as spot-ETF inflows accelerate', 'CoinDesk', '9m'),
    ('bull', 'Ethereum leads majors after network upgrade goes live', 'The Block', '48m'),
    ('bear', 'Altcoins wobble as perp funding rates flip negative intraday', 'Cointelegraph', '3h'),
  ],
};

// (sentiment, citations, text)
const Map<String, (String, List<String>, String)> _advice = {
  'us': ('bull', ['Reuters', 'Finnhub'], 'Pre-market tone is constructive as Treasury yields ease and megacap tech leads. The swing factor today is the US CPI print at 13:30 GMT — a hotter number would pressure rate-sensitive names.'),
  'sa': ('neut', ['Argaam', 'Zawya'], 'TASI likely opens flat; banks and Aramco steady after the dividend note. Oil direction and PIF-linked listing flow are the near-term drivers to watch.'),
  'ae': ('bull', ['Arabian Business', 'Zawya'], 'DFM is supported by strong Dubai property transaction data, with Dubai Islamic Bank in focus ahead of earnings. ADX lags as energy names track softer crude.'),
  'eg': ('bull', ['Mubasher', 'Zawya'], 'EGX 30 is buoyed by foreign inflows into CIB and EFG. Watch the pound — currency pressure can cap blue-chip gains even when the index is strong.'),
  'cn': ('bear', ['akshare', 'Eastmoney'], 'Mainland is soft on the property drag; sentiment hinges on fresh stimulus signals. Moutai and Ping An are the large-cap tells for the session.'),
  'au': ('neut', ['Kitco', 'Marketaux'], 'Gold is range-bound ahead of US inflation. A cooler CPI plus a softer dollar would favour bullion; a rebound in yields caps it. Position sizing over direction today.'),
  'cr': ('bull', ['CoinDesk', 'The Block'], 'BTC and ETH extend gains on accelerating spot-ETF inflows. Momentum is strong but perp funding rates look stretched — watch for intraday altcoin pullbacks.'),
};

const List<WatchRow> _watchlist = [
  WatchRow(id: 'us', flag: '🇺🇸', symbol: 'AAPL', name: 'Apple', native: '\$214.30', usd: '\$214.30', changePct: 0.9),
  WatchRow(id: 'sa', flag: '🇸🇦', symbol: '2222', name: 'Saudi Aramco', native: '﷼ 28.90', usd: '\$7.71', changePct: -0.4),
  WatchRow(id: 'eg', flag: '🇪🇬', symbol: 'COMI', name: 'Comm. Intl Bank', native: '£ 84.20', usd: '\$1.72', changePct: 1.7),
  WatchRow(id: 'cn', flag: '🇨🇳', symbol: '600519', name: 'Kweichow Moutai', native: '¥1,588', usd: '\$219.4', changePct: -0.6),
  WatchRow(id: 'ae', flag: '🇦🇪', symbol: 'EMAAR', name: 'Emaar Properties', native: 'د.إ 8.15', usd: '\$2.22', changePct: 0.3),
  WatchRow(id: 'au', flag: '🥇', symbol: 'XAU', name: 'Gold spot / oz', native: '\$2,338.40', usd: '\$2,338.40', changePct: 0.4),
  WatchRow(id: 'cr', flag: '🪙', symbol: 'BTC', name: 'Bitcoin', native: '\$68,450', usd: '\$68,450', changePct: 2.1),
];

final Brief _brief = Brief(
  lead:
      "Global risk appetite is firmer heading into the session. US futures point higher as Treasury yields cool, Gulf markets open steady with Aramco in focus, and crypto extends its rally on renewed spot-ETF inflows. Gold holds its range ahead of today's US inflation print.",
  lines: const [
    BriefLine(id: 'us', flag: '🇺🇸', name: 'USA', sentiment: Sentiment.bull, text: 'Futures firmer; megacap tech leads pre-market.'),
    BriefLine(id: 'sa', flag: '🇸🇦', name: 'KSA', sentiment: Sentiment.neut, text: 'TASI flat to open; banks & Aramco steady.'),
    BriefLine(id: 'ae', flag: '🇦🇪', name: 'UAE', sentiment: Sentiment.bull, text: 'Dubai property strength supports DFM.'),
    BriefLine(id: 'eg', flag: '🇪🇬', name: 'Egypt', sentiment: Sentiment.bull, text: 'EGX 30 buoyed by foreign inflows into CIB.'),
    BriefLine(id: 'cn', flag: '🇨🇳', name: 'China', sentiment: Sentiment.bear, text: 'Mainland soft on property drag; stimulus watch.'),
    BriefLine(id: 'au', flag: '🥇', name: 'Gold', sentiment: Sentiment.neut, text: 'Range-bound; awaiting US CPI at 13:30 GMT.'),
    BriefLine(id: 'cr', flag: '🪙', name: 'Crypto', sentiment: Sentiment.bull, text: 'BTC & ETH extend gains on ETF inflows.'),
  ],
  hint:
      'Tone is risk-on but data-dependent — US inflation (13:30 GMT) is the common swing factor for gold, crypto, and rate-sensitive megacaps alike. Worth watching before repositioning.',
  citations: const ['Reuters', 'Bloomberg', 'Argaam', 'Kitco', 'CoinDesk'],
  source: 'mock',
  asOf: DateTime.now(),
);
