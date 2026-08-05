# Stock curve status — per-instrument price history

Added **2026-08-05**. Tapping a stock in the market details dialog opens that instrument's price
curve over a selectable window — **1D · 1W · 1M · 3M · 6M**.

The fetching half is a standalone, reusable service (`PriceHistoryService`); the drawing half is a
standalone, reusable widget (`PriceChart`). Neither knows about the details dialog, so either can be
pointed at any instrument — a mover, a leading stock, a market's own headline index, a future
watchlist row.

> **This feature never mocks.** Where the rest of the app degrades to `MockSource` so a tile is never
> blank, a curve that can't be fetched shows **"N.A."**. A drawn line is read as a real price
> history; an invented one would be a lie in a way a placeholder tile is not.

---

## The user flow
```
market tile / screener row
  → market details dialog
      → tap a highlighted (gold) ticker in "Leading stocks" or "Top movers"
          → instrument chart dialog  [1D] [1W] [1M] [3M] [6M]
```
A ticker is **gold and tappable only when its curve can actually be fetched here** — the symbol
resolves in that market's config *and* the platform can reach its source. Anything else stays plain
and inert, so a tap never opens a dialog that can only say "N.A.".

Both dialogs close from the `X` in the **top-left**, per the design rule.

---

## Files

| File | Role |
|---|---|
| `lib/services/price_history_service.dart` | **The service.** `HistoryTarget` + `PriceHistoryService` — routes, caches, returns null |
| `lib/data/models/price_history.dart` | `HistoryRange` (the windows), `PricePoint`, `PriceHistory` |
| `lib/shared/widgets/price_chart.dart` | **The chart.** Line + area + guides + scrubbing crosshair |
| `lib/market_details/widgets/instrument_chart_dialog.dart` | The dialog: header → range pills → curve/N.A. |
| `lib/market_details/cubit/instrument_chart_cubit.dart` | Owns the selected window and its fetch |
| `test/history_probe.dart` | Live probe (excluded from `flutter test` — no `_test` suffix) |

Changed: `yahoo_source.dart` + `coingecko_source.dart` (a new `fetchSeries` each),
`dashboard_repository.dart` (`.history` getter), `market_details_dialog.dart`,
`leaders_table.dart` + `movers_table.dart` (tappable rows), `models.dart` (barrel), `smoke_test.dart`.

---

## Using the service

```dart
// Anywhere with the repository in scope (it's a RepositoryProvider above MaterialApp):
final service = context.read<DashboardRepository>().history;

final target = HistoryTarget.forSymbol(marketConfig, 'AAPL');  // null ⇒ not in this market
if (target != null && service.canServe(target)) {              // false ⇒ unreachable here
  final curve = await service.fetch(target, HistoryRange.months3);
  if (curve == null) { /* show "N.A." */ } else { PriceChart(history: curve); }
}
```

### `HistoryTarget` — resolving a symbol to a queryable id
The UI has a **display** symbol (`2222`, `BTC`); a source wants **its own** id (`2222.SR`,
`bitcoin`). That translation lives in the service, never in a widget.

| Factory | Resolves |
|---|---|
| `HistoryTarget.forSymbol(config, symbol)` | movers → leaders → watch → coins, by display symbol (case-insensitive). Yahoo ticker via `InstrumentRef.yahooTicker`; coins via `CoinRef.id` |
| `HistoryTarget.index(config)` | the market's headline index — CoinGecko for a coin market, else Yahoo |

**An unknown symbol returns `null`** — the service never guesses a ticker from a display string.

### `PriceHistoryService`
| Member | Does |
|---|---|
| `canServe(target)` | Can this platform reach that source at all? (Web without a proxy ⇒ Yahoo is false.) Lets a caller hide an affordance |
| `fetch(target, range)` | The curve, or **`null`** — blocked, empty, fewer than 2 points, or a throw |

`fetch` catches everything and returns `null`. One point is a dot, not a curve, so it counts as
nothing to show.

---

## The windows — `HistoryRange`

One enum carries the pill label, the Yahoo pair, the CoinGecko `days`, and the cache TTL, so adding
`1Y` is a single line and every layer follows.

| Range | Label | Yahoo `range` | Yahoo `interval` | CoinGecko `days` | TTL |
|---|---|---|---|---|---|
| `day` | 1D | `1d` | `5m` | 1 | 60s |
| `week` | 1W | `5d` | `30m` | 7 | 60s |
| `month` | 1M | `1mo` | `1d` | 30 | 15m |
| `months3` | 3M | `3mo` | `1d` | 90 | 15m |
| `months6` | 6M | `6mo` | `1d` | 180 | 15m |

`isIntraday` (`interval != '1d'`) drives both the TTL tier and the axis format — clock times for
1D/1W, dates for the rest. **1D and 1W are genuinely intraday**, not daily closes.

CoinGecko picks its own granularity from `days` on the free tier (5-minutely ≤1 day, hourly ≤90
days, daily beyond), so no interval is requested — which is why 3M returns *more* points than 6M.

