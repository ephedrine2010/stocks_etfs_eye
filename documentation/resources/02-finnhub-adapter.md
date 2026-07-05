# 02 · Finnhub live-quote adapter

Adds **real-time US stock/ETF quotes** (Finnhub free tier) as a new data source, used for the markets
whose movers are US-listed — **USA and Gold**. This is a textbook run of the core rule: *add a source
→ one adapter file + a few lines of repository wiring; the UI is untouched.*

## Files touched
| File | Change |
|------|--------|
| `lib/data/sources/finnhub_source.dart` | **New** — the adapter |
| `lib/app/data_policy.dart` | Registered `finnhub` as a CORS-direct source |
| `lib/data/repository/dashboard_repository.dart` | Key field, `_finnhub` getter, eligibility check, prefer it in `_movers` |
| `lib/main.dart` | Load `FINNHUB_API_KEY` from `.env`, pass to the repository |
| `.env` | New `FINNHUB_API_KEY=…` line (git-ignored, like the DeepSeek key) |

## The adapter — `FinnhubSource`
- Instance-based (`FinnhubSource(apiKey)`) because it needs a key, unlike the keyless static
  Yahoo/CoinGecko sources.
- `_quoteOf(symbol)` → `(price, changePct)` from `GET /api/v1/quote?symbol=…&token=…`. Fields:
  `c` (current), `pc` (previous close), `dp` (percent change). Prefers Finnhub's own `dp`, else
  computes `(c − pc) / pc`. **Throws when `c == 0`** — the free tier returns `c: 0` for symbols it
  doesn't cover, which the caller treats as "skip".
- `fetchMovers(market)` → each curated ticker priced live, cached `finnhub:t:<symbol>` for 60s (same
  TTL as Yahoo). A failed/uncovered ticker is **skipped, not blanked**.

## Routing & eligibility
`data_policy.dart`: Finnhub is CORS-friendly REST, so `modeFor(DataSource.finnhub)` is always
`direct` (like CoinGecko). Key presence is the repository's concern, not the policy's.

`dashboard_repository.dart`:
- `_finnhub` — returns a `FinnhubSource` only when a non-empty key is present and the source is live.
- `_finnhubMovers(m)` — eligible when a key exists **and every mover ticker is US-listed**, detected
  as *no `.` or `^` in the `yahooTicker`*. This cleanly selects **USA** (`AAPL`, `NVDA`, …) and
  **Gold** (`GLD`, `IAU`, `NEM`, `GOLD`) while excluding `.SR` / `.CA` / `.SS` / `.AE` tickers the
  free tier can't serve.
- `_movers(m)` order: CoinGecko (crypto) → **Finnhub (US-listed)** → Yahoo → mock.

## Coverage matrix (movers)
| Market | Movers source after this change |
|--------|--------------------------------|
| USA | **Finnhub** (real-time) → Yahoo → mock |
| Gold | **Finnhub** (real-time) → Yahoo → mock |
| KSA / UAE / Egypt / China | Yahoo (unchanged) → mock |
| Crypto | CoinGecko (unchanged) |

Headline **index** quotes are unchanged (still Yahoo): Finnhub's free tier does not cover indices
(`^GSPC`) or futures (`GC=F`).

## Setup
1. Free key at [finnhub.io](https://finnhub.io) → dashboard.
2. Add to the git-ignored `.env` at the project root:
   ```
   FINNHUB_API_KEY=your_key_here
   ```
3. Relaunch (`flutter run -d windows`). No key ⇒ the movers path simply falls through to Yahoo, so
   the app behaves exactly as before.

## Notes & limitations
- **Real-time vs close-to-close:** Finnhub gives live intraday price + `dp`; Yahoo's mover path is
  close-to-close. During US market hours the two differ noticeably.
- **No on-screen "source" badge:** the `Mover` model has no source field and the UI was left
  untouched per the core rule, so the difference is in the *values*, not a visible label. Adding a
  small "live" indicator would be a minor `Mover` + UI change (deliberately deferred).
- **Free-tier rate limits** apply; the 60s cache keeps calls modest.

## Verification
`flutter analyze` clean; smoke tests pass. Key validated live during development (an `AAPL` probe
returned a real intraday quote).
