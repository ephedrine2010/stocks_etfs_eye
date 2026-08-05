import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// The one card in the app: a flat surface with a 1px border.
///
/// No gradient, no coloured shadow — separation is the border's job. A shadow
/// is reserved for something that genuinely floats above the page (a dialog),
/// which is why [AppCard] never takes one.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Draw the accent border, e.g. for a selected tile.
  final bool highlighted;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg + 2),
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg - 2),
      border: Border.all(
        color: highlighted ? AppColors.accent : AppColors.line,
        width: highlighted ? 1.5 : 1,
      ),
    ),
    child: child,
  );
}

/// The tinted icon chip: a glyph on a 12% wash of its own colour. Used as the
/// leading mark on a header — brand, dialog title, empty state.
class IconChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final EdgeInsetsGeometry padding;

  const IconChip(
    this.icon, {
    super.key,
    this.color = AppColors.accent,
    this.size = AppIconSize.chip,
    this.padding = const EdgeInsets.all(9),
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.tint(color),
      borderRadius: BorderRadius.circular(AppRadius.iconChip),
    ),
    child: Icon(icon, color: color, size: size),
  );
}

/// Nothing to show. Names the missing thing with its `_off` glyph and says what
/// to do next — never a bare "No data".
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  final EdgeInsetsGeometry padding;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize.empty, color: AppColors.ink3),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppText.bodyMuted, textAlign: TextAlign.center),
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(hint!, style: AppText.caption, textAlign: TextAlign.center),
          ],
        ],
      ),
    ),
  );
}
