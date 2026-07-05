# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is
**Stocks Eye** — a Flutter multi-market monitoring dashboard for 7 markets (USA, KSA, UAE, Egypt,
China, Gold, Crypto). Live open/closed status + per-market local clocks, prices with sparklines, top
movers, leading stocks + dividends, per-market news + sentiment, and a daily AI **Morning Brief**.

A ground-up Flutter rebuild of an earlier Node/vanilla-JS app kept for reference in
`assets/stocks_eye_old/` (its own `CLAUDE.md` documents the original). Full docs live in
[`documentation/stocks_eye/`](documentation/stocks_eye/) — read `README.md` there first.

## Stack (fixed — don't swap without asking)
- **State:** `cubit` via `flutter_bloc`. No other state-management lib.
- **Tables:** `material_table_view`. **Icons:** `flutter_tabler_icons`. **HTTP:** `dio`.
- Also: `intl`, `equatable`, `timezone` (IANA tz for market hours).
- Runs on Android/iOS, desktop (Windows/macOS/Linux), and Web.

## Commands
```bash
flutter pub get
flutter analyze                     # keep this clean — zero issues
flutter test                        # offline widget + no-overflow smoke tests
flutter run -d windows              # desktop (reads .env for live AI; see below)
flutter build web                   # web MUST use the proxy for live data
flutter test test/live_probe.dart   # manual live probe (real endpoints; AI test needs the proxy)
```
The default `flutter test` is offline/deterministic; the live probe is excluded by filename (no
`_test` suffix). When done with nontrivial UI changes, re-run `flutter test` — the smoke tests
assert **no overflow at 320–390 px**, which catches the most common regressions.

## Conventions
- 2-space indent; `const` wherever possible; models are immutable + `equatable`.
- File references in prose use `path:line`. Match the surrounding code's style.
- Reference the running app on Windows with the built exe under
  `build/windows/x64/runner/Debug/`; kill a stale instance with
  `taskkill //F //IM stocks_etfs_eye.exe` before relaunching.

## Architecture — route → normalize → cache → aggregate
Each source is an isolated **adapter** returning the normalized model; the **repository** is the ONE
place that stitches them together, choosing a source per market and falling back to **mock** on any
failure. The UI never knows which source answered. (See `documentation/stocks_eye/01-architecture.md`.)

```
DashboardCubit.load() → DashboardRepository.load()
  per market: quote (coingecko|yahoo|mock) · movers (coingecko|yahoo|mock) ·
              leaders (yahoo|[]) · news (rss|mock)
  then: takes + brief (deepseek direct|proxy|mock) · watchlist (mock + live crypto/gold)
  → Dashboard { markets[], watchlist[], brief, asOf }
```

Directory map (`lib/`): `app/` (theme, format, data_policy, config, env loader) · `data/models/` ·
`data/config/markets.dart` (the 7 markets) · `data/sources/` (one file per source) ·
`data/repository/` (market_hours + aggregator) · `cubit/` · `ui/` (page + widgets).
`proxy/` is a thin Node server (holds the DeepSeek key; forwards CORS-blocked web requests).

## The core rule: modularity
- **Add or swap a data source → edit ONE file** in `lib/data/sources/`, then wire it in
  `dashboard_repository.dart`. Never put source-specific logic in the UI or cubits.
- **Add a market → ONE entry** in `lib/data/config/markets.dart`.
- Every adapter returns the normalized model and fails soft (`null`/throw) so the repository falls
  through; `mock_source.dart` is the guaranteed final fallback so a tile is never blank.

## AI (DeepSeek) — key handling
Two interchangeable backends behind `AiSource`: **direct** (`deepseek_source.dart`, desktop, key
from a local `.env`) and **proxy** (`ai_proxy_source.dart`). `DataPolicy` picks: native prefers a
local `.env` key, else proxy, else mock; **Web only uses the proxy** (CORS + no filesystem).
**Never embed the key in the client** — that's the whole reason the proxy and the runtime-`.env`
loader exist. Cost control default: Morning Brief live (cached 24h), per-market Takes mock — gated
by `_liveBrief/_liveTakes` (direct) or `LIVE={takes,brief}` (proxy). See `documentation/stocks_eye/03-ai.md`.

## Platform / data policy
`DataPolicy.modeFor(source)` returns `direct | proxy | mock`. Native → direct for
CoinGecko/Yahoo/RSS. **Web → Yahoo/RSS are CORS-blocked**, so they route through the proxy's
`/api/fetch` (via `viaProxyUrl`); CoinGecko is CORS-OK and always direct. The user's normal workflow
is **Option 1** (desktop `.env`, no proxy) — don't tell them to start the proxy for desktop use.

## Gotchas to preserve (ported from the original)
- **Yahoo daily change** uses the prior-day close (`previousClose` / 2nd-to-last close), NOT
  `chartPreviousClose` (range-relative).
- **Movers use close-to-close**, not `regularMarketPrice` — Yahoo's live price is on a different
  scale for some EGX `.CA` tickers and fabricates fake moves if mixed with closes.
- **Dividend yield = TTM payout ÷ price**; a non-payer returns `null` → UI shows "—", never "0%".
- **RSS parser decodes numeric entities** (`&#8217;`), not just named ones.
- **`TtlCache.wrap`**: the `whenComplete` MUST use a block body, not `=> map.remove(key)` — an arrow
  returns the future being awaited and self-deadlocks (this bug happened once; keep the comment).
- **Cache TTLs:** quotes/movers 60s · leaders/news 15m · brief 24h (success only). Respect free tiers.
- **Crypto** `always:true` (24/7); **Gold** `commodity:true` (24h Mon–Fri) — these flags drive the
  status + clock label. Open/closed + clocks are recomputed client-side each second.
- **UAE headline index is intentionally mock** (Yahoo lacks `^DFMGI`); its movers are live.
- **Not investment advice** — keep the disclaimers in the brief, takes, and news.

## Where to extend next (open items)
- A real **UAE headline-index source** (movers already live).
- **KSA / UAE news feeds** (outlets 403 a plain fetch).
- **Live FX** for the watchlist (currently static/approximate, display-only).
- **FinBERT** sentiment for RSS headlines (currently neutral).
- **Live per-market Takes** (flip the cost gate) and/or deploy the proxy for a shareable Web build.
- A **SAHMK** adapter for the official TASI index (today KSA falls back to Yahoo `^TASI.SR`).
