import '../models/market_config.dart';
import '../models/schedule.dart';

/// The 7 tracked markets, ported from `backend/markets/*.js`.
/// Display order: equities → gold → crypto.
const List<MarketConfig> kMarkets = [
  _usa,
  _ksa,
  _uae,
  _egypt,
  _china,
  _gold,
  _crypto,
];

MarketConfig? marketConfigById(String id) {
  for (final m in kMarkets) {
    if (m.id == id) return m;
  }
  return null;
}

// 🇺🇸 USA — NYSE / NASDAQ. Trades Mon–Fri.
const _usa = MarketConfig(
  id: 'us',
  name: 'United States',
  city: 'New York',
  nameAr: 'الولايات المتحدة',
  cityAr: 'نيويورك',
  flag: '🇺🇸',
  tz: 'America/New_York',
  currency: 'USD',
  index: IndexInfo(label: 'S&P 500', symbol: '^GSPC'),
  schedule: Schedule(
    tz: 'America/New_York',
    days: [1, 2, 3, 4, 5],
    sessions: [
      [570, 960],
    ],
  ),
  priceSource: 'yahoo',
  newsSource: 'rss',
  newsFeeds: ['https://www.cnbc.com/id/100003114/device/rss/rss.html'],
  watch: [
    InstrumentRef(symbol: 'AAPL', name: 'Apple'),
    InstrumentRef(symbol: 'NVDA', name: 'NVIDIA'),
    InstrumentRef(symbol: 'MSFT', name: 'Microsoft'),
  ],
  movers: [
    InstrumentRef(symbol: 'AAPL', name: 'Apple'),
    InstrumentRef(symbol: 'NVDA', name: 'NVIDIA'),
    InstrumentRef(symbol: 'MSFT', name: 'Microsoft'),
    InstrumentRef(symbol: 'TSLA', name: 'Tesla'),
    InstrumentRef(symbol: 'AMZN', name: 'Amazon'),
  ],
  leaders: [
    InstrumentRef(symbol: 'AAPL', name: 'Apple'),
    InstrumentRef(symbol: 'MSFT', name: 'Microsoft'),
    InstrumentRef(symbol: 'NVDA', name: 'NVIDIA'),
    InstrumentRef(symbol: 'AMZN', name: 'Amazon'),
    InstrumentRef(symbol: 'META', name: 'Meta Platforms'),
    InstrumentRef(symbol: 'GOOGL', name: 'Alphabet'),
    InstrumentRef(symbol: 'JPM', name: 'JPMorgan Chase'),
    InstrumentRef(symbol: 'XOM', name: 'Exxon Mobil'),
  ],
  mock: MockQuote(
    price: 5473.2,
    changePct: 0.62,
    spark: [40, 42, 41, 44, 43, 46, 45, 48, 47, 50, 52, 51, 54],
  ),
);

// 🇸🇦 KSA — Tadawul (TASI). Trades Sun–Thu.
const _ksa = MarketConfig(
  id: 'sa',
  name: 'Saudi Arabia',
  city: 'Riyadh',
  nameAr: 'السعودية',
  cityAr: 'الرياض',
  flag: '🇸🇦',
  tz: 'Asia/Riyadh',
  currency: 'SAR',
  index: IndexInfo(label: 'TASI', symbol: '^TASI.SR', sahmk: 'TASI'),
  schedule: Schedule(
    tz: 'Asia/Riyadh',
    days: [0, 1, 2, 3, 4],
    sessions: [
      [600, 900],
    ],
  ),
  priceSource: 'sahmk',
  moversSource: 'sahmk',
  newsSource: 'mock',
  watch: [
    InstrumentRef(symbol: '2222', name: 'Saudi Aramco'),
    InstrumentRef(symbol: '1120', name: 'Al Rajhi Bank'),
    InstrumentRef(symbol: '2010', name: 'SABIC'),
  ],
  movers: [
    InstrumentRef(symbol: '2222', name: 'Saudi Aramco', yahoo: '2222.SR'),
    InstrumentRef(symbol: '1120', name: 'Al Rajhi Bank', yahoo: '1120.SR'),
    InstrumentRef(symbol: '2010', name: 'SABIC', yahoo: '2010.SR'),
    InstrumentRef(symbol: '7010', name: 'STC', yahoo: '7010.SR'),
    InstrumentRef(symbol: '1010', name: 'Riyad Bank', yahoo: '1010.SR'),
  ],
  leaders: [
    InstrumentRef(symbol: '2222', name: 'Saudi Aramco', yahoo: '2222.SR'),
    InstrumentRef(symbol: '1120', name: 'Al Rajhi Bank', yahoo: '1120.SR'),
    InstrumentRef(symbol: '1180', name: 'Saudi National Bank', yahoo: '1180.SR'),
    InstrumentRef(symbol: '2010', name: 'SABIC', yahoo: '2010.SR'),
    InstrumentRef(symbol: '1211', name: "Ma'aden", yahoo: '1211.SR'),
    InstrumentRef(symbol: '7010', name: 'STC', yahoo: '7010.SR'),
    InstrumentRef(symbol: '1010', name: 'Riyad Bank', yahoo: '1010.SR'),
    InstrumentRef(symbol: '1150', name: 'Alinma Bank', yahoo: '1150.SR'),
  ],
  mock: MockQuote(
    price: 11842.5,
    changePct: -0.34,
    spark: [60, 59, 61, 58, 57, 59, 56, 55, 57, 54, 53, 55, 52],
  ),
);

