# Stocks Eye — Documentation

Project docs for the **Stocks Eye** Flutter dashboard. Start here, then dive into a topic.

| Doc | What it covers |
|-----|----------------|
| [00-overview.md](00-overview.md) | What the app is, the 7 markets, the screen anatomy |
| [01-architecture.md](01-architecture.md) | Feature folders, the `route → normalize → cache → aggregate` flow, folder map |
| [02-data-sources.md](02-data-sources.md) | CoinGecko / Yahoo / Finnhub / RSS adapters, the mock fallback, gotchas |
| [03-ai.md](03-ai.md) | The AI Morning Brief + Takes, direct-vs-proxy, cost control |
| [04-ui-and-state.md](04-ui-and-state.md) | The four cubits, widgets, tables, responsive layout, the design system |
| [05-running-and-config.md](05-running-and-config.md) | How to run each platform, `.env` vs proxy, the proxy server |

See also **[../stock-curve-status/stocks-curve-status.md](../stock-curve-status/stocks-curve-status.md)**
— per-instrument price curves (1D/1W/1M/3M/6M): the reusable `PriceHistoryService`, the `PriceChart`
widget, and the one data path in the app that shows **"N.A." instead of mock**.

See also **[../resources/](../resources/README.md)** — research background and detailed write-ups of
the later enhancements (multi-agent Morning Brief, Finnhub live quotes, cross-market screener).

Related: the root [`CLAUDE.md`](../../CLAUDE.md) (guidance for AI coding assistants),
[`README.md`](../../README.md) (quick run), and [`FLUTTER_BUILD_PLAN.md`](../../FLUTTER_BUILD_PLAN.md)
(the original build plan + decisions).

## One-paragraph summary
Stocks Eye is a multi-market monitoring dashboard for 7 markets (USA, KSA, UAE, Egypt, China, Gold,
Crypto). Its home page is a cross-market **screener** over a grid of live **market tiles** — open/
closed status with per-market local clocks, price, daily %, sparkline — and tapping any market opens
a **details dialog** with its chart, AI Take, leading stocks with dividend yields, top movers, and
news with sentiment. It's a Flutter rebuild of an earlier Node/vanilla-JS app (kept for reference in
`assets/stocks_eye_old`), using **cubit** for state, **`material_table_view`** for tables,
**`flutter_tabler_icons`** for icons, and **`dio`** for HTTP. It runs on desktop, mobile, and web,
and every data source degrades to bundled mock data so a tile is never blank.

> **Restructured 2026-08-05.** The app moved from `ui/` + `cubit/` layers to one folder per feature
> (`home/`, `screen_all_markets/`, `markets_list/`, `market_details/`, `shared/`, `services/`), the
> UI became English-only, and the Morning Brief card and watchlist table were removed from the page.
> These docs describe the current code; `../resources/` describes the design work that led up to it
> and is a historical record.
