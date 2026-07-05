# 00 · Stock & ETF analysis tooling landscape

Research background (mid-2026) for choosing what to build on. Grouped by where each tool sits in the
same `route → normalize → aggregate` pipeline Stocks Eye already runs. A visual, bilingual (EN/AR)
version lives in [`tooling-map/`](tooling-map/) — open `index.html` in any browser.

## The pipeline view
```
Data feeds → Research platform → Screen / test → AI layer → Your app
Finnhub      OpenBB              TradingView      TradingAgents   Stocks Eye
Twelve Data  Okama               Finviz · Koyfin  FinRobot        (brief · movers
Alpha V.                         Backtesting.py                    news · screener)
FMP
```

## Standouts by category

### Research platforms
- **[OpenBB](https://github.com/OpenBB-finance/OpenBB)** — open-source; ~900 commands, 8 asset
  classes, ~100 data sources behind one Python API. Built for "analysts, quants & AI agents". It is
  essentially our route→normalize→aggregate pattern at scale — the best architecture reference.
- **Okama** — Python portfolio analysis/optimization across many exchanges.

### Screeners / research services
- **TradingView** — best all-round stock+ETF screener; ~150 metrics, Pine Script indicators/alerts.
- **Koyfin** — 500+ fundamental metrics, 10-yr history. **Finviz** — fast free stock screening.
- **stockanalysis.com** / **ETF Database** / **etf.com** — dedicated ETF screeners.
- **Backtesting.py** — clean strategy backtesting (stocks/crypto/FX).

### AI / LLM frameworks (informed feature 01)
- **[TradingAgents](https://github.com/TauricResearch/TradingAgents)** — multi-agent LLM desk:
  fundamental, sentiment & technical analysts debate a call. Directly inspired our multi-agent brief.
- **FinRobot**, **virattt/ai-financial-agent**, **awesome-ai-in-finance** (curated list).

### Data APIs with usable free tiers (informed feature 02)
| Provider | Free tier | Best for |
|----------|-----------|----------|
| **Finnhub** | free real-time US quotes + WebSocket | live prices (chosen for 02) |
| Twelve Data | 800 calls/day (delayed) | broad coverage |
| Alpha Vantage | 25/day, 500/mo | 50+ technical indicators |
| Financial Modeling Prep | limited | fundamentals/statements |

## The catch — market coverage
Almost every tool above is **US / global-first**. Our MENA markets are the real gap:

| Market | Global tools | Free data APIs | Our path today |
|--------|-------------|----------------|----------------|
| USA · Crypto · Gold | Full | Full / partial | Finnhub / CoinGecko / Yahoo |
| China | Partial | Partial | Yahoo |
| KSA · TASI | Weak | Weak | Yahoo `^TASI.SR` · SAHMK (todo) |
| UAE · DFM/ADX | Weak | Weak | movers live · index mock |
| Egypt · EGX | Weak | Weak | Yahoo `.CA` (close-to-close) |

No off-the-shelf tool covers TASI / DFM / EGX well; regional sources (Argaam, Mubasher) stay
scrape-only. **That gap is the app's differentiator** — see the open items in the root `CLAUDE.md`.

## What we acted on
1. **OpenBB** validated the adapter pattern → we extended it with a new source (02).
2. **TradingAgents** → the multi-agent Morning Brief (01).
3. **Finnhub** → live real-time US quotes for USA + Gold movers (02).
4. A cross-market **screener** (03) leans on the "screen/test" idea but reuses our own live data so it
   works for every market, MENA included, with zero extra API calls.