---

## The adapters

Both are additive; neither touches the existing quote/movers/leaders paths.

### `YahooSource.fetchSeries(symbol, range, {proxyBase})`
`v8/finance/chart/{symbol}?range=…&interval=…`, returns `List<PricePoint>`.

**Deliberately separate from `_fetchChart`.** That one exists to derive a *daily change* and
hard-codes `interval=1d` — the prior-day-close gotcha stays isolated there. `fetchSeries` varies the
interval and, unlike `_fetchChart`, **keeps the timestamps**.

Yahoo pads holidays, halts and pre-market gaps with `null` closes. Those points are **skipped, never
filled** — a gap in the data is a gap in the line.

### `CoinGeckoSource.fetchSeries(id, range)`
`coins/{id}/market_chart?vs_currency=usd&days=…`, returns `List<PricePoint>`.

Both cache through the shared `netCache` under `…:hist:{id}:{range}` at `range.ttl`.

---

## Coverage

| Market | Curves for stocks | Via | Note |
|---|---|---|---|
| USA | ✅ all 5 ranges | Yahoo | movers + leaders |
| KSA | ✅ all 5 ranges | Yahoo | `.SR` tickers |
| UAE | ✅ movers | Yahoo | the **index** has no source (unchanged gap) |
| Egypt | ✅ all 5 ranges | Yahoo | `.CA` tickers |
| China | ✅ all 5 ranges | Yahoo | |
| Gold | ✅ all 5 ranges | Yahoo | US-listed ETFs |
| Crypto | ✅ all 5 ranges | CoinGecko | works on Web too (CORS-OK) |

**On Web without a proxy**, Yahoo is unreachable, so every equity/gold ticker correctly goes inert
and only Crypto charts. On desktop (the normal workflow, `.env`, no proxy) everything above is live.

Live probe, observed 2026-08-05:
```
AAPL  1D   79 pts   1W   66 pts   1M   23 pts   3M   63 pts   6M  124 pts
BTC   1D  289 pts   1W  169 pts   1M  721 pts   3M 2161 pts   6M  181 pts
```

---

## The chart — `PriceChart`

The grown-up sibling of `Sparkline`, which stays a decorative 14-point mark on tiles.

- Line + soft area fill, colored by the **window's own** change.
- Horizontal guides at the window high / midpoint / low, each labelled in the right gutter.
- Date axis: first and last point.
- **Scrubbing crosshair** on hover (desktop) and tap/drag (touch) — the readout shows that point's
  price and timestamp; releasing returns to the latest close.
- Draws only the points it is given. No interpolation, no smoothing across gaps.

The headline change is the **period** move, not the day's: on `3M` it reads as the 3-month change.
A zero opening value yields `changePct == null` → the readout shows "—", never a fake 0%.

---

## State — `InstrumentChartCubit`

`InstrumentChartState { target, range, history?, loading }`. Created with the dialog, disposed with
it. It holds no timer — the market details cubit's clock is unaffected, and the "one timer for the
page" rule still holds.

- `select(range)` emits `loading`, fetches, then emits the result.
- **A slower earlier window can't overwrite a newer selection** — the result is dropped if
  `state.range` moved on while it was in flight.
- `copyWith` passes `history` through *un-defaulted* on purpose: a window with no data must **clear**
  the previous curve, not keep showing it under a new label.

---

## Gotchas to preserve

- **No mock, ever.** `fetch` returns `null` and the UI says "N.A.". Don't add a `MockSource` branch
  to this path "so it's never empty" — that's the one thing it must not do.
- **`fetchSeries` is not `_fetchChart`.** Keep them separate; merging them re-entangles the
  prior-day-close rule with the interval.
- **Null closes are skipped, not filled.**
- **`HistoryTarget.forSymbol` returns null for an unknown symbol** rather than assuming the display
  symbol is a valid ticker. A mock mover whose symbol isn't in the config correctly gets no chart.
- **Rows are gated on `canServe`**, so the gold-ticker affordance never lies about what's reachable.
- **`copyWith(history:)` is intentionally not `?? this.history`.**
- `intl` exports its own `TextDirection` — `price_chart.dart` hides it so the painter keeps
  Flutter's.

---

## Testing

```bash
flutter test                        # includes an offline no-overflow test for PriceChart at 320 px
flutter test test/history_probe.dart  # live: prints points + change for every range, both providers
```

The offline chart test builds a `PriceHistory` by hand — that's test fixture data, not app mock
data; the app itself still has no path that fabricates a series.

## Where to extend
- **Reuse `HistoryTarget.index(config)`** to replace the details dialog's 14-point sparkline with a
  real, range-selectable index curve. The service already supports it; nothing is wired yet.
- **More windows** (`1Y`, `5Y`, `YTD`) — one line in `HistoryRange`.
- **Volume bars** — Yahoo already returns `volume` alongside `close` in the same payload.
- **Charts from the screener** — resolve a row to a target and open the same dialog.
