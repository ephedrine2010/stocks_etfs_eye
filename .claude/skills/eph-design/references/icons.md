# POS_X icon glossary

One concept, one glyph, everywhere. Look the concept up here **before**
inventing an icon — a report that calls a sale `cash_register` and a dashboard
that calls it `shopping_cart` teaches the cashier that they are two things.

Every name below was verified against `flutter_tabler_icons: ^1.43.0`
(5,717 icons). Names are **snake_case** and resolve to plain `const IconData`:

```dart
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
Icon(TablerIcons.cash_register, size: AppIconSize.chip)
```

---

## Navigation — the rail and the main areas

| Concept | Icon |
|---|---|
| Dashboard / home | `layout_grid` |
| Sell / POS | `cash_register` |
| Buy / purchasing | `shopping_cart` |
| Trade / wholesale | `businessplan` |
<!-- `businessplan` was listed under Money as "credit sale / receivable" until
     2026-07-31, but every live usage was Trade — the reports catalog, the trade
     reports home, and the dashboard's Trade button. The code won; receivable
     moved to `moneybag`, which nothing was using. -->

| Inventory / warehouse | `building_warehouse` |
| Stock levels | `stack_2` |
| Reports | `presentation_analytics` |
| Finance | `building_bank` |
| Online / delivery orders | `truck_delivery` |
| Promotions | `discount` |
| Customers / partners | `users` |
| Insurance | `shield_half` |
| Printers | `printer` |
| Settings | `settings` |
| Users / staff | `id_badge` |
| Branches | `building_store` |
| Log out | `logout` |

---

## Documents

| Concept | Icon |
|---|---|
| Sale invoice / receipt | `receipt` |
| Purchase invoice / supplier bill | `file_invoice` |
| Sale return (credit note) | `receipt_refund` |
| Supplier return | `truck_return` |
| Quotation / draft | `notes` |
| Statement | `clipboard_list` |
| Journal entry | `book` |
| Export to file | `file_export` |
| Import a file | `file_upload` |
| Spreadsheet / CSV | `file_spreadsheet` |

---

## Stock movements

These map one-to-one onto `stock_movement_history.movement_type` — use the
matching glyph so the ledger and the UI agree.

| `movement_type` | Direction | Icon |
|---|---|---|
| `purchase` | in | `package_import` |
| `sale` | out | `package_export` |
| `sale_return` | in | `receipt_refund` |
| `supplier_return` | out | `truck_return` |
| `transfer_in` | in | `transfer_in` |
| `transfer_out` | out | `transfer_out` |
| `adjustment_in` / `adjustment_out` | either | `adjustments` |
| damage | out | `alert_octagon` |
| expiry write-off | out | `calendar_x` |

---

## Items and the catalog

| Concept | Icon |
|---|---|
| Item / SKU (generic) | `package` |
| Barcode | `barcode` |
| Medicine / tablet | `pill` |
| Prescription item | `prescription` |
| Injectable / vaccine | `vaccine` |
| OTC / general health | `medical_cross` |
| First aid / consumables | `first_aid_kit` |
| Batch / expiry | `calendar_due` |
| Category | `category` |
| Brand / manufacturer | `building_factory_2` |
| Supplier | `truck` |
| Item image | `photo_up` |

---

## Money and finance

| Concept | Icon |
|---|---|
| Cash | `cash` |
| Card payment | `credit_card` |
| Bank / GL account | `building_bank` |
| Wallet / till | `wallet` |
| Credit sale / receivable | `moneybag` |
| Customer overdue | `user_exclamation` |
| Payment received | `coins` |
| Profit / margin | `report_money` |
| VAT / discount rate | `percentage` |
| Trial balance / balance sheet | `scale` |
| Totals | `sum` |
| Price lookup | `zoom_money` |
| Cost | `coin` |

---

## Status

Pair each with the matching `context.appColors` field — the colour carries the
severity, the glyph carries the meaning.

| State | Icon | Colour |
|---|---|---|
| Done / synced / paid | `circle_check` | `success` |
| In progress | `loader_2` | `info` |
| Needs attention | `alert_triangle` | `warning` |
| Failed / blocked | `alert_circle` | `danger` |
| Expiring soon | `clock_exclamation` | `warning` |
| Expired | `calendar_x` | `danger` |
| Offline / unsynced | `wifi_off` | `warning` |
| Not started / draft | `circle_dashed` | `onSurfaceVariant` |
| Cancelled | `ban` | `danger` |
| Locked / posted | `lock` | `onSurfaceVariant` |
| Information | `info_circle` | `info` |

---

## Actions

| Action | Icon |
|---|---|
| Add | `plus` |
| Add to cart | `shopping_cart_plus` |
| Add a new record | `circle_plus` |
| Delete | `trash` |
| Clear a field | `x` |
| Close a screen or dialog | `x` — top-left, see SKILL.md §5 |
| Clear a whole form | `eraser` |
| Confirm / accept | `check` |
| Refresh / re-sync | `refresh` |
| Search | `search` |
| Advanced search | `file_search` |
| Filter | `filter` |
| Sort | `sort_ascending` |
| Adjust / configure | `adjustments` |
| View detail | `eye` |
| History | `history` |
| Print | `printer` |
| Pause / hold a sale | `player_pause` |
| Overflow menu | `dots_vertical` |
| Drill in | `chevron_right` |
| Go back | `chevron_left` |

---

## Empty states

**Rule: use the `_off` variant of whatever is missing.** Already the convention
in this repo — keep it.

| Nothing to show | Icon |
|---|---|
| No items / no stock | `package_off` |
| No invoices | `receipt_off` |
| No chart data | `chart_bar_off` |
| No branches | `building_off` |
| Empty cart | `shopping_cart_off` |
| Empty basket | `basket_off` |
| No search results | `search` at `AppIconSize.empty`, `onSurfaceVariant` |

---

## Checking a name exists

The package is one generated Dart file. To confirm a glyph before using it:

```bash
grep "IconData my_icon_name " \
  ~/AppData/Local/Pub/Cache/hosted/pub.dev/flutter_tabler_icons-*/lib/flutter_tabler_icons.dart
```

Some icons have `_filled` and `_off` variants. **Do not use `_filled`** — the
app is a single-weight stroke system, and one filled glyph in a row of stroked
ones is instantly visible as a mistake.
