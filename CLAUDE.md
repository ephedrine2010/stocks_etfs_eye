# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is
**Stocks Eye** — a Flutter multi-market monitoring dashboard for 7 markets (USA, KSA, UAE, Egypt,
China, Gold, Crypto). The home page is the cross-market **screener** over the live **market tiles**
(open/closed + per-market local clocks, price, sparkline); tapping a market — a tile or a screener
row — opens its **details dialog** (chart, AI Take, leading stocks + dividends, **my stocks**, top
movers, news + sentiment). Tapping a **stock** inside that dialog opens its **price curve** over
1D/1W/1M/3M/6M; **Add stock** searches that market's exchange for anything not already listed.

A ground-up Flutter rebuild of an earlier Node/vanilla-JS app kept for reference in
`assets/stocks_eye_old/` (its own `CLAUDE.md` documents the original). Full docs live in
[`documentation/stocks_eye/`](documentation/stocks_eye/) — read `README.md` there first; they were
updated with the 2026-08-05 feature-folder restructure and match the current code.

| Doc | Covers |
|---|---|
| [`documentation/stocks_eye/`](documentation/stocks_eye/) | The app as a whole — start at `README.md` |
| [`documentation/market-details/market-details.md`](documentation/market-details/market-details.md) | The details dialog and the two surfaces it opens |
| [`documentation/stock-curve-status/stocks-curve-status.md`](documentation/stock-curve-status/stocks-curve-status.md) | Per-instrument price curves |
| [`documentation/firebase/firebase.md`](documentation/firebase/firebase.md) | Firebase connection, auth plan, Firestore rules + shape |
| [`documentation/todo/my-stocks-todo.md`](documentation/todo/my-stocks-todo.md) | **Open work** — where "My stocks" stopped and what's left |

**Historical
records** (`FLUTTER_BUILD_PLAN.md`, `documentation/resources/*`) describe the app as first built and
carry a note saying so — where they disagree, `documentation/stocks_eye/` and this file are right.

**UI language is English only.** The EN/ع toggle, `app/i18n.dart`, `LocaleCubit` and the Arabic
market names were removed on 2026-08-05 — don't reintroduce localized strings without asking.
`LocalizedText` survives in the AI models because the DeepSeek/proxy parsers still return both
sides; nothing renders the Arabic one.

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
- **Design:** follow `.claude/skills/eph-design`, mapped onto this app's palette. No `Colors.*`,
  `Color(0x…)` or `.shade*` in a widget — every colour comes from `AppColors`. Every spacing, radius
  and icon size is a token (`AppSpacing`/`AppRadius`/`AppIconSize`/`AppMotion`) and every text style
  is a named `AppText` style, not a freehand `fontSize:`. Flat surfaces with a 1 px border — no
  gradients, no coloured shadows (a dialog is the one thing allowed to float). Icons are
  `TablerIcons.*`; empty states use the `_off` glyph and say what to do next. Numbers in a column
  carry tabular figures (`AppText.mono`/`numCell`). A surface that opens over the page closes from an
  `X` in its **top-left**.
- Reference the running app on Windows with the built exe under
  `build/windows/x64/runner/Debug/`; kill a stale instance with
  `taskkill //F //IM stocks_etfs_eye.exe` before relaunching.

## Architecture — route → normalize → cache → aggregate
Each source is an isolated **adapter** returning the normalized model; the **repository** is the ONE
place that stitches them together, choosing a source per market and falling back to **mock** on any
failure. The UI never knows which source answered. (See `documentation/stocks_eye/01-architecture.md`.)

```
HomeCubit.load() → DashboardRepository.load()
  per market: quote (coingecko|yahoo|mock) · movers (coingecko|yahoo|mock) ·
              leaders (yahoo|[]) · news (rss|mock)
  then: takes + brief (deepseek direct|proxy|mock) · watchlist (mock + live crypto/gold)
  → Dashboard { markets[], watchlist[], brief, asOf }
```

`Dashboard.brief` and `.watchlist` are still fetched but nothing renders them since the home page
was cut back to its two sections — keep them working; they are the cheapest way to bring either
feature back.

### Feature folders (`lib/`)
One folder per feature, each owning its cubit + widgets; a feature never reaches into another's
internals. Composition happens in `home/`.

