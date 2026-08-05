---
name: pos-x-design
description: The visual design system for the POS_X app UI — brand colours, dark/light behaviour, type, spacing, icons, surfaces, and the layout patterns every screen and widget must follow. Use when building or editing ANY Flutter screen, widget, dialog or cubit-driven view under lib/. Covers what to use instead of Colors.red, when green is allowed, the Tabler icon glossary, and the card/panel recipes taken from the Sell, Buy and Reports screens. (For printed HTML documents, use printable-document-design instead.)
---

# POS_X app design

This is a pharmacy POS operated behind a counter, often on a bright screen, all
day. It must be **fast to scan, legible in both themes, and consistent enough
that a cashier never has to re-learn a screen.**

Two colours carry the brand, and the split is strict:

| | Colour | Means |
|---|---|---|
| **Navy** `#1B3A5C` → `colorScheme.primary` | chrome | rail, app bar, headers, links, filters, selection, ordinary actions |
| **Green** `#256138` → `colorScheme.tertiary` | confirm | complete a sale, receive stock, settle an invoice, post a payment |

Green is scarce on purpose. When a cashier sees green, money moved.

Everything else — every surface, border and grey — is generated from the navy
seed by `ColorScheme.fromSeed` in
`lib/themes/darklightmood.dart`. Nobody hand-picks a grey.

---

## 1. The hard rules

Not preferences. Each one maps to a defect that shipped in this repo.

### 1.1 Never write a literal colour in a widget

```dart
// ❌ NEVER
color: Colors.red
color: Colors.orange.shade50
color: Colors.grey[600]
color: const Color(0xFF2E7D32)
style: TextStyle(color: Colors.white)

// ✅ ALWAYS
color: context.scheme.primary
color: context.appColors.danger
color: context.appColors.tint(context.appColors.warning)
```

**Why:** `Colors.*` does not change with brightness. `Colors.orange.shade50` is
a near-white background — in dark mode it becomes a glowing white slab with
white text on it. This is the single biggest reason dark mode could not be
switched on for so long. There were **1015** such usages when this system was
written; every one is a dark-mode bug waiting to be seen.

Both helpers come from `lib/themes/app_semantic_colors.dart`:

```dart
import '../../themes/app_semantic_colors.dart';

context.scheme      // ColorScheme  — brand + surfaces
context.appColors   // semantic     — success/warning/danger/info/profit/loss
```

### 1.2 Green means a transaction completed. Nothing else.

```dart
// ✅ the ONE green button on the screen
FilledButton(
  style: FilledButton.styleFrom(
    backgroundColor: context.scheme.tertiary,
    foregroundColor: context.scheme.onTertiary,
  ),
  onPressed: _confirmPayment,
  child: const Text('Confirm payment'),
)

// ✅ every other action — navy, the default
FilledButton(onPressed: _addLine, child: const Text('Add item'))
```

Not green: "Save draft", "Search", "Export", "Apply filter", "Add row",
"Next". Those are navy. A screen with two green buttons has one too many.

`context.appColors.success` is a **status** colour — a synced badge, an
in-stock pill. It is not a button. Do not use it to paint an action.

### 1.3 Flat surfaces with a border. Never a gradient or a glow.

```dart
// ❌ NEVER — the Sell/Buy screens are full of this and it is being removed
decoration: BoxDecoration(
  gradient: LinearGradient(colors: [scheme.surface, scheme.surface.withOpacity(0.9)]),
  boxShadow: [BoxShadow(color: scheme.primary.withOpacity(0.3), blurRadius: 12)],
)

// ✅ ALWAYS
decoration: BoxDecoration(
  color: context.scheme.surface,
  borderRadius: AppRadius.card,
  border: Border.all(color: context.scheme.outlineVariant),
)
```

**Why:** a coloured drop-shadow reads as a smudge of dirt on a dark surface,
and a two-stop gradient between a colour and 0.9 of itself is invisible work —
it costs a repaint and shows nothing. Separation is the border's job.

Shadows are allowed in exactly one place: something that genuinely floats above
the page — a dialog, a menu, a dragged item. Never a card, never a button,
never a search field.

### 1.4 Numbers come from tokens

From `lib/themes/app_tokens.dart`:

```dart
AppSpacing.xs sm md lg xl xxl huge      // 4 8 12 16 20 24 32
AppRadius.xs sm chip md lg xl           // 6 8 11 12 16 24
AppIconSize.inline dense standard chip header empty   // 16 18 20 22 28 44
AppMotion.fast panel curve              // 180ms 300ms easeInOut
```

These are not new numbers — they are the values the codebase already converged
on by itself. If a value isn't in a token class, use the nearest one that is.
No 10, 14, 18, 25.

### 1.5 One icon family: Tabler

```dart
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

Icon(TablerIcons.cash_register, size: AppIconSize.chip)
```

**Why:** the app currently mixes `Icons.dashboard_outlined` with
`Icons.dashboard_rounded` with `Icons.point_of_sale_rounded` — outlined and
filled in the same nav rail. That mixed-weight look accounts for more of "this
app feels inconsistent" than the colours ever did. Tabler is one stroke weight,
always.

See **`references/icons.md`** before picking any icon — it has the domain
glossary, so "sale" is the same glyph on every screen forever.

---

## 2. Colour map

### Surfaces — three levels, and they invert between themes

| Level | Token | Use |
|---|---|---|
| Ground | *theme default* — don't set it | The scaffold. Already correct; do not pass `backgroundColor:` to `Scaffold` |
| Card | `scheme.surface` | Card, panel, dialog, rail, app bar. Always with a 1px `outlineVariant` border |
| Nested | `scheme.surfaceContainerHighest` | A tag, a table header row, a well *inside* a card |

Do not reach for `surfaceContainerLowest` / `surfaceContainerLow` directly.
Their tonal order flips between light and dark, so a hand-picked one is right
in one mode and wrong in the other. The theme already resolves this.

### Text

| Token | Use |
|---|---|
| `scheme.onSurface` | Primary text. Usually just omit `color:` and let the theme apply it |
| `scheme.onSurfaceVariant` | Secondary text — hints, captions, column headers, inactive icons |
| `scheme.primary` | A link, an active tab, a selected label |
| `scheme.error` | A validation message on a field |

Never `Colors.black54` / `Colors.white70`. That is what `onSurfaceVariant` is.

### Lines

| Token | Use |
|---|---|
| `scheme.outlineVariant` | Card border, divider, table rule, field border at rest |
| `scheme.outline` | Outlined button border, focused field |

### Semantic — `context.appColors`

| Field | Means | In this app |
|---|---|---|
| `success` | good, done | synced, in stock, paid, active promo |
| `warning` | needs attention | low stock, expiring batch, unsynced, partly paid |
| `danger` | wrong or blocked | out of stock, expired, failed sync, overdue |
| `info` | neutral notice | a hint, a count, an explanation |
| `profit` | positive money | margin, gain, credit in our favour |
| `loss` | negative money | negative margin, write-off, shrinkage |

`profit`/`loss` are deliberately separate from `success`/`danger`. **A loss is
not an error.** Styling a normal negative margin with the error colour makes
every honest report look broken.

Do not invent more. Out-of-stock is `danger`; expiring is `warning`; expired is
`danger`. Reuse, don't multiply.

**Tinted backgrounds** use the standard 12% wash, never a `.shade50`:

```dart
final c = context.appColors.warning;
Container(
  decoration: BoxDecoration(
    color: context.appColors.tint(c),   // c at 12%
    borderRadius: BorderRadius.circular(AppRadius.xs),
  ),
  child: Text('Expires in 12 days', style: TextStyle(color: c)),
)
```

### Category accents

The reports catalog (`lib/reports/data/reports_catalog.dart`) assigns each
report category a fixed accent. Those are **content colours, not brand
colours** — they are correct as they are, they must not be replaced by navy,
and they only ever appear behind an icon at 12%, never as a fill or a button.

**A new set of categories does not automatically get accents.** Ask what the
colour would be saying:

| The categories are… | Colour |
|---|---|
| kinds of **content**, and the colour helps you find one — a sales report vs a stock report | an accent per category, as Reports does |
| **places to go**, all equally yours — the Settings panels | `primary` for every one |

Settings has eight categories and no accents, deliberately: Store and Sync are
not two *kinds* of thing the way Sales and Inventory are, so a colour per tile
would be decoration pretending to be information. Eight identical navy tiles
scan fine — the selected one is a solid fill, the rest a 12% wash.

