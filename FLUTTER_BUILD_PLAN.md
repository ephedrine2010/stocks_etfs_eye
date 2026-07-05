# Stocks Eye — Flutter Rebuild · Build Plan

A ground-up Flutter rebuild of the `assets/stocks_eye_old` Node/vanilla-JS dashboard.
Same product, same data model, same dark gold-accent look — native Flutter, standalone
(no required backend), with a clean adapter layer that keeps the old app's best property:
**every source falls back to mock, so a tile is never blank.**

## Constraints (fixed by you)
- **State:** `cubit` (via `flutter_bloc`).
- **Tables:** `material_table_view`.
- **Icons:** `flutter_tabler_icons`.
- **Data:** re-implemented in Dart (adapters ported from the Node backend).
- **Platforms:** Android/iOS + Desktop (Win/macOS/Linux) + Web.
- **AI:** wire a live model (DeepSeek — key already in `ai_agents_sub.env`).
- **HTTP client:** `dio` (interceptors, retry, timeout, cancellation).

## Web + AI strategy — DECIDED: thin proxy (option a)
`dio` does **not** solve this — CORS is a browser rule and an embedded key is extractable.
On **mobile/desktop** every source is called directly (no CORS, fully standalone).
On **Web**, Yahoo / RSS / DeepSeek are blocked by CORS (CoinGecko is fine), and any embedded
key leaks.

**Committed design:**
- **Mobile/desktop:** 100% direct-Dart. No proxy in the loop for prices/news.
- **Web:** prices + news route through a **thin proxy** (a trimmed copy of the existing
  `stocks_eye_old` Node server — its Yahoo/RSS adapters are already written).
- **AI (all platforms):** DeepSeek calls go through the proxy so the API key lives server-side
  in the proxy's env (`ai_agents_sub.env`) and is **never** shipped in any client build.
- **Fallback:** if the proxy is unreachable, the affected source falls back to **mock** — the app
  still runs everywhere (CoinGecko stays live on web regardless).

**Wiring:** a `DataPolicy` decides per platform + per source: **direct · via proxy · mock**.
A single `apiBaseUrl` selects the proxy (empty ⇒ direct/mock). Flipping platforms or standing up
the proxy is a config change, never an app-code change.

### The proxy (M5 deliverable)
Reuse `assets/stocks_eye_old/backend`, trimmed to a forwarding layer:
- `GET /api/quote?market=…` · `GET /api/movers?market=…` · `GET /api/leaders?market=…`
- `GET /api/news?market=…`
- `POST /api/ai/take` · `POST /api/ai/brief`  (holds `DEEPSEEK_API_KEY`)
- CORS enabled for the Flutter web origin only.
Run locally with `npm start`, or deploy to a $0 tier (Render / Fly / Cloudflare Workers).

---

## Data model (ported 1:1 from `core/normalizer.js` + market configs)

```dart
Market   { id, name, city, flag, tz, currency, index, schedule,
           open, quote, spark, movers[], leaders[], news[], take, watch[] }
Quote    { price, changePct, currency, spark[], source, asOf }
Mover    { symbol, name, changePct, price? }
Leader   { symbol, name, price, changePct, dividend? }
Dividend { yield, annual, exDate, frequency }
NewsItem { headline, url, source, sentiment(bull|bear|neut), published }
Take     { sentiment, text, citations[], source, asOf }
Brief    { lead, lines[{id,flag,name,s,text}], hint, citations[], source, asOf }
WatchRow { id, flag, symbol, name, native, usd, changePct }
Schedule { tz, days[0-6], sessions[[startMin,endMin]], always?, commodity? }
```

## The 7 markets (ported from `backend/markets/*.js`)
USA (S&P 500 · Yahoo), KSA (TASI · SAHMK→Yahoo), UAE (DFM · Yahoo movers, index mock — known gap),
Egypt (EGX 30 · Yahoo), China (SSE · Yahoo), Gold (XAU · Yahoo, 24h Mon–Fri),
Crypto (BTC + top coins · CoinGecko, 24/7). Each config carries flag, tz, currency, schedule,
`watch`, `movers`, optional `leaders`, news feeds, and a `mock` block.

---

## Architecture

