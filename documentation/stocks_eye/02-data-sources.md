# 02 · Data sources

Each source is an isolated adapter in `lib/data/sources/`. All return the normalized model and fail
soft so the repository falls back to the next option (ultimately mock).

## CoinGecko — `coingecko_source.dart`
- **Live everywhere**, including Web (CORS-enabled, no API key).
- `fetchQuote(market)` → the headline coin (BTC) quote with a 7-day sparkline.
- `fetchCoins(market)` → all configured coins as movers.
- Endpoint: `api.coingecko.com/api/v3/coins/markets`. Cached 60s.

## Yahoo Finance — `yahoo_source.dart`
Unofficial public chart endpoint, no key. Covers equity/gold indices, movers, and leaders.
- `fetchQuote` → headline index (range `1mo`, cached 60s).
- `fetchMovers` → each curated ticker priced **close-to-close** from the daily series (cached 60s).
- `fetchLeaders` → weight-ranked bellwethers, close-to-close **plus a dividend summary** from one
  `range=2y&events=div` call (cached 15m).
- **On Web**, Yahoo is CORS-blocked, so calls are routed through the proxy's `/api/fetch` forwarder
  (see `viaProxyUrl`); on native they go direct.

### Gotchas (ported from the original — keep them)
- **Daily change must use the prior-day close** (`meta.previousClose`, else the second-to-last
  close), *not* `chartPreviousClose`, which is range-relative (a ~1-month move on `range=1mo`).
- **Movers use close-to-close, not the live price.** Yahoo's `regularMarketPrice` is unreliable for
  some EGX (`.CA`) tickers — it sits on a different scale than the close series and would fabricate a
  huge fake daily move if mixed in. So price and change both come from the last two daily closes.
- **Dividend yield = trailing-12-month payout ÷ price** (currency-neutral). A genuine non-payer
  returns `null` → the UI shows "—" (a real absence, never "0%").

## RSS news — `rss_source.dart`
- Light regex XML parsing (no dependency). Returns up to 4 items per feed, cached 15m.
- **Decodes numeric entities** (`&#8217;` etc.), not just named ones — WordPress feeds rely on it.
- Handles RFC-822 `pubDate` for the relative "time ago" label.
- Sentiment defaults to **neutral** (FinBERT is a future step). Mock items carry hand-set sentiment.
- Feeds: USA=CNBC, Egypt=Egypt Independent, China=SCMP, Gold=Kitco, Crypto=CoinDesk. KSA/UAE have no
  working feed (outlets 403 a plain fetch) → they use mock news.
- **On Web**, routed through the proxy forwarder like Yahoo.

## Mock — `mock_source.dart`
The guaranteed fallback: quotes (from each market's baked-in `mock` block), movers, news, per-market
takes, the watchlist, and the Morning Brief. This is what keeps a tile from ever going blank.

## Shared plumbing — `net.dart`
- A single `dio` instance (6s connect / 8s receive timeouts, so a slow source fails fast).
- `TtlCache.wrap(key, ttl, fetch)` — an in-memory TTL cache that de-dupes concurrent calls and
  **caches only successful results** (a throw is never cached, so one failure doesn't lock a stale
  value). *Note: the `whenComplete` uses a block body on purpose — an arrow returning
  `map.remove(key)` would return the future being awaited and deadlock it.*
- `viaProxyUrl(url, proxyBase)` — wraps a target through `/api/fetch` when a proxy base is set
  (Web), else returns it unchanged (native).
- `downsample(series, n)` — thins a series to n points for sparklines.

## Cache TTLs (respect free-tier limits)
| Data | TTL |
|------|-----|
| Quotes / movers | 60s |
| Leaders (+dividends) | 15m |
| News | 15m |
| AI Morning Brief | 24h (cached on success only) |

## Live coverage summary
| Market | Index | Movers | Leaders | News |
|--------|-------|--------|---------|------|
| USA | Yahoo | Yahoo | Yahoo ✅ | RSS |
| KSA | Yahoo (`^TASI.SR`) | Yahoo | Yahoo ✅ | mock |
| UAE | **mock** (gap) | Yahoo | — | mock |
| Egypt | Yahoo | Yahoo | — | RSS |
| China | Yahoo | Yahoo | — | RSS |
| Gold | Yahoo | Yahoo | — | RSS |
| Crypto | CoinGecko | CoinGecko | — | RSS |
