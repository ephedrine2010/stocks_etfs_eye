import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../../cubit/clock_cubit.dart';
import '../../data/models/models.dart';
import '../../data/repository/market_hours.dart';
import 'common.dart';
import 'sparkline.dart';

/// A single market status tile. Open/closed + local clock are recomputed on each
/// ClockCubit tick, so the tile ticks without a data refresh.
class MarketTile extends StatelessWidget {
  final Market market;
  final bool selected;
  final VoidCallback onTap;

  const MarketTile({
    super.key,
    required this.market,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final changePct = market.quote.changePct;
    final label = market.always
        ? '24/7'
        : market.commodity
        ? 'Trades'
        : 'Local';
    final suffix = (market.always || market.commodity) ? ' UTC' : '';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(),
              const SizedBox(height: 10),
              Text(
                market.indexLabel,
                style: const TextStyle(fontSize: 11, color: AppColors.ink2),
              ),
              const SizedBox(height: 2),
              Text(
                Fmt.price(market.quote.price),
                style: AppText.mono.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              ChangeText(changePct, big: true, fontSize: 12.5),
              const SizedBox(height: 8),
              Sparkline(data: market.spark, changePct: changePct),
              const SizedBox(height: 8),
              _clock(label, suffix),
              const SizedBox(height: 8),
              _watch(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => Row(
    children: [
      Text(market.flag, style: const TextStyle(fontSize: 19)),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              market.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              market.city,
              style: const TextStyle(fontSize: 10.5, color: AppColors.ink3),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      // Rebuild the pill each tick so it flips at the session boundary.
      BlocBuilder<ClockCubit, DateTime>(
        builder: (_, __) => StatusPill(open: MarketHours.isOpen(market.schedule)),
      ),
    ],
  );

  Widget _clock(String label, String suffix) =>
      BlocBuilder<ClockCubit, DateTime>(
        builder: (_, __) => Text(
          '$label ${MarketHours.localClock(market.tz)}$suffix',
          style: AppText.mono.copyWith(fontSize: 11.5, color: AppColors.ink2),
        ),
      );

  Widget _watch() => Wrap(
    spacing: 4,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      const Text(
        'Watch',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.ink3,
        ),
      ),
      for (final s in market.watchSymbols)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            s,
            style: AppText.mono.copyWith(fontSize: 10, color: AppColors.ink2),
          ),
        ),
    ],
  );
}