| Folder | Holds |
|---|---|
| `home/` | `home_page.dart` (the only page) · `HomeCubit` (loads/refreshes the dashboard) · topbar |
| `screen_all_markets/` | the cross-market screener + `ScreenAllMarketsCubit` (flatten, sort, filter, search) |
| `markets_list/` | the "markets — live status" tiles + `MarketsListCubit` (the 1 s tick, open/closed, filter) |
| `market_details/` | `showMarketDetails()` dialog + `MarketDetailsCubit` (one market, its own tick) · `showInstrumentChart()` dialog + `InstrumentChartCubit` (one stock's curve) · `showAddStock()` dialog + `MyStocksCubit`/`StockSearchCubit` (the user's own stocks) |
| `shared/widgets/` | primitives every feature uses: `AppCard`/`IconChip`/`EmptyState`, `AppPill`/`AppSearchField`, `AppTable`, `Sparkline`/`PriceChart`, `ChangeText`/`StatusPill`/`InfoChip` |
| `services/` | `dashboard_repository.dart` (the aggregator) · `price_history_service.dart` (price curves, on demand) · `my_stocks_service.dart` (search + rows for added stocks) · `my_stocks_store.dart` (where the added list lives) · `market_hours.dart` · `sources/` (one file per source) |
| `data/` | `models/` · `config/markets.dart` (the 7 markets) |
| `app/` | theme + design tokens, format, data_policy, config, env loader |

`proxy/` is a thin Node server (holds the DeepSeek key; forwards CORS-blocked web requests).

**One timer for the page.** `MarketsListCubit` ticks once a second and derives every market's
open/closed + local clock; the topbar's UTC clock and "N open" badge read the same state. Don't add
a second app-wide ticker. `MarketDetailsCubit` runs its own only while the dialog is open.

**Feeding the sections.** `HomeCubit` is the only thing that touches the repository; `home_page.dart`
pushes the loaded markets into the two section cubits via `setMarkets` (a `BlocListener`, plus a seed
in each provider's `create` so a load that resolved early isn't missed). Sections never fetch.

## The core rule: modularity
- **Add or swap a data source → edit ONE file** in `lib/services/sources/`, then wire it in
  `services/dashboard_repository.dart`. Never put source-specific logic in the UI or cubits.
- **Add a market → ONE entry** in `lib/data/config/markets.dart`.
- Every adapter returns the normalized model and fails soft (`null`/throw) so the repository falls
  through; `mock_source.dart` is the guaranteed final fallback so a tile is never blank.

## Price curves — the one thing that never mocks
`PriceHistoryService` (`services/price_history_service.dart`) fetches one instrument's curve over a
`HistoryRange` (**1D/1W/1M/3M/6M**) and is **not** part of `DashboardRepository.load()` — charts are
fetched on demand, reached via `repository.history`. It routes Yahoo (equities/gold, all 5 ranges via
`YahooSource.fetchSeries`) or CoinGecko (crypto, `fetchSeries`), honours `DataPolicy`, and caches per
(instrument, range).

**It returns `null` — "N.A." — rather than falling back to mock.** That is the deliberate exception
to the app's never-blank rule: a drawn line reads as a real price history, so an invented one would
lie in a way a placeholder tile does not. Don't add a `MockSource` branch to this path.

Widgets never translate a display symbol (`2222`) into a source id (`2222.SR`, `bitcoin`) —
`HistoryTarget.forSymbol(config, symbol)` / `.index(config)` do, and return `null` for an unknown
symbol instead of guessing a ticker. A table row is tappable only when its target resolves **and**
`service.canServe(target)` (so Web-without-proxy correctly offers nothing for Yahoo-backed rows).
`HistoryRange` carries the Yahoo `range`+`interval`, CoinGecko `days` and cache TTL, so a new window
is one line. Full write-up:
[`documentation/stock-curve-status/stocks-curve-status.md`](documentation/stock-curve-status/stocks-curve-status.md).

## My stocks — searching beyond the curated lists
The details dialog's **My stocks** section (between the curated leaders and the session's movers)
lets the user search their market's exchange and follow any listing. `MyStocksService`
(`services/my_stocks_service.dart`) routes the search — Yahoo for equities/gold, CoinGecko for
crypto — and prices the kept rows through the *same* `fetchLeaderRow` the curated leaders use, so an
added row is not a lesser shape. Like the price curves it is outside `DashboardRepository.load()`
and **never mocks**: an invented hit could never be priced or charted afterwards, so `[]` is the
answer to both "no match" and "lookup failed".

