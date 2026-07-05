# 00 · Overview

## What it is
**Stocks Eye** is a single-screen monitoring dashboard that watches 7 markets at a glance. It's for
keeping an eye on multiple markets across time zones — which are open right now, where prices sit,
what's moving, and a short AI read on the day.

It is **informational, not investment advice** — that framing is deliberate and the disclaimers in
the UI should stay.

## The 7 markets
| Flag | Market | Index (headline) | Trading week | Notes |
|------|--------|------------------|--------------|-------|
| 🇺🇸 | United States | S&P 500 | Mon–Fri | Leaders + dividends |
| 🇸🇦 | Saudi Arabia | TASI | Sun–Thu | Leaders + dividends |
| 🇦🇪 | UAE | DFM GI | Mon–Fri | Index is mock (known gap); movers live |
| 🇪🇬 | Egypt | EGX 30 | Sun–Thu | |
| 🇨🇳 | China | SSE Composite | Mon–Fri (midday break) | |
| 🥇 | Gold | XAU/USD | ~24h Mon–Fri | Commodity |
| 🪙 | Crypto | BTC/USD | 24/7/365 | Never closes |

Display order is equities → gold → crypto.

## Screen anatomy (top → bottom)
1. **Topbar** — brand, a refresh button, an "N / 7 open" badge, and a live UTC clock.
2. **AI Morning Brief** — a gold-accented card: a lead paragraph, one bull/bear/neutral line per
   market, a "today's hint", and source chips.
3. **Market tiles** — a responsive grid of 7 tiles. Each shows flag, name/city, an open/closed pill
   (with a pulsing dot when open), the index name, price, daily %, a colored sparkline, a **ticking
   local clock**, and watch-symbol chips. Tap a tile to select it.
4. **Detail panel** (for the selected market) — headline price + chart, the **AI Take**, a **Leading
   stocks** table (ticker / company / price / chg / dividend yield), a **Top movers** table, and a
   **news & sentiment** list.
5. **Watchlist** — a cross-market table normalized to USD (symbol / native / USD / chg).
6. **Footer** — trading-hours note and disclaimers.

Open/closed and the clocks are recomputed on the client every second, so tiles tick without any
server round-trip.

## Design language
Dark ground (`#0E1420`) with a gold accent (`#E3A93C`); green (`#34C08A`) for gains, red (`#F26D6D`)
for losses. Monospace, tabular figures for all numbers. Ported 1:1 from the original app's palette.

## Status at a glance
- **Live:** Crypto (CoinGecko), USA/KSA/Egypt/China/Gold indices + movers + leaders (Yahoo),
  news via RSS (USA/Egypt/China/Gold/Crypto), AI Morning Brief (DeepSeek).
- **Mock (by design / known gaps):** UAE headline index, KSA/UAE news, per-market AI Takes.
- Every source falls back to mock on failure, so nothing is ever blank.