That also keeps the one colour that *does* carry meaning legible: the amber dot
on the Sync tile when rows are waiting to upload (see §5).

---

## 3. Type

Sizes and weights come from the theme. **Never set `fontSize:` freehand.**

| Style | Size / weight | Use |
|---|---|---|
| `headlineMedium` | 20 / w600 | Screen title |
| `titleLarge` | 18 / w600 | Panel title, dialog title |
| `titleMedium` | 16 / w500 | Section heading |
| `titleSmall` | 14 / w600 | Card title, item name |
| `bodyLarge` | 16 | Body, form values |
| `bodyMedium` | 14 | Default body, table cell |
| `bodySmall` | 12 | Hint, caption, secondary line |
| `labelLarge` | 14 / w600 | Button, table column header |
| `labelSmall` | 11 / w500 | Tag, badge, micro-label |

```dart
Text(item.name, style: Theme.of(context).textTheme.titleSmall)

// A weight bump is fine; a size override is not.
style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)
```

**Every number a person compares gets tabular figures.** Prices, quantities,
totals, dates in a column — without this, digits jitter between rows and the
column stops being scannable.

```dart
style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])
```

No font family is set anywhere. The theme deliberately leaves it unset so the
platform face applies (Segoe UI on Windows, SF Pro on macOS) — both render
Arabic correctly, which matters for the Egypt / KSA / UAE markets. Do not add
`fontFamily:` to a widget.

---

## 4. Icons

**Read `references/icons.md` for the glossary.** The rules:

### Size — pick by context, never freehand

| Token | px | Where |
|---|---|---|
| `inline` | 16 | Inside a table cell, tag or dense row |
| `dense` | 18 | Text field prefix, tab label, dense button |
| `standard` | 20 | Button, list tile leading, app bar action |
| `chip` | 22 | Tinted icon chip, nav rail destination |
| `header` | 28 | Dialog header |
| `empty` | 44 | Empty state — the only decorative size |

### Colour

Default is `onSurfaceVariant` (the theme already applies it — usually pass no
colour at all). `primary` only for active/selected. Semantic colour only when
the icon *is* the status.

### The tinted icon chip

The signature POS_X component, from `report_card.dart`. Use it for the leading
mark on a card, an app bar, or a rail brand:

```dart
Container(
  padding: const EdgeInsets.all(9),
  decoration: BoxDecoration(
    color: accent.withValues(alpha: 0.12),
    borderRadius: AppRadius.iconChip,      // 11
  ),
  child: Icon(icon, color: accent, size: AppIconSize.chip),
)
```

### Empty states use the `_off` variant of the missing thing

Already the convention in this repo, and it reads beautifully — keep it.

| Nothing to show | Icon |
|---|---|
| No items / no stock | `TablerIcons.package_off` |
| No invoices | `TablerIcons.receipt_off` |
| No chart data | `TablerIcons.chart_bar_off` |
| No branches | `TablerIcons.building_off` |
| Empty cart | `TablerIcons.shopping_cart_off` |

### Never build `IconData` dynamically

```dart
// ❌ this defeats font tree-shaking and ships all 5,717 glyphs
IconData(codePoint, fontFamily: 'TablerIcons')

// ✅
TablerIcons.receipt
```

Tabler is one generated Dart file of `const IconData`, so `const` widget trees
work and the font tree-shakes — but only if every reference is static.

---

## 5. Layout

### The screen skeleton

Rail → app bar → ground → cards. Page padding is `AppSpacing.xxl` (24),
gap between cards `AppSpacing.lg` (16).

### Every screen closes from the top-left

**Any screen, dialog or panel that opens *over* the shell gets an `X` in its
top-left corner** — the first thing in its header row, before the title.

```dart
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

Row(
  children: [
    IconButton(
      tooltip: 'Close',
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(TablerIcons.x, size: AppIconSize.standard),
    ),
    const SizedBox(width: AppSpacing.sm),
    Expanded(
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    ),
    // actions go here, on the right
  ],
)
```

With an `AppBar`, it is the `leading:` slot — not an action.

