# 04 · UI & state

## State (cubit)
Three cubits, provided at the top of the tree in `main.dart`:

- **`DashboardCubit`** — `load()` / `refresh()`. States: `DashboardLoading`, `DashboardLoaded`
  (carries a `refreshing` flag for the silent refresh), `DashboardError`. It calls
  `DashboardRepository.load()`.
- **`ClockCubit`** — emits `DateTime.now()` every second. Tiles and the topbar rebuild on it and
  recompute open-closed + local clocks via `MarketHours`, so the UI ticks without re-fetching.
- **`SelectionCubit`** — the selected market id; drives the detail panel. Defaults to the first
  market once data loads.

## Widgets
| Widget | Role |
|--------|------|
| `dashboard_page.dart` | Layout host: topbar · brief · tiles · (detail | watchlist) · footer. Switches on `DashboardState`. |
| `topbar.dart` | Brand, refresh button (spins while refreshing), "N/7 open" badge, live UTC clock. Stacks on narrow widths. |
| `brief_card.dart` | The gold AI Morning Brief card. |
| `market_grid.dart` + `market_tile.dart` | Responsive tile grid; each tile has sparkline, pulsing open dot, ticking local clock, watch chips. |
| `detail_panel.dart` | Header + chart + AI Take + leaders table + movers table + news list. |
| `sparkline.dart` | `CustomPainter` line + area fill, colored by change sign. |
| `common.dart` | Shared bits: section label, colored change text, status pill (+pulsing dot), sentiment icon, chip. |
| `data_table.dart` | Thin wrapper over `material_table_view` for the read-only tables. |
| `movers_table.dart` / `leaders_table.dart` / `watchlist_table.dart` | The three tables. |

## Tables (`material_table_view`)
The wrapper in `data_table.dart` configures a shrink-wrapped, vertically non-scrolling table (it
composes inside the page's scroll view) that still **scrolls horizontally** on narrow screens — the
"overflow-x" behaviour from the original CSS. First column left-aligned, numeric columns right.
Dividend cells show the yield % (with a tooltip) or a muted "—" for non-payers.

## Responsive layout
- **Wide (desktop/web):** tiles grid, then detail (flex 3) and watchlist (flex 2) side by side.
- **Narrow (mobile):** single column — tiles, then detail, then watchlist stacked. The topbar and
  the AI Take header collapse/flex so nothing overflows (there are smoke tests asserting no overflow
  at 320–390 px).

## Theming
`AppTheme.dark` + `AppColors` in `theme.dart` reproduce the original palette exactly: ground
`#0E1420`, surface `#1B2333`, line `#2C3850`, ink `#E7ECF5/#9AA6BC/#6C7789`, accent `#E3A93C`, gain
`#34C08A`, loss `#F26D6D`. Numbers use a monospace fallback stack with tabular figures. Icons come
from `flutter_tabler_icons` (e.g. trending-up/down/minus for sentiment, sparkles for AI, eye for the
brand, refresh, clock).

## Formatting & sentiment
`format.dart` holds the `Sentiment` enum (→ icon + color + label) and `Fmt` helpers
(`price`, `signedPct`, `compactPct`, `gainLoss`) ported from the original `format.js`.
