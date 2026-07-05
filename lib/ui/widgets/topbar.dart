import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../cubit/clock_cubit.dart';
import '../../cubit/dashboard_cubit.dart';
import '../../data/models/models.dart';
import '../../data/repository/market_hours.dart';

/// Top bar: brand, spacer, "N open" badge, live UTC clock.
class Topbar extends StatelessWidget {
  final List<Market> markets;
  const Topbar({super.key, required this.markets});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final narrow = c.maxWidth < 520;
          final status = BlocBuilder<ClockCubit, DateTime>(
            builder: (context, now) {
              final open =
                  markets.where((m) => MarketHours.isOpen(m.schedule)).length;
              return Row(
                mainAxisSize: narrow ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  const _RefreshButton(),
                  const SizedBox(width: 6),
                  _Badge('$open / ${markets.length} open'),
                  const SizedBox(width: 14),
                  // Flexible so a tight screen shrinks the clock instead of
                  // overflowing; the subtitle is dropped when narrow.
                  Flexible(child: _Clock(now.toUtc(), compact: narrow)),
                ],
              );
            },
          );

          // Stack under the brand when there isn't room for one row.
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Brand(),
                const SizedBox(height: 14),
                status,
              ],
            );
          }
          return Row(
            children: [const _Brand(), const Spacer(), status],
          );
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
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            gradient: const RadialGradient(
              center: Alignment(0, -0.1),
              radius: 0.9,
              colors: [AppColors.accent, Color(0xFF4A3A16), AppColors.surface2],
              stops: [0.30, 0.60, 0.61],
            ),
          ),
          child: const Icon(TablerIcons.eye, size: 18, color: AppColors.ground),
        ),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Stocks Eye',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: AppColors.ink,
              ),
            ),
            Text(
              'MULTI-MARKET MONITOR',
              style: AppText.label.copyWith(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final refreshing = state is DashboardLoaded && state.refreshing;
        return IconButton(
          tooltip: 'Refresh',
          visualDensity: VisualDensity.compact,
          iconSize: 18,
          color: AppColors.ink2,
          onPressed: refreshing
              ? null
              : () => context.read<DashboardCubit>().refresh(),
          icon: refreshing
              ? const SizedBox(
                  width: 16,
                  height: 16,
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
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: AppColors.line),
    ),
    child: Text(
      text.toUpperCase(),
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
          const Text(
            'Coordinated Universal Time',
            style: TextStyle(fontSize: 11, color: AppColors.ink2),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