**One place, always the same place.** A cashier closes a screen dozens of times
a shift and should never have to look for the way out. Some screens in this repo
put the close on the right, some rely on the shell, some have no exit at all —
new work goes top-left, and convert the header you touch.

Two things it is not:

- **Not on a rail tab.** Dashboard, Reports, Settings and the rest are the app's
  home surfaces — there is nothing to close, and an `X` there implies there is.
  This rule is for what the shell *pushes*: Sell, Buy, Trade, dialogs, drawers,
  full-window detail screens.
- **Not a save, and never green.** It is a plain `IconButton` in the default
  `onSurfaceVariant`. If closing would throw away typed work, `maybePop` through
  a confirm — do not turn the `X` into a commit button, and do not disable it.

### The split-panel pattern (Sell, Buy)

These two screens have the right *layout* — keep it, and reuse it for any new
transactional screen:

- Work area on the left, context panel on the right.
- The right panel collapses; a 24px circular handle sits on its edge.
- `AnimatedContainer` / `AnimatedPositioned` at `AppMotion.panel` (300ms)
  with `AppMotion.curve`.
- A slide-in panel over content gets a `Colors.black.withValues(alpha: 0.3)`
  scrim that dismisses on tap.

Their *decoration* is the old generation — gradients and glow shadows. When you
touch one of those files, convert the container you touched to §1.3. Do not
rewrite the layout.

### The card-grid pattern (Reports)

For any dashboard or catalog of things to open: a search field, a horizontal
row of filter tiles, then `Wrap`ped cards at a fixed width (300) with
`spacing: 14, runSpacing: 14`. `reports_dashboard.dart` is the reference
implementation — copy its structure.

### The tile bar

The same horizontal row of icon-and-label tiles does two different jobs, and
the difference decides how it behaves:

| | Reports | Settings |
|---|---|---|
| Role | **filter** — narrows the grid below | **navigation** — swaps the panel below |
| Selecting nothing | valid (the `All` tile) | impossible; one is always open |
| Colour | an accent per category | `primary` throughout (§2) |
| Reference | `reports_dashboard.dart` | `lib/settings/widgets/settings_tile_bar.dart` |

Shared shape either way: ~96 px wide, ~78–84 px tall, `AppRadius.lg` corners,
icon over a one-line label, `AppMotion.fast` on selection. Selected is a solid
fill with `onPrimary` content; unselected is the same colour at 12%.

Two rules that are not optional:

- **It scrolls horizontally.** Eight tiles overflow a narrow window, and a row
  that merely clips hides the last category with nothing on screen to say it
  exists.
- **Generate it from the enum**, never from a second hand-written list beside
  it. That duplication is what left four finished modules with no way into the
  app when the nav rail kept its own destination list. It follows that **a tile
  index is not an enum index** whenever any tile can be filtered out — map
  through the visible list.

### Badges on a nav item

A rail destination or a tile can carry one mark. Keep it to one — a tile with
two badges has nothing left to emphasise.

| Mark | Means | Treatment |
|---|---|---|
| **Dot** | there is something here to deal with | 8 px circle, top-left, `appColors.*` by severity |
| **Lock** | you may look, not change | `TablerIcons.lock` at `AppIconSize.inline`, top-right, plus `Opacity(0.62)` on the tile |

**Pick the dot's colour by what the count means, not by how big it is.** Rows
waiting to sync are amber (`warning`) because an offline-first POS holding
unsent rows is working exactly as designed — red would be a lie, and a status
users learn to ignore is worse than no status. Reserve `danger` for something a
person must actually fix.

A badge is a **pointer, not the answer**: the dot says "look in Sync", the panel
says how many and what. Never put a number in the tile itself — it competes
with the label and is unreadable at that size.

A locked tile stays **visible**. Hiding it is one line less code and teaches
staff the setting does not exist; the panel behind the lock should name who can
change it and what the reader *can* still do.

### Tables

Use `material_table_view` (project convention). Column headers are
`labelLarge` on `surfaceContainerHighest`. Numeric columns are right-aligned
with tabular figures. Row separation is `outlineVariant`, never a zebra fill.

---

## 6. The logo

The mark is a two-tone green fan, and **each tone fails contrast on the ground
that matches it** — dark petals measure 2.4:1 on a dark surface, light petals
2.7:1 on white. So it is never drawn raw.