// 🇦🇪 UAE — DFM / ADX. Trades Mon–Fri. Index is the known price-data gap (mock).
const _uae = MarketConfig(
  id: 'ae',
  name: 'UAE',
  city: 'Dubai',
  nameAr: 'الإمارات',
  cityAr: 'دبي',
  flag: '🇦🇪',
  tz: 'Asia/Dubai',
  currency: 'AED',
  index: IndexInfo(label: 'DFM GI', symbol: '^DFMGI'),
  schedule: Schedule(
    tz: 'Asia/Dubai',
    days: [1, 2, 3, 4, 5],
    sessions: [
      [600, 900],
    ],
  ),
  priceSource: 'yahoo',
  newsSource: 'mock',
  watch: [
    InstrumentRef(symbol: 'EMAAR', name: 'Emaar Properties'),
    InstrumentRef(symbol: 'DIB', name: 'Dubai Islamic Bank'),
    InstrumentRef(symbol: 'IHC', name: 'Intl Holding Co'),
  ],
  movers: [
    InstrumentRef(symbol: 'EMAAR', name: 'Emaar Properties', yahoo: 'EMAAR.AE'),
    InstrumentRef(symbol: 'DIB', name: 'Dubai Islamic Bank', yahoo: 'DIB.AE'),
    InstrumentRef(
      symbol: 'DEWA',
      name: 'Dubai Electricity & Water',
      yahoo: 'DEWA.AE',
    ),
    InstrumentRef(symbol: 'SALIK', name: 'Salik', yahoo: 'SALIK.AE'),
    InstrumentRef(symbol: 'DU', name: 'du (EITC)', yahoo: 'DU.AE'),
  ],
  mock: MockQuote(
    price: 4180.9,
    changePct: 0.18,
    spark: [30, 31, 30, 32, 33, 32, 34, 33, 35, 34, 36, 35, 37],
  ),
);

// 🇪🇬 Egypt — EGX (EGX 30). Trades Sun–Thu.
const _egypt = MarketConfig(
  id: 'eg',
  name: 'Egypt',
  city: 'Cairo',
  nameAr: 'مصر',
  cityAr: 'القاهرة',
  flag: '🇪🇬',
  tz: 'Africa/Cairo',
  currency: 'EGP',
  index: IndexInfo(label: 'EGX 30', symbol: '^CASE30'),
  schedule: Schedule(
    tz: 'Africa/Cairo',
    days: [0, 1, 2, 3, 4],
    sessions: [
      [600, 870],
    ],
  ),
  priceSource: 'yahoo',
  newsSource: 'rss',
  newsFeeds: ['https://www.egyptindependent.com/category/business/feed/'],
  watch: [
    InstrumentRef(symbol: 'COMI', name: 'Commercial Intl Bank'),
    InstrumentRef(symbol: 'HRHO', name: 'EFG Holding'),
    InstrumentRef(symbol: 'SWDY', name: 'Elsewedy Electric'),
  ],
  movers: [
    InstrumentRef(symbol: 'COMI', name: 'Commercial Intl Bank', yahoo: 'COMI.CA'),
    InstrumentRef(symbol: 'HRHO', name: 'EFG Holding', yahoo: 'HRHO.CA'),
    InstrumentRef(symbol: 'SWDY', name: 'Elsewedy Electric', yahoo: 'SWDY.CA'),
    InstrumentRef(symbol: 'TMGH', name: 'Talaat Moustafa', yahoo: 'TMGH.CA'),
    InstrumentRef(symbol: 'ETEL', name: 'Telecom Egypt', yahoo: 'ETEL.CA'),
  ],
  mock: MockQuote(
    price: 27960,
    changePct: 1.24,
    spark: [20, 22, 21, 24, 26, 25, 28, 30, 29, 32, 34, 33, 37],
  ),
);

