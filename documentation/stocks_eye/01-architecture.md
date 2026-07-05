# 01 · Architecture

## The core idea: route → normalize → cache → aggregate
Every data source is an isolated **adapter** that returns the app's normalized model. A single
**repository** stitches all sources into the one payload the UI renders, choosing the source per
market and falling back to **mock** on any failure. The UI never knows which source answered.

```
DashboardCubit.load()
  → DashboardRepository.load()                 the ONLY place sources are combined
      ├─ per market (in parallel):
      │    ├─ quote    coingecko | yahoo | mock
      │    ├─ movers   coingecko | yahoo | mock
      │    ├─ leaders  yahoo | []            (+ dividends)
      │    └─ news     rss | mock
      ├─ takes         deepseek(direct|proxy) | mock   (grounded on the built market data)
      ├─ brief         deepseek(direct|proxy) | mock
      └─ watchlist     mock, refreshed with live crypto/gold prices
  → Dashboard { markets[], watchlist[], brief, asOf }
```

## Layers
- **`app/`** — cross-cutting: theme, formatting + sentiment icons, `DataPolicy` (which source mode
  per platform), `AppConfig` (`PROXY_URL`), and the runtime `.env` loader.
- **`data/models/`** — the normalized shapes (immutable, `equatable`).
- **`data/config/`** — the 7 market definitions (`MarketConfig`).
- **`data/sources/`** — one adapter per source; each returns `null`/throws on failure.
- **`data/repository/`** — `market_hours` (open-closed + local time) and the aggregator.
- **`cubit/`** — state: dashboard (load/refresh), clock (1s tick), selection.
- **`ui/`** — the page and widgets.

## Folder map
```
lib/
  main.dart                    loads .env, builds DataPolicy + repository, provides cubits
  app/
    theme.dart                 palette + ThemeData + reusable text styles
    format.dart                Sentiment enum, tabler-icon mapping, Fmt.price/pct/gainLoss
    data_policy.dart           per-platform/per-source: direct | proxy | mock
    config.dart                AppConfig.proxyUrl (from --dart-define=PROXY_URL)
    env.dart / env_io.dart / env_stub.dart   runtime .env loader (io on native, stub on web)
  data/
    models/  schedule · quote · instruments(Mover,Leader,Dividend) · news_item · ai(Take,Brief,
             BriefLine) · watch_row · market_config · market · dashboard · models(barrel)
    config/markets.dart        the 7 MarketConfig definitions
    sources/
      coingecko_source.dart    crypto quote + coins (live everywhere)
      yahoo_source.dart        index quote, movers, leaders + dividends
      rss_source.dart          fetch + parse + entity decode
      deepseek_source.dart     direct DeepSeek client (desktop, key from .env)
      ai_proxy_source.dart     DeepSeek via the proxy
      ai_source.dart           common interface for the two AI backends
      mock_source.dart         the guaranteed fallback dataset
      net.dart                 shared dio + TtlCache + downsample + viaProxyUrl
    repository/
      market_hours.dart        isOpen(schedule) + local clock (IANA tz)
      dashboard_repository.dart the aggregator
  cubit/  dashboard_cubit · clock_cubit · selection_cubit
  ui/
    dashboard_page.dart        topbar · brief · tiles · (detail | watchlist) · footer
    widgets/  topbar · brief_card · market_tile · market_grid · detail_panel · sparkline ·
              common · data_table · movers_table · leaders_table · watchlist_table
proxy/                         thin Node proxy (see 03-ai.md, 05-running-and-config.md)
```

## Modularity rules (keep these)
- **Add or swap a data source → edit one file** in `data/sources/`, then wire it in
  `dashboard_repository.dart`. Never put source-specific logic in the UI or cubits.
- **Add a market → one entry** in `data/config/markets.dart`.
- Every adapter returns the normalized model and fails soft (`null`/throw) so the repository can
  fall through to the next source; `mock_source.dart` is the final fallback.
- The repository is the **only** place that combines sources.

## State & rendering
- `DashboardCubit` owns loading/refreshing (`DashboardLoading | DashboardLoaded | DashboardError`).
- `ClockCubit` emits `DateTime.now()` once a second; tiles/topbar recompute open-closed and local
  clocks from it, so the display ticks without re-fetching data.
- `SelectionCubit` holds the selected market id (drives the detail panel), defaulting to the first
  market on load.
