# Market details — the dialogs

Everything under `lib/market_details/`. Tapping a market anywhere on the home page — a **tile** or a
**screener row** — opens that market's details over the page. Two further surfaces open from inside
it: a stock's **price curve**, and the **add-a-stock** search.

Written **2026-08-06**, current as of the "My stocks" feature.

---

## The three surfaces

```
home page  (market tile · screener row)
  └── showMarketDetails()          market details dialog
        ├── showInstrumentChart()  one stock's price curve   [1D][1W][1M][3M][6M]
        └── showAddStock()         search this market's exchange
```

All three are `Dialog`s that close from an **`X` in the top-left** — the app-wide rule for a surface
that opens over the page. A dialog is also the one thing allowed to float (elevation); every other
surface is flat with a 1 px border.

---

## Files

| File | Role |
|---|---|
| `market_details_dialog.dart` | `showMarketDetails()` + the dialog: header → body → the sections |
| `cubit/market_details_cubit.dart` · `market_details_state.dart` | One market, its own 1 s tick |
| `cubit/my_stocks_cubit.dart` · `my_stocks_state.dart` | The user's added stocks for this market |
| `cubit/stock_search_cubit.dart` | The debounced search box |
| `cubit/instrument_chart_cubit.dart` | The selected chart window and its fetch |
| `widgets/take_block.dart` | The AI Take panel |
| `widgets/leaders_table.dart` | Leading stocks + the shared `DividendCell` |
| `widgets/my_stocks_table.dart` | The user's own stocks + remove |
| `widgets/movers_table.dart` | Top movers |
| `widgets/news_list.dart` | Headlines + sentiment |
| `widgets/add_stock_dialog.dart` | `showAddStock()` — search field + results |
| `widgets/instrument_chart_dialog.dart` | `showInstrumentChart()` — range pills + curve/N.A. |

---

## The market details dialog

`Dialog` → max **640 × 720**, header pinned, body scrolls.

### Header
`X` · flag · index label · `name · city` · price + change. The price uses `AppText.numHeadline`;
the change is a `ChangeText` (green/red, tabular).

### Body, in order
| # | Section | Shown when | Source |
|---|---|---|---|
| 1 | **Status strip** — `StatusPill` · clock · `Source · …` · currency | always | `MarketDetailsCubit` tick |
| 2 | **Sparkline** — 14-point index curve | always | `market.spark` |
| 3 | **AI Take** | `state.hasTake` | `TakeBlock` |
| 4 | **Leading stocks · {currency}** | `state.hasLeaders` | `LeadersTable` |
| 5 | **My stocks · {currency}** | always | `MyStocksTable` or an empty state |
| 6 | **Top movers · session** | always | `MoversTable` or an empty state |
| 7 | **Latest · news & sentiment** | always | `NewsList` or an empty state |
| 8 | Disclaimer | always | — |

Sections 5–7 always render *something*: a table when there's data, an `EmptyState` with the `_off`
glyph and a next step when there isn't. Section 5 sits **between** the curated leaders and the
session's movers deliberately — a user-added stock is neither a "leader" nor a "top mover", and
folding it into either list would make those headings lie.

### The tables

| Table | Columns |
|---|---|
| `LeadersTable` | Ticker · Company · Price · Chg · Div yield |
| `MyStocksTable` | Ticker · Company · Price · Chg · Div yield · *(remove)* |
| `MoversTable` | Ticker · Company · Chg |

My stocks deliberately mirrors the leaders' five columns — an added stock is not a lesser row, it
just wasn't curated. All three are `AppTable` (shrink-wrapped, horizontally scrollable, `AppColors.line`
rules — never zebra fills). Numeric columns carry tabular figures via `AppText.numCell`.

**Dividend yield** is TTM payout ÷ price. A genuine non-payer shows a muted **"—"**, never `0%`;
`DividendCell` (public in `leaders_table.dart`) is shared by both tables so they read identically.

---

## Tappable rows → the price curve

A ticker is **gold and tappable only when its curve can actually be fetched here**. `_chartTargets()`
in `market_details_dialog.dart` resolves the set once per build:

```dart
// saved stocks first — they carry the queryable id their search returned
for (final stock in mine.saved) {
  final t = HistoryTarget.fromSaved(m.config, stock);
  if (service.canServe(t)) out[stock.symbol] = t;
}
// then the curated rows, which resolve through markets.dart
for (final symbol in {...leaders, ...movers}) {
  final t = HistoryTarget.forSymbol(m.config, symbol);
  if (t != null && service.canServe(t)) out[symbol] = t;
}
```

Two independent gates, both required:
1. **The symbol resolves** — `HistoryTarget.forSymbol` returns `null` for anything not in that
   market's config rather than guessing a ticker; `fromSaved` uses the id captured at search time.
2. **The platform can reach the source** — `service.canServe(target)`. On Web with no proxy, Yahoo is
   unreachable, so those rows correctly go inert while crypto still works.

Anything failing either gate stays plain and un-tappable, so a tap never opens a view that can only
say "N.A.". Full write-up: [`../stock-curve-status/stocks-curve-status.md`](../stock-curve-status/stocks-curve-status.md).

---

## State — three cubits, one dialog

`showMarketDetails()` builds a `MultiBlocProvider` with `MarketDetailsCubit` + `MyStocksCubit`. Both
are created with the dialog and disposed with it, so **neither the clock nor the price fetches
outlive the view**.

### `MarketDetailsCubit`
Owns one market and a `Timer.periodic(1s)` that re-derives `isOpen` + `localClock`. This is the *only*
app ticker besides `MarketsListCubit`'s — **don't add a third**. `clockLabel` varies by market kind:
`24/7` (crypto, `always`), `Trades` (gold, `commodity`), else `Local time`.

`setMarket()` swaps in a fresher copy after a refresh without rebuilding the cubit.

### `MyStocksCubit`
Listens to `MyStocksStore.changes`, so adding a stock in the search dialog updates the section
without either side knowing about the other. On every change it re-prices the saved rows through
`MyStocksService.rows()`, guarded by a `_request` token so a slow earlier fetch can't overwrite a
newer one.

`saved` and `rows` are kept **separate on purpose**: `saved` is what the user chose and always
renders; `rows` is what a source could price *right now*. A saved stock with no row shows muted "—"s
rather than disappearing — losing a row the user explicitly added would read as the app forgetting it.

### `StockSearchCubit`
Debounced **350 ms**, minimum **2 characters**, with its own `_request` token. Both search sources are
free tiers; neither should be hit once per keystroke.

---

## The add-a-stock dialog

Opened from the **Add stock** pill in the My stocks section header — and *only* when
`MyStocksService.canSearch(market)` is true, so a platform that can't reach the source never offers a
box that could only come back empty.

Takes the already-built `MyStocksCubit` by `BlocProvider.value`, so the section behind it updates the
moment something is added; the dialog never owns the list. A result already in the list shows
**"Added"** instead of the Add pill.

Results are scoped to the market's own exchange. Full rules, including why Egypt needs a verified
ticker probe, are in `CLAUDE.md` → *My stocks* and
[`../todo/my-stocks-todo.md`](../todo/my-stocks-todo.md).

---

## Design rules this feature must keep

- Colours from `AppColors` only — no `Colors.*`, `Color(0x…)` or `.shade*`.
- Every spacing/radius/icon size is a token; every text style is a named `AppText` style.
- Icons are `TablerIcons.*`; empty states use the `_off` glyph and say what to do next.
- Numbers in a column carry tabular figures.
- A surface that opens over the page closes from an `X` in its **top-left**.
- **Not investment advice** — the disclaimers on the take, the news and the curve stay.

---

## Tests

`test/smoke_test.dart` (offline, deterministic — `DataPolicy(offline: true)`):
- the dialog opens from a tile and shows its section labels;
- My stocks starts empty and **hides** Add stock when search is offline;
- a store seeded with a `SavedStock` renders in `MyStocksTable`;
- **no overflow at 320–390 px** — the check that catches most layout regressions.

`test/search_probe.dart` and `test/history_probe.dart` are live probes, excluded from `flutter test`
by filename (no `_test` suffix). Run them explicitly.
