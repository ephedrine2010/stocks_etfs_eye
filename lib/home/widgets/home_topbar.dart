import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../markets_list/cubit/markets_list_cubit.dart';
import '../../shared/widgets/surfaces.dart';
import '../cubit/home_cubit.dart';

/// Top bar: brand · refresh · "N open" badge · live UTC clock.
///
/// The badge and the clock both read [MarketsListCubit] — it already ticks once
/// a second and knows how many markets are open, so the page runs off one timer.
class HomeTopbar extends StatelessWidget {
  const HomeTopbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg + 2),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final narrow = c.maxWidth < 520;
          final status = BlocBuilder<MarketsListCubit, MarketsListState>(
            builder: (context, state) => Row(
              mainAxisSize: narrow ? MainAxisSize.max : MainAxisSize.min,
              children: [
                const _RefreshButton(),
                const SizedBox(width: AppSpacing.xs + 2),
                // The badge sheds its word before the clock sheds digits.
                Flexible(
                  child: _Badge(
                    narrow
                        ? '${state.openCount}/${state.total}'
                        : '${state.openCount} / ${state.total} open',
                  ),
                ),
                const SizedBox(width: AppSpacing.md + 2),
                // Flexible so a tight screen shrinks the clock instead of
                // overflowing; the subtitle is dropped when narrow.
                Flexible(child: _Clock(state.now.toUtc(), compact: narrow)),
              ],
            ),
          );

          // Stack under the brand when there isn't room for one row.
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Brand(),
                const SizedBox(height: AppSpacing.md + 2),
                status,
              ],
            );
          }
          return Row(children: [const _Brand(), const Spacer(), status]);
        },
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      // min + Flexible: on a wide screen the brand sits beside a Spacer with
      // unbounded width, where a flex child would otherwise assert.
      mainAxisSize: MainAxisSize.min,
      children: [
        const IconChip(TablerIcons.eye, size: AppIconSize.dense),
        const SizedBox(width: AppSpacing.md - 1),
        // Flexible: the wide-tracked subtitle is what runs out of room first on
        // a 320 px screen, and it should ellipsize rather than overflow.
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Stocks Eye',
                style: AppText.headline,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'MULTI-MARKET MONITOR',
                style: AppText.label.copyWith(fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final refreshing = state is HomeLoaded && state.refreshing;
        return IconButton(
          tooltip: 'Refresh',
          visualDensity: VisualDensity.compact,
          iconSize: AppIconSize.dense,
          color: AppColors.ink2,
          onPressed: refreshing
              ? null
              : () => context.read<HomeCubit>().refresh(),
          icon: refreshing
              ? const SizedBox(
                  width: AppIconSize.inline,
                  height: AppIconSize.inline,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                )
              : const Icon(TablerIcons.refresh),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm + 2,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(color: AppColors.line),
    ),
    child: Text(
      text.toUpperCase(),
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 10.5,
        letterSpacing: 1,
        color: AppColors.ink3,
      ),
    ),
  );
}

class _Clock extends StatelessWidget {
  final DateTime utc;
  final bool compact;
  const _Clock(this.utc, {this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${DateFormat('HH:mm:ss').format(utc)}${compact ? ' UTC' : ''}',
          style: AppText.mono.copyWith(fontSize: 15, color: AppColors.ink),
        ),
        if (!compact)
          Text(
            'Coordinated Universal Time',
            style: AppText.caption.copyWith(color: AppColors.ink2),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
