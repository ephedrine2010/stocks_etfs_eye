# 03 · Cross-market screener

A new dashboard card that flattens **every market's movers + leaders into one sortable, filterable
table** — rank instruments across all 7 markets at once. It reuses data already fetched per market,
so it makes **zero extra API calls** and works for every market, MENA included.

## Files touched
| File | Change |
|------|--------|
| `lib/ui/widgets/screener_table.dart` | **New** — the entire screener widget |
| `lib/ui/dashboard_page.dart` | One import + one line: a `ScreenerTable` card below the market grid |

## What it does
- **Sortable columns** — tap any header (Mkt / Ticker / Company / Price / Chg / Div). The active
  column shows a ▲/▼ chevron. Default sort: **Chg, descending** (biggest movers first). Text columns
  default A→Z; numeric columns default high→low; re-tapping toggles direction.
- **Gain/loss filter** — `All · Gainers · Losers` pills (Gainers tinted green, Losers red).
- **Per-market filter** — `🌐 All` plus a flag pill per market.
- **Search** — matches ticker or company name (case-insensitive).
- **Live count** — "N instruments" reflects the active filters.

## Data shaping (in-widget)
- `_allRows()` flattens `markets` into `_Row`s and **de-dupes by `marketId:symbol`**. Leaders are
  added first; movers `putIfAbsent`, so a **leader wins on collision** (it carries `price` and
  `dividend.yield`; a bare mover may not).
- `_visibleRows()` applies market filter → gain/loss filter → search, then `sort(_compare)`.
- **Nulls sort last**, independent of direction (`_nullableCmp`), and a missing `price`/`divYield`
  renders as a muted **"—"**, never a fake `0` (consistent with the dividend gotcha elsewhere).

## Why local state, not a cubit
Sort/filter/search/market are **ephemeral view-only state** local to this one widget, so it's a
`StatefulWidget` with `setState`. That's Flutter's built-in local state, not a competing
state-management library — it doesn't violate the "cubit via `flutter_bloc`, no other lib" rule.
Cubits remain for **shared/domain** state: `SelectionCubit` is a cubit precisely because the selected
market is read by multiple widgets (grid + detail panel).

## Reuse (no new primitives)
Built entirely on existing pieces: `AppTable` (the `material_table_view` wrapper), `ChangeText`,
`SectionLabel`, `Fmt`, and the `AppColors` palette. Sortable headers were added **without touching**
`data_table.dart` — the header cell builder simply returns a tappable `GestureDetector`
(+ `MouseRegion` for a desktop pointer cursor).

## Layout gotcha (keep in mind)
The header row originally used `SectionLabel + Spacer() + Text(count)`. A `Spacer` cannot prevent an
overflow when the two fixed children exceed the width — and under Flutter's **fixed-width test font**
the uppercase label is much wider than in the real proportional font, so it overflowed at 390px and
tripped the no-overflow smoke test. **Fix:** wrap the label in `Expanded` (it flexes/wraps) and drop
the `Spacer`. Lesson: any header row pairing a long label with a trailing value should let the label
flex, and always re-run `flutter test` (the 320–390px overflow assertion catches exactly this).

The table itself scrolls **horizontally** on narrow screens (inherited from `AppTable`), so the six
columns never force the page to overflow sideways.

## Placement
Rendered as a `_Card` in `dashboard_page.dart`, directly **below "Markets — live status"** and above
the detail/watchlist row.

## Verification
`flutter analyze` clean; both smoke tests pass, including the **no-overflow @ 390px** check (after the
header fix above).

## Possible extensions
- A "live" badge once movers carry a source (ties into [02](02-finnhub-adapter.md)).
- More sort dimensions (e.g. absolute % move), CSV export, or click-through to the market detail.
