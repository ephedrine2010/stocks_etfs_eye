# 04 · UI & state

## State (cubit)
Four cubits. Only `HomeCubit` is provided app-wide (in `main.dart`); the other three are scoped to
the feature that owns them.

- **`HomeCubit`** (`home/cubit/`) — `load()` / `refresh()`. States: `HomeLoading`, `HomeLoaded`
  (carries a `refreshing` flag for the silent refresh), `HomeError`. The **only** thing that calls
  `DashboardRepository.load()`.
- **`ScreenAllMarketsCubit`** (`screen_all_markets/cubit/`) — holds the markets plus the screener's
  view state (sort key + direction, gain/loss filter, market filter, search text) and emits the
  already-flattened, filtered, sorted `rows`. The widget renders; it does not compute.
- **`MarketsListCubit`** (`markets_list/cubit/`) — holds the markets, the All/Open/Closed filter,
  and a **1-second timer**. Each tick it derives every market's `isOpen` + `localClock` through
  `MarketHours` and emits them on the state, so a tile never computes anything time-dependent.
  This is the page's only ticker: the top bar's UTC clock and "N open" badge read the same state.
- **`MarketDetailsCubit`** (`market_details/cubit/`) — one market and its own 1-second tick, alive
  only while the dialog is open.

**How the sections get their data:** `home_page.dart` provides the two section cubits, seeds them
from whatever `HomeCubit` already holds, and pushes each new load into them via a `BlocListener`
calling `setMarkets`. Sections never fetch.

## Screens & widgets
| File | Role |
|------|------|
| `home/home_page.dart` | The only page. Switches on `HomeState`; lays out top bar · screener card · markets list · footer. Owns the two section cubits and routes a market tap to the dialog. |
| `home/widgets/home_topbar.dart` | Brand, refresh button (spins while refreshing), "N/7 open" badge, live UTC clock. Stacks under the brand below 520 px. |
| `screen_all_markets/screen_all_markets_view.dart` | Section header + count, filter pills + search, the sortable table, the disclaimer. A row tap opens that row's market. |
| `markets_list/markets_list_view.dart` | Section header + open count, the All/Open/Closed pills, and the responsive tile grid (`auto-fit, minmax(172px, 1fr)` reproduced with `LayoutBuilder` + `Wrap`). |
| `markets_list/widgets/market_tile.dart` | Flag, name/city, open-closed pill (pulsing dot when open), index name, price, daily %, sparkline, ticking local clock, watch chips. Hover lifts the border; a chevron marks that it opens. |
| `market_details/market_details_dialog.dart` | `showMarketDetails(context, market)`. Header (close · flag · index · price/chg) then a scrolling body: status strip, chart, AI Take, leaders, movers, news. |
| `market_details/widgets/` | `take_block` · `leaders_table` · `movers_table` · `news_list`. |
| `shared/widgets/surfaces.dart` | `AppCard` (the one card shape), `IconChip` (tinted glyph plate), `EmptyState`. |
| `shared/widgets/controls.dart` | `AppPill` (filter pill), `PillDivider`, `AppSearchField`. |
| `shared/widgets/app_table.dart` | Thin wrapper over `material_table_view` for the read-only tables. |
| `shared/widgets/common.dart` | `SectionLabel`, `ChangeText`, `InfoChip`, `StatusPill` (+ pulsing dot), `SentimentIcon`. |
| `shared/widgets/sparkline.dart` | `CustomPainter` line + area fill, coloured by the change sign. |

## Opening a market
Both entry points converge on one dialog, and neither feature imports the other:

```
market tile  ──onMarketTap(market)──┐
                                    ├──> home_page ──> showMarketDetails(context, market)
screener row ──onMarketTap(id)──────┘        (resolves the id against the loaded markets)
```

## Tables (`material_table_view`)
The wrapper in `app_table.dart` configures a shrink-wrapped, vertically non-scrolling table (it
composes inside the page's scroll view) that still **scrolls horizontally** on narrow screens — the
"overflow-x" behaviour from the original CSS. First column left-aligned, numeric columns right, row
separation a 1 px rule (never a zebra fill), and an optional `onRowTap`. Dividend cells show the
yield % (with a tooltip) or a muted "—" for non-payers.

## Responsive layout
- **Wide (desktop/web):** content is centred at max 1200 px; the tile grid fits as many 172 px
  columns as there is room for.
- **Narrow (mobile):** one tile column; the top bar stacks under the brand and shortens its badge;
  the screener's filter row wraps; the table scrolls horizontally.
- Smoke tests assert **no overflow at 320 and 390 px**, including with the dialog open.

## Design system
`.claude/skills/eph-design` is the authority, mapped onto this app's palette. In practice:

- **Colour** comes only from `AppColors` — ground `#0E1420`, surface `#1B2333`, nested `#232D40`,
  line `#2C3850`, ink `#E7ECF5/#9AA6BC/#6C7789`, accent `#E3A93C`, gain `#34C08A`, loss `#F26D6D`.
  No `Colors.*`, no `Color(0x…)`, no `.shade*` in a widget. `AppColors.tint(c)` is the standard 12 %
  wash behind a coloured icon or pill.
- **Numbers** come from tokens: `AppSpacing` (4/8/12/16/20/24/32), `AppRadius` (6/8/11/12/16/24 +
  `pill`), `AppIconSize` (16/18/20/22/28/44), `AppMotion` (180 ms / 300 ms / easeInOut).
- **Type** comes from the named `AppText` styles (`headline`, `title`, `titleSmall`, `body`,
  `bodyMuted`, `caption`, `micro`, `label`, `columnHeader`, `mono`, `numCell`, `numHeadline`) — not
  a freehand `fontSize:`. Every number a person compares down a column carries tabular figures.
- **Surfaces** are flat with a 1 px border. No gradients, no coloured shadows; the dialog is the one
  thing allowed to float.
- **Icons** are all `flutter_tabler_icons`, one stroke weight. Empty states use the `_off` variant of
  the missing thing (`filter_off`, `chart_bar_off`, `news_off`, `building_off`, `clock_off`) and say
  what to do next.
- **Anything that opens over the page closes from an `X` in its top-left** — one place, always.

## Language
The UI is **English only**. The EN/ع toggle, `app/i18n.dart`, `LocaleCubit` and the Arabic market
names were removed on 2026-08-05; see `../resources/04-bilingual-i18n.md` for the superseded design.

## Formatting & sentiment
`format.dart` holds the `Sentiment` enum (→ icon + colour + label) and `Fmt` helpers
(`price`, `signedPct`, `compactPct`, `gainLoss`) ported from the original `format.js`.
