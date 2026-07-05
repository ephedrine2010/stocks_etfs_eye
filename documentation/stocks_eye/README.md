# Stocks Eye — Documentation

Project docs for the **Stocks Eye** Flutter dashboard. Start here, then dive into a topic.

| Doc | What it covers |
|-----|----------------|
| [00-overview.md](00-overview.md) | What the app is, the 7 markets, the screen anatomy |
| [01-architecture.md](01-architecture.md) | Layers, the `route → normalize → cache → aggregate` flow, folder map |
| [02-data-sources.md](02-data-sources.md) | CoinGecko / Yahoo / RSS adapters, the mock fallback, gotchas |
| [03-ai.md](03-ai.md) | The AI Morning Brief + Takes, direct-vs-proxy, cost control |
| [04-ui-and-state.md](04-ui-and-state.md) | Cubits, widgets, tables, responsive layout, theming |
| [05-running-and-config.md](05-running-and-config.md) | How to run each platform, `.env` vs proxy, the proxy server |

See also **[../resources/](../resources/README.md)** — research background and detailed write-ups of
the later enhancements (multi-agent Morning Brief, Finnhub live quotes, cross-market screener).

Related: the root [`CLAUDE.md`](../../CLAUDE.md) (guidance for AI coding assistants),
[`README.md`](../../README.md) (quick run), and [`FLUTTER_BUILD_PLAN.md`](../../FLUTTER_BUILD_PLAN.md)
(the original build plan + decisions).

## One-paragraph summary
Stocks Eye is a multi-market monitoring dashboard for 7 markets (USA, KSA, UAE, Egypt, China, Gold,
Crypto). It shows live open/closed status with per-market local clocks, prices with sparklines, top
movers, leading stocks with dividend yields, per-market news with sentiment, and a daily AI
**Morning Brief**. It's a Flutter rebuild of an earlier Node/vanilla-JS app (kept for reference in
`assets/stocks_eye_old`), using **cubit** for state, **`material_table_view`** for tables,
**`flutter_tabler_icons`** for icons, and **`dio`** for HTTP. It runs on desktop, mobile, and web,
and every data source degrades to bundled mock data so a tile is never blank.