- **Results are scoped to the market's own exchange**, and the suffix set is *derived* from that
  market's `movers`+`leaders` in `markets.dart` (`.SR`, `.CA`, `.SS`/`.SZ`, or none) — not a second
  table. Adding a market stays ONE entry. `watch` refs are excluded because they omit the `yahoo:`
  field and would contribute a bogus empty suffix.
- **Yahoo's search index doesn't cover every exchange its chart endpoint serves** — EGX (`.CA`)
  returns nothing for *any* query, though `COMI.CA` prices fine. So an empty scoped search falls back
  to `_probeAsTicker`, which tries `<query><suffix>` and offers it **only after a real quote comes
  back**. That's a verification, not a guess — keep it that way.
- `SavedStock` stores **identity only** (`marketId·symbol·name·query·provider`), never a price. The
  stored `query` is what makes an added stock chartable via `HistoryTarget.fromSaved` without
  weakening the "never guess a ticker" rule.
- `MyStocksStore` is the **persistence seam** — in-memory today; Firestore (`ephedrine2010/{uid}`)
  plus a local mirror slot in behind the same surface, so neither the cubits nor the widgets change.
- Live probe: `flutter test test/search_probe.dart`.

> ⚠️ **The added list is session-only right now** — it resets when the app closes. Persistence is
> built but *not wired*: `firestore.rules` requires a signed-in user and the app has no sign-in yet.
> The plan, decisions already made, and console state are in
> [`documentation/todo/my-stocks-todo.md`](documentation/todo/my-stocks-todo.md) — **read it before
> touching this feature**.

## Firebase
`Firebase.initializeApp()` runs before the first frame in `main.dart`, wrapped in a try/catch —
**fail-soft on purpose**: the dashboard is public market data and must run without it. Project
`stocketfseye`; `firebase_core` is the only Firebase package installed so far.

- **Firestore rules already require `request.auth != null`**, and nothing signs in — so any Firestore
  call today returns `PERMISSION_DENIED`. That's the blocker for persistence, not a bug.
- Planned: real Google sign-in, per-user doc at **`ephedrine2010/{uid}`**, gating **only** the "My
  stocks" section — never the dashboard.
- **`google_sign_in` has no Windows support** (the primary dev platform); Windows needs a loopback
  OAuth + PKCE flow. `cloud_firestore` and `firebase_auth` *do* support Windows; nothing Firebase
  supports Linux.
- OAuth credentials live in `.env` (gitignored) as `GOOGLE_OAUTH_CLIENT_ID` /
  `GOOGLE_OAUTH_CLIENT_SECRET` — **never hardcode them**, same rule as the DeepSeek key.
- Full detail: [`documentation/firebase/firebase.md`](documentation/firebase/firebase.md).

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
- **`YahooSource.fetchSeries` is deliberately separate from `_fetchChart`** — the latter exists to
  derive a daily change and hard-codes `interval=1d`; merging them re-entangles that rule with the
  chart's interval. `fetchSeries` keeps the timestamps and **skips null closes, never fills them**
  (a gap in the data is a gap in the line).
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
- **Not investment advice** — keep the disclaimers on the takes, news and screener.
- **The pulsing status dot builds its `AnimationController` in `initState`, never lazily** — a
  `late final` initialiser first runs inside `dispose()` for a dot that never pulsed (a closed
  market) and throws on a deactivated element. Keep the comment in `shared/widgets/common.dart`.

## Where to extend next (open items)
**In flight — start here:** persist "My stocks" to Firestore. Needs Google sign-in first (the rules
already demand it). Stages, decisions and console state:
[`documentation/todo/my-stocks-todo.md`](documentation/todo/my-stocks-todo.md).

- Point the details dialog's 14-point sparkline at **`HistoryTarget.index(config)`** for a real,
  range-selectable index curve — the service already supports it; nothing is wired yet.
- A real **UAE headline-index source** (movers already live).
- **KSA / UAE news feeds** (outlets 403 a plain fetch).
- A home for the **Morning Brief** and the **watchlist** in the new layout (both still fetched, both
  currently unrendered; the old widgets are in git history at `lib/ui/widgets/`).
- **Live FX** for the watchlist (currently static/approximate, display-only).
- **FinBERT** sentiment for RSS headlines (currently neutral).
- **Live per-market Takes** (flip the cost gate) and/or deploy the proxy for a shareable Web build.
- A **SAHMK** adapter for the official TASI index (today KSA falls back to Yahoo `^TASI.SR`).
