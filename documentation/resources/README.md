# Resources & feature notes

Supplementary docs for **Stocks Eye** — market-research background plus detailed write-ups of the
three enhancements added on top of the base app. These sit alongside the core docs in
[`../stocks_eye/`](../stocks_eye/README.md); read those first for the architecture.

| Doc | What it covers |
|-----|----------------|
| [00-tooling-landscape.md](00-tooling-landscape.md) | Research: the best stock/ETF analysis tools, APIs, and GitHub projects — and the MENA-coverage gap. Backs the three features below. |
| [01-multi-agent-brief.md](01-multi-agent-brief.md) | **Feature:** the Morning Brief upgraded to a 3-analyst debate + editor (direct DeepSeek). |
| [02-finnhub-adapter.md](02-finnhub-adapter.md) | **Feature:** a live real-time US quote adapter (Finnhub) for USA + Gold movers. |
| [03-cross-market-screener.md](03-cross-market-screener.md) | **Feature:** a sortable/filterable screener across all 7 markets' movers + leaders. |
| [tooling-map/](tooling-map/) | Standalone bilingual (EN/AR) visual map of the tooling landscape — open `index.html` in a browser. |

## How these relate to the core rule
Every feature honoured the project's modularity rule (see the root
[`CLAUDE.md`](../../CLAUDE.md)):
- **Add/swap a data source → one adapter file** in `lib/data/sources/`, then wire it in
  `dashboard_repository.dart`. The Finnhub adapter (02) is a textbook example.
- **The UI never learns which source answered** — the brief (01) and screener (03) render the same
  normalized models regardless of origin.
- **Everything fails soft** to Yahoo → mock, so a tile is never blank.

## Status at time of writing
| # | Feature | Source of truth | Live gate |
|---|---------|-----------------|-----------|
| 01 | Multi-agent Morning Brief | direct DeepSeek (`.env` key) | `DeepSeekSource._multiAgent` |
| 02 | Finnhub live US movers | Finnhub free tier (`.env` key) | presence of `FINNHUB_API_KEY` |
| 03 | Cross-market screener | reuses already-fetched movers/leaders | always on (no key) |