Always go through `AppLogo` (`lib/widgets/app_logo.dart`):

| Constructor | Use |
|---|---|
| `AppLogo(size: 48+)` | Login, splash, about. Full colour on its brand plate |
| `AppLogo.mono(size:, color:)` | Rail, app bar, drawer — any ground, you pick the tone |
| `AppLogo.mark(size: 16–32)` | Small chrome. 5-petal reduction; the full fan turns to mush below ~32px |
| `AppLogoLockup(extended:)` | Mark + wordmark for a rail header |

Never `SvgPicture.asset('assets/logo/…')` directly. Never recolour the plated
variant, never stretch it, never put the full-colour mark on a bare surface.

---

## 7. Before you call a screen done

- [ ] No `Colors.*`, no `Color(0x…)`, no `.shade*` anywhere in the file.
- [ ] Run it in **dark mode**. Every surface, border and label still legible.
- [ ] At most one green button, and it completes a transaction.
- [ ] If it opens over the shell, there is an `X` in the top-left that closes it.
- [ ] No gradient. No coloured shadow.
- [ ] Every spacing, radius and icon size is a token.
- [ ] Every icon is `TablerIcons.*`, and matches `references/icons.md`.
- [ ] Numbers in columns have `FontFeature.tabularFigures()`.
- [ ] Empty state uses the `_off` icon and says what to do next.
- [ ] `flutter analyze` — no new warnings.

---

## 8. Retrofitting old screens

Do not mass-rewrite. Fix what you touch, in this order when given a choice:

1. **Sell + Buy** — highest traffic, most gradients.
2. **Finance** — biggest surface area of hardcoded status colours.
3. **Dashboard / inventory** — older `GetX`-era markup.
4. Everything else, opportunistically.

`lib/reports/` and `lib/mainScreen/` are already close to this system. When
unsure what a component should look like, open `reports/widgets/report_card.dart`
or `mainScreen/widgets/main2_app_bar.dart` and follow it.

---

## 9. Printed pages are governed elsewhere — three rulings to know

This skill covers **screens**. The moment the design is going to paper —
any `*_html.dart` builder, anything reaching `HtmlPrintService`,
`printToBrowser` or `Printing.convertHtml` — the authority is
**`printable-document-design`**, and you must load it.

Three rulings made on the Trade report (2026-08-04) live there in full. They are
listed here only because this is the skill people reach for first:

- **The print dialog's Orientation control belongs to the operator.** Never put
  `size:` in `@page` — naming one (especially `A4 landscape`) greys the control
  out, and someone looking at a wrong preview has no way to fix it. A wide table
  steps its own type down (`.dense`) instead. **`printable-document-design`
  §1.4.**
- **A compact masthead for internal pages.** One band, and the split is by
  subject, not by importance: **left is the document** — QR, document type, its
  reference, the party, the date, read top-down as one identity — and **right is
  the shop and its headline figures**. One rule under both, then the table.
  The full masthead costs about a third of the first page on address and tax
  numbers, which on a one-page report is more room than the numbers get. It
  prints **no tax registration number**, so it is not for anything a tax
  authority reads. **§3.1.**
- **Headline figures go in that header, not a band across the page.** The
  print-side `.kpis` band is the paper equivalent of a KPI row, and on a
  one-page invoice it took a quarter of the sheet and pushed the first line of
  the table under the fold. Two to four figures beside the shop name. On
  **screen** the equivalent stays a `TradeTotalsStrip` under the table, because
  a screen scrolls and paper does not — the two media get the same numbers in
  different places on purpose. **§3.1.**
- **A document with its own number carries it as a QR**, generated in Dart as
  inline SVG (`lib/printer/qr_svg.dart`) — never an `<img>` pointing at a QR
  service, which prints as a broken box offline. No reference means no QR. **§3.2.**

The one screen-side consequence: on a screen, a header that needs explaining
gets a `Tooltip` and a small `TablerIcons.help_circle`; on paper the same wording
prints as a `.col-hint` gloss under the column name. **One wording, defined
once** — `lib/reports/trade_reports/widgets/trade_common.dart` is the pattern.
Two copies drift, and the paper copy is the one nobody re-reads.