```
lib/
  main.dart                     MultiBlocProvider → DashboardPage
  app/
    theme.dart                  ThemeData: ground #0E1420, surface #1B2333, line #2C3850,
                                ink #E7ECF5/#9AA6BC/#6C7789, accent #E3A93C, gain #34C08A, loss #F26D6D
    format.dart                 fmt / sgn / pct / gainLoss color / sentiment glyph map
    data_policy.dart            per-platform + per-source: direct | proxy | mock
  data/
    models/                     the shapes above (+ fromJson/copyWith)
    config/markets.dart         the 7 market configs
    sources/
      coingecko_source.dart     LIVE everywhere (CORS-ok). quote + coins.
      yahoo_source.dart         index quote (daily %), movers (close-to-close), leaders (+dividends)
      rss_source.dart           fetch + parse + numeric-entity decode; neutral sentiment
      deepseek_source.dart      OpenAI-compatible chat; getTake + getBrief
      mock_source.dart          ported mock dataset — guaranteed fallback
    repository/
      dashboard_repository.dart THE aggregator — the only place sources are combined
      market_hours.dart         isOpen(schedule) + local time (ported from marketHours.js)
      cache.dart                dio interceptor TTLs: quotes 60s, news 15m, take 30m, brief 24h
  cubit/
    dashboard_cubit.dart        DashboardState: loading | loaded(dashboard) | error; load()/refresh()
    clock_cubit.dart            1s tick → UTC clock + each market's local time + open/closed
    selection_cubit.dart        selected market id (drives the detail panel)
  ui/
    dashboard_page.dart         topbar · brief · tiles grid · (detail | watchlist) · footer
    widgets/
      topbar.dart               brand, live UTC clock, market-open badge
      brief_card.dart           AI Morning Brief (gold card)
      market_tile.dart          flag, name/city, open pill (pulsing dot), index, price, %,
      market_grid.dart          sparkline (CustomPainter), local clock, watch chips
      detail_panel.dart         headline + chart + AI Take + leaders + movers + news
      sparkline.dart            CustomPainter (green/red by change)
      movers_table.dart         material_table_view
      leaders_table.dart        material_table_view (ticker/company/price/chg/div-yield)
      watchlist_table.dart      material_table_view (symbol/native/USD/chg)
      sentiment_badge.dart      flutter_tabler_icons: trendingUp/Down/minus
```

**Icon mapping (flutter_tabler_icons):** bull `IconTrendingUp` · bear `IconTrendingDown` ·
neutral `IconMinus` · AI/brief `IconSparkles` · clock `IconClock` · open dot `IconPointFilled` ·
market/eye brand `IconEye` · source/link `IconExternalLink` · dividend `IconCoin`.

**Responsive:** `LayoutBuilder` — desktop/web: tiles grid + side-by-side (detail | watchlist);
mobile: single column, tiles → tap → detail below (or a bottom sheet).

## Gotchas to preserve (from the old CLAUDE.md)
- Yahoo index change % must be **daily** (`previousClose`, not range-relative `chartPreviousClose`).
- Movers use **close-to-close** (last two daily closes), not `regularMarketPrice` — EGX scale bug.
- RSS parser decodes **numeric** entities (`&#8217;`), not just named ones.
- Cache TTLs: quotes 60s · news 15m · AI take 30m · **AI brief 24h, cached only on live success**.
- Crypto `always:true`; Gold `commodity:true` (24h Mon–Fri) — drives status + clock label.
- FX in the watchlist is **static/approximate** (display only) — keep the disclaimer.
- Keep the "not investment advice" disclaimers on news, takes, and the brief.

---

## Milestones

**M0 — Scaffold & theme**
`flutter create` (all platforms) · pubspec: `flutter_bloc`, `dio`, `material_table_view`,
`flutter_tabler_icons`, `intl`, `equatable` · theme.dart · format.dart · empty DashboardPage.

**M1 — Models + market configs + mock source**
Port the data model and 7 configs; port the mock dataset. `DashboardRepository` assembles a
full dashboard from **mock only**. Verifiable payload with no network.

**M2 — UI parity on mock data**
Topbar, brief card, tiles grid (sparkline + pulsing open dot), detail panel, and the three
`material_table_view` tables. Full visual parity, driven entirely by mock. Cubits wired
(dashboard/clock/selection). *This is the "looks done" checkpoint.*

**M3 — Live sources (mobile/desktop first)**
CoinGecko (quote + coins), Yahoo (index %, movers close-to-close, leaders + dividends),
RSS news + entity decode. `DataPolicy` + dio cache interceptor. Each source returns null on
failure → repository falls back to mock. Verify on a desktop build.

**M4 — Live AI (DeepSeek)**
`deepseek_source` (OpenAI-compatible chat): per-market Take + roll-up Morning Brief, grounded on
the snapshot. Mock fallback on any failure. Brief cached 24h on success only.

**M5 — Web policy + polish**
Apply the chosen Web strategy (proxy base-URL, or mock-on-web fallback). Responsive layout pass,
refresh interval, error/empty states, disclaimers. Cross-platform smoke test.

## Dependencies (pubspec)
`flutter_bloc` · `dio` · `material_table_view` · `flutter_tabler_icons` · `intl` · `equatable`
(+ optional `xml` for RSS parsing).

## Open items carried from the original
UAE headline index (movers already live) · KSA/UAE news feeds (outlets 403) · live FX ·
FinBERT sentiment for RSS · per-market live Takes (start mock, brief live first for cost).
```