// 🇨🇳 China — Shanghai / Shenzhen (SSE Composite). Mon–Fri with a midday break.
const _china = MarketConfig(
  id: 'cn',
  name: 'China',
  city: 'Shanghai',
  nameAr: 'الصين',
  cityAr: 'شنغهاي',
  flag: '🇨🇳',
  tz: 'Asia/Shanghai',
  currency: 'CNY',
  index: IndexInfo(label: 'SSE Comp', symbol: '000001.SS'),
  schedule: Schedule(
    tz: 'Asia/Shanghai',
    days: [1, 2, 3, 4, 5],
    sessions: [
      [570, 690],
      [780, 900],
    ],
  ),
  priceSource: 'yahoo',
  newsSource: 'rss',
  newsFeeds: ['https://www.scmp.com/rss/92/feed'],
  watch: [
    InstrumentRef(symbol: '600519', name: 'Kweichow Moutai'),
    InstrumentRef(symbol: '601318', name: 'Ping An'),
    InstrumentRef(symbol: '600036', name: 'China Merchants Bank'),
  ],
  movers: [
    InstrumentRef(symbol: '600519', name: 'Kweichow Moutai', yahoo: '600519.SS'),
    InstrumentRef(symbol: '601318', name: 'Ping An', yahoo: '601318.SS'),
    InstrumentRef(
      symbol: '600036',
      name: 'China Merchants Bank',
      yahoo: '600036.SS',
    ),
    InstrumentRef(symbol: '000858', name: 'Wuliangye', yahoo: '000858.SZ'),
    InstrumentRef(symbol: '601988', name: 'Bank of China', yahoo: '601988.SS'),
  ],
  mock: MockQuote(
    price: 3021.7,
    changePct: -0.51,
    spark: [50, 49, 50, 48, 47, 48, 46, 47, 45, 46, 44, 45, 43],
  ),
);

// 🥇 Gold — spot XAU/USD. Commodity: ~24h Mon–Fri.
const _gold = MarketConfig(
  id: 'au',
  name: 'Gold',
  city: 'Spot · London/UTC',
  nameAr: 'الذهب',
  cityAr: 'فوري · لندن/عالمي',
  flag: '🥇',
  tz: 'UTC',
  currency: 'USD',
  index: IndexInfo(label: 'XAU/USD  /oz', symbol: 'GC=F'),
  schedule: Schedule(
    tz: 'UTC',
    days: [1, 2, 3, 4, 5],
    sessions: [
      [0, 1439],
    ],
    commodity: true,
  ),
  priceSource: 'yahoo',
  newsSource: 'rss',
  newsFeeds: ['https://www.kitco.com/rss/'],
  watch: [
    InstrumentRef(symbol: 'GLD', name: 'SPDR Gold ETF'),
    InstrumentRef(symbol: 'IAU', name: 'iShares Gold'),
    InstrumentRef(symbol: 'NEM', name: 'Newmont'),
  ],
  movers: [
    InstrumentRef(symbol: 'GLD', name: 'SPDR Gold ETF'),
    InstrumentRef(symbol: 'IAU', name: 'iShares Gold'),
    InstrumentRef(symbol: 'NEM', name: 'Newmont'),
    InstrumentRef(symbol: 'GOLD', name: 'Barrick Gold'),
  ],
  mock: MockQuote(
    price: 2338.4,
    changePct: 0.41,
    spark: [44, 45, 44, 46, 45, 47, 46, 48, 47, 49, 48, 50, 51],
  ),
);

// 🪙 Crypto — top 5 coins. 24/7 via CoinGecko.
const _crypto = MarketConfig(
  id: 'cr',
  name: 'Crypto',
  city: 'Global · 24/7',
  nameAr: 'العملات الرقمية',
  cityAr: 'عالمي · 24/7',
  flag: '🪙',
  tz: 'UTC',
  currency: 'USD',
  index: IndexInfo(label: 'BTC/USD', symbol: 'bitcoin'),
  schedule: Schedule(
    tz: 'UTC',
    days: [0, 1, 2, 3, 4, 5, 6],
    sessions: [
      [0, 1439],
    ],
    always: true,
  ),
  priceSource: 'coingecko',
  newsSource: 'rss',
  newsFeeds: ['https://www.coindesk.com/arc/outboundfeeds/rss/'],
  coins: [
    CoinRef(id: 'bitcoin', symbol: 'BTC', name: 'Bitcoin'),
    CoinRef(id: 'ethereum', symbol: 'ETH', name: 'Ethereum'),
    CoinRef(id: 'binancecoin', symbol: 'BNB', name: 'BNB'),
    CoinRef(id: 'solana', symbol: 'SOL', name: 'Solana'),
    CoinRef(id: 'ripple', symbol: 'XRP', name: 'XRP'),
  ],
  watch: [
    InstrumentRef(symbol: 'BTC', name: 'Bitcoin'),
    InstrumentRef(symbol: 'ETH', name: 'Ethereum'),
    InstrumentRef(symbol: 'BNB', name: 'BNB'),
    InstrumentRef(symbol: 'SOL', name: 'Solana'),
    InstrumentRef(symbol: 'XRP', name: 'XRP'),
  ],
  mock: MockQuote(
    price: 68450,
    changePct: 2.14,
    spark: [38, 40, 39, 42, 44, 43, 46, 48, 47, 50, 52, 54, 56],
  ),
);
