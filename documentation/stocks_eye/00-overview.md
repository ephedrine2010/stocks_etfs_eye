# 00 · Overview

## What it is
**Stocks Eye** is a single-screen monitoring dashboard that watches 7 markets at a glance, with a
per-market details dialog one tap away. It's for keeping an eye on multiple markets across time
zones — which are open right now, where prices sit, what's moving, and a short AI read on the day.

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

## Screen anatomy
One page, two sections, and a dialog.

**Home (top → bottom)**
1. **Top bar** — brand, a refresh button, an "N / 7 open" badge, and a live UTC clock.
2. **Screen — all markets** — the cross-market screener: every market's movers and leading stocks
   flattened into one table (mkt / ticker / company / price / chg / div). Tap a column to sort;
   filter by gainers/losers, by market, or by a ticker/name search.
3. **Markets — live status** — a responsive grid of 7 tiles, filterable by All / Open / Closed. Each
   tile shows flag, name/city, an open/closed pill (with a pulsing dot when open), the index name,
   price, daily %, a coloured sparkline, a **ticking local clock**, and watch-symbol chips.
4. **Footer** — trading-hours note and disclaimers.

**Market details (dialog)** — opened by tapping a tile *or* a screener row, and closed from the `X`
in its top-left. Header (flag · index · price · daily %), then a status strip (open/closed, the
market's own clock, which source answered, currency), the chart, the **AI Take**, a **Leading
stocks** table (ticker / company / price / chg / dividend yield), a **Top movers** table, and a
**news & sentiment** list.

Open/closed and the clocks are recomputed on the client every second, so tiles tick without any
server round-trip.

The UI is **English only**. The AI **Morning Brief** and the USD **watchlist** are still fetched but
are not currently rendered anywhere (see 01-architecture.md).

## Design language
Dark ground (`#0E1420`) with a gold accent (`#E3A93C`); green (`#34C08A`) for gains, red (`#F26D6D`)
for losses. Monospace, tabular figures for all numbers. Ported 1:1 from the original app's palette.
Flat surfaces with a 1 px border — no gradients, no coloured shadows. Spacing, radii, icon sizes and
text styles all come from tokens in `app/theme.dart`; see 04-ui-and-state.md.

## Status at a glance
- **Live:** Crypto (CoinGecko), USA/KSA/Egypt/China/Gold indices + movers + leaders (Yahoo),
  news via RSS (USA/Egypt/China/Gold/Crypto), AI Morning Brief (DeepSeek).
- **Mock (by design / known gaps):** UAE headline index, KSA/UAE news, per-market AI Takes.
- **Fetched but not rendered:** the AI Morning Brief and the USD watchlist.
- Every source falls back to mock on failure, so nothing is ever blank.
