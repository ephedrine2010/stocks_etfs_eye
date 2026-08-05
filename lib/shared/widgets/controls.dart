import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../app/theme.dart';

/// A tappable filter pill; tinted with [activeColor] when [active].
///
/// Selected is a 16% wash of the accent with a solid border, unselected is the
/// nested surface — the same treatment everywhere a filter row appears.
class AppPill extends StatelessWidget {
  final String label;
  final bool active;
  final Color? activeColor;
  final IconData? icon;
  final String? tooltip;
  final VoidCallback onTap;

  const AppPill({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.activeColor,
    this.icon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final accent = activeColor ?? AppColors.accent;
    final pill = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md - 1,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: active
                ? accent.withValues(alpha: 0.16)
                : AppColors.surface2,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: active ? accent : AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: active ? accent : AppColors.ink3,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? AppColors.ink : AppColors.ink2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? pill : Tooltip(message: tooltip!, child: pill);
  }
}

/// A faint vertical separator between control groups.
class PillDivider extends StatelessWidget {
  const PillDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: AppSpacing.xl, color: AppColors.line);
}

/// The app's single search field shape — dense, nested surface, tabler glyph.
class AppSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final double maxWidth;

  const AppSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.maxWidth = 190,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(
        height: AppSpacing.huge,
        child: TextField(
          onChanged: onChanged,
          style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
          cursorColor: AppColors.accent,
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.ink3),
            prefixIcon: const Icon(
              TablerIcons.search,
              size: 15,
              color: AppColors.ink3,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 30,
              minHeight: 30,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            filled: true,
            fillColor: AppColors.surface2,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(color: AppColors.accentDim),
            ),
          ),
        ),
      ),
    );
  }
}
