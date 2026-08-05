# POS_X component recipes

Copy these. They are the components the app actually repeats, written to the
rules in SKILL.md. Every one is dark-mode safe and uses tokens only.

All of them assume:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../themes/app_semantic_colors.dart';   // context.scheme, context.appColors
import '../../themes/app_tokens.dart';            // AppSpacing, AppRadius, AppIconSize
```

---

## 1. Card

The base surface for everything. Flat, bordered, no shadow.

```dart
Container(
  padding: const EdgeInsets.all(AppSpacing.lg),
  decoration: BoxDecoration(
    color: context.scheme.surface,
    borderRadius: AppRadius.card,
    border: Border.all(color: context.scheme.outlineVariant),
  ),
  child: child,
)
```

Tappable? Wrap the content in `Material` + `InkWell` so the ripple is clipped:

```dart
Material(
  color: context.scheme.surface,
  borderRadius: AppRadius.card,
  child: InkWell(
    borderRadius: AppRadius.card,
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        border: Border.all(color: context.scheme.outlineVariant),
      ),
      child: child,
    ),
  ),
)
```

---

## 2. Card header with a tinted icon chip

The signature POS_X row. `accent` is the category colour, or
`context.scheme.primary` when the card has no category.

```dart
Row(
  children: [
    Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: AppRadius.iconChip,
      ),
      child: Icon(icon, color: accent, size: AppIconSize.chip),
    ),
    const SizedBox(width: AppSpacing.md),
    Expanded(
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    Icon(
      TablerIcons.chevron_right,
      size: AppIconSize.dense,
      color: context.scheme.onSurfaceVariant,
    ),
  ],
)
```

---

## 3. Buttons

```dart
// Ordinary action — navy. The default; no styling needed.
FilledButton(onPressed: _save, child: const Text('Save'))

FilledButton.icon(
  onPressed: _add,
  icon: const Icon(TablerIcons.plus, size: AppIconSize.standard),
  label: const Text('Add item'),
)

// Secondary action
OutlinedButton(onPressed: _cancel, child: const Text('Cancel'))

// Tertiary / low emphasis
TextButton(onPressed: _reset, child: const Text('Reset filters'))

// CONFIRM A TRANSACTION — green. One per screen, maximum.
FilledButton.icon(
  style: FilledButton.styleFrom(
    backgroundColor: context.scheme.tertiary,
    foregroundColor: context.scheme.onTertiary,
  ),
  onPressed: _confirmPayment,
  icon: const Icon(TablerIcons.check, size: AppIconSize.standard),
  label: const Text('Confirm payment'),
)

// Destructive
FilledButton.icon(
  style: FilledButton.styleFrom(
    backgroundColor: context.appColors.danger,
    foregroundColor: Colors.white,
  ),
  onPressed: _delete,
  icon: const Icon(TablerIcons.trash, size: AppIconSize.standard),
  label: const Text('Delete'),
)
```

---

## 4. Status pill

Colour carries severity, glyph carries meaning, text carries the detail.

```dart
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.appColors.tint(color),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize.inline, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
```

Used as:

```dart
StatusPill(
  label: 'Low stock',
  icon: TablerIcons.alert_triangle,
  color: context.appColors.warning,
)
```

---

## 5. Money figure

Signed, tabular, and coloured by sign — not by success/failure.

```dart
class MoneyText extends StatelessWidget {
  const MoneyText({super.key, required this.amount, this.style});

  final double amount;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final c = amount < 0 ? context.appColors.loss : context.appColors.profit;
    return Text(
      amount.toStringAsFixed(2),
      style: (style ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
        color: c,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
```

A plain total that is not a gain or a loss — an invoice total, a quantity —
takes **no** colour, only tabular figures:

```dart
Text(
  total.toStringAsFixed(2),
  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
    fontWeight: FontWeight.w700,
    fontFeatures: const [FontFeature.tabularFigures()],
  ),
)
```

---

## 6. Empty state

Always says what is missing **and** what to do about it.

```dart
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? hint;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize.empty, color: scheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}
```

```dart
EmptyState(
  icon: TablerIcons.package_off,
  title: 'No items in this branch yet',
  hint: 'Receive a purchase to start tracking stock.',
  action: FilledButton(onPressed: _openBuy, child: const Text('Open Buy')),
)
```

---

## 7. Search field

```dart
SizedBox(
  width: 420,
  child: TextField(
    onChanged: cubit.search,
    decoration: const InputDecoration(
      hintText: 'Search items…',
      prefixIcon: Icon(TablerIcons.search, size: AppIconSize.dense),
    ),
  ),
)
```

Everything else — fill, radius, borders, focus ring — comes from
`inputDecorationTheme`. Do not re-specify it per field.

---

## 8. Section heading

```dart
Row(
  children: [
    Text(
      title,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    ),
    const SizedBox(width: AppSpacing.sm),
    Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: context.scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text('$count', style: Theme.of(context).textTheme.labelSmall),
    ),
  ],
)
```

---

## 9. Loading and error states inside a `BlocBuilder`

```dart
if (state is XLoading) {
  return const Center(child: CircularProgressIndicator());
}

if (state is XError) {
  return EmptyState(
    icon: TablerIcons.alert_circle,
    title: 'Could not load',
    hint: state.message,
    action: FilledButton.icon(
      onPressed: () => context.read<XCubit>().load(),
      icon: const Icon(TablerIcons.refresh, size: AppIconSize.standard),
      label: const Text('Try again'),
    ),
  );
}
```

The spinner takes no `color:` — the theme handles it. Do not wrap it in a
gradient box or a tinted card.

---

## 10. Slide-in panel (Sell / Buy pattern)

```dart
Stack(
  children: [
    content,

    if (isOpen)
      Positioned.fill(
        child: GestureDetector(
          onTap: _close,
          child: Container(color: Colors.black.withValues(alpha: 0.3)),
        ),
      ),

    AnimatedPositioned(
      duration: AppMotion.panel,
      curve: AppMotion.curve,
      right: isOpen ? 0 : -400,
      top: 0,
      bottom: 0,
      width: 400,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.scheme.surface,
          border: Border(
            left: BorderSide(color: context.scheme.outlineVariant),
          ),
        ),
        child: panel,
      ),
    ),
  ],
)
```

The scrim is the one place a raw `Colors.black` is correct — it is a light
value, not a theme colour, and it must darken in both modes.
