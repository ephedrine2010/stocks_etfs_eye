# 01 · Architecture

## The core idea: route → normalize → cache → aggregate
Every data source is an isolated **adapter** that returns the app's normalized model. A single
**repository** stitches all sources into the one payload the UI renders, choosing the source per
market and falling back to **mock** on any failure. The UI never knows which source answered.

```
HomeCubit.load()
  → DashboardRepository.load()                 the ONLY place sources are combined
      ├─ per market (in parallel):
      │    ├─ quote    coingecko | yahoo | mock
      │    ├─ movers   coingecko | yahoo | finnhub | mock
      │    ├─ leaders  yahoo | []            (+ dividends)
      │    └─ news     rss | mock
      ├─ takes         deepseek(direct|proxy) | mock   (grounded on the built market data)
      ├─ brief         deepseek(direct|proxy) | mock
      └─ watchlist     mock, refreshed with live crypto/gold prices
  → Dashboard { markets[], watchlist[], brief, asOf }
```

`brief` and `watchlist` are still assembled but nothing renders them since the 2026-08-05
restructure cut the home page back to two sections. They are kept working so either feature can be
brought back by rendering it — not by re-integrating it.

## Feature folders
The app is organised **by feature, not by layer**. Each feature folder owns its cubit and its
widgets; no feature reaches into another's internals. Composition happens in `home/`.

| Folder | Owns |
|--------|------|
| `home/` | the only page, `HomeCubit` (load/refresh), the top bar |
| `screen_all_markets/` | the cross-market screener + `ScreenAllMarketsCubit` |
| `markets_list/` | the live market tiles + `MarketsListCubit` |
| `market_details/` | the details dialog + `MarketDetailsCubit` |
| `shared/widgets/` | primitives every feature composes from |
| `services/` | the repository, market hours, and one adapter per source |
| `data/` | normalized models + the 7 market definitions |
| `app/` | theme + design tokens, formatting, data policy, config, `.env` loader |

## Folder map
```
lib/
  main.dart                    loads .env, builds DataPolicy + repository, provides HomeCubit
  app/
    theme.dart                 palette · AppSpacing/AppRadius/AppIconSize/AppMotion · AppText scale
    format.dart                Sentiment enum, tabler-icon mapping, Fmt.price/pct/gainLoss
    data_policy.dart           per-platform/per-source: direct | proxy | mock
    config.dart                AppConfig.proxyUrl (from --dart-define=PROXY_URL)
    env.dart / env_io.dart / env_stub.dart   runtime .env loader (io on native, stub on web)
  data/
    models/  schedule · quote · instruments(Mover,Leader,Dividend) · news_item · ai(Take,Brief,
             BriefLine) · watch_row · market_config · market · dashboard · models(barrel)
    config/markets.dart        the 7 MarketConfig definitions
  services/
    dashboard_repository.dart  the aggregator
    market_hours.dart          isOpen(schedule) + local clock (IANA tz)
    sources/
      coingecko_source.dart    crypto quote + coins (live everywhere)
      yahoo_source.dart        index quote, movers, leaders + dividends
      finnhub_source.dart      real-time US-listed movers (needs a key)
      rss_source.dart          fetch + parse + entity decode
      deepseek_source.dart     direct DeepSeek client (desktop, key from .env)
      ai_proxy_source.dart     DeepSeek via the proxy
      ai_source.dart           common interface for the two AI backends
      mock_source.dart         the guaranteed fallback dataset
      net.dart                 shared dio + TtlCache + downsample + viaProxyUrl
  home/
    home_page.dart             the page: top bar · screener · markets list · footer
    cubit/home_cubit.dart      HomeLoading | HomeLoaded(refreshing) | HomeError
    widgets/home_topbar.dart   brand · refresh · "N/7 open" badge · live UTC clock
  screen_all_markets/
    screen_all_markets_view.dart
    cubit/screen_all_markets_cubit.dart + _state.dart
  markets_list/
    markets_list_view.dart     section header · open/closed filter · responsive tile grid
    cubit/markets_list_cubit.dart + _state.dart
    widgets/market_tile.dart
  market_details/
    market_details_dialog.dart showMarketDetails(context, market)
    cubit/market_details_cubit.dart + _state.dart
    widgets/  leaders_table · movers_table · news_list · take_block
  shared/widgets/
    surfaces.dart              AppCard · IconChip · EmptyState
    controls.dart              AppPill · PillDivider · AppSearchField
    app_table.dart             thin wrapper over material_table_view
    common.dart                SectionLabel · ChangeText · InfoChip · StatusPill · SentimentIcon
    sparkline.dart             CustomPainter line + area fill
proxy/                         thin Node proxy (see 03-ai.md, 05-running-and-config.md)
```

## Modularity rules (keep these)
- **Add or swap a data source → edit one file** in `services/sources/`, then wire it in
  `services/dashboard_repository.dart`. Never put source-specific logic in the UI or cubits.
- **Add a market → one entry** in `data/config/markets.dart`.
- Every adapter returns the normalized model and fails soft (`null`/throw) so the repository can
  fall through to the next source; `mock_source.dart` is the final fallback.
- The repository is the **only** place that combines sources.
- A feature talks to another feature through a **callback**, not by importing its cubit. The markets
  list and the screener both report a tapped market up to `home_page.dart`, which decides that a tap
  opens the details dialog.

## State & data flow
- `HomeCubit` is the only thing that calls the repository (`HomeLoading | HomeLoaded | HomeError`;
  `HomeLoaded.refreshing` drives the silent refresh).
- `home_page.dart` provides the two section cubits and pushes the loaded markets into them with
  `setMarkets` — via a `BlocListener`, plus a seed in each provider's `create` so a load that
  resolved before the page built isn't missed. **Sections never fetch anything.**
- `MarketsListCubit` runs the page's **one** timer: once a second it recomputes every market's
  open/closed and local clock via `MarketHours` and emits them pre-derived, so tiles stay dumb. The
  top bar's UTC clock and "N open" badge read the same state. Don't add a second app-wide ticker.
- `MarketDetailsCubit` is created with the dialog and disposed with it, so its ticker only runs
  while the dialog is on screen.
