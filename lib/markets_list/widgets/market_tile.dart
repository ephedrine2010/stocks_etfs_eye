import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/sparkline.dart';
import '../cubit/markets_list_state.dart';

/// A single market status tile. Everything time-dependent (open/closed, the
/// local clock) arrives pre-computed on [status], so the tile itself is dumb and
/// repaints once per tick.
///
/// Tapping it opens that market's details dialog.
class MarketTile extends StatefulWidget {
  final MarketStatus status;
  final VoidCallback onTap;

  const MarketTile({super.key, required this.status, required this.onTap});

  @override
  State<MarketTile> createState() => _MarketTileState();
}

class _MarketTileState extends State<MarketTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final market = widget.status.market;
    final changePct = market.quote.changePct;
    final label = market.always
        ? '24/7'
        : market.commodity
        ? 'Trades'
        : 'Local';
    final suffix = (market.always || market.commodity) ? ' UTC' : '';

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md + 1),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppRadius.md + 1),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.curve,
            padding: const EdgeInsets.all(AppSpacing.lg - 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md + 1),
              border: Border.all(
                color: _hover ? AppColors.lineHover : AppColors.line,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(market.flag, market.name, market.city),
                const SizedBox(height: AppSpacing.sm + 2),
                Text(
                  market.indexLabel,
                  style: AppText.caption.copyWith(color: AppColors.ink2),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(Fmt.price(market.quote.price), style: AppText.numHeadline),
                const SizedBox(height: 2),
                ChangeText(changePct, big: true, fontSize: 12.5),
                const SizedBox(height: AppSpacing.sm),
                Sparkline(data: market.spark, changePct: changePct),
                const SizedBox(height: AppSpacing.sm),
                _clock(label, suffix),
                const SizedBox(height: AppSpacing.sm),
                _watch(market.watchSymbols),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(String flag, String name, String city) => Row(
    children: [
      Text(flag, style: const TextStyle(fontSize: 19)),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: AppText.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              city,
              style: AppText.micro.copyWith(fontSize: 10.5),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      StatusPill(open: widget.status.isOpen),
    ],
  );

  Widget _clock(String label, String suffix) => Row(
    children: [
      Expanded(
        child: Text(
          '$label ${widget.status.localClock}$suffix',
          style: AppText.mono.copyWith(fontSize: 11.5, color: AppColors.ink2),
        ),
      ),
      // The affordance for "there is more behind this tile".
      AnimatedOpacity(
        duration: AppMotion.fast,
        opacity: _hover ? 1 : 0.4,
        child: const Icon(
          TablerIcons.chevron_right,
          size: 14,
          color: AppColors.ink3,
        ),
      ),
    ],
  );

  Widget _watch(List<String> symbols) => Wrap(
    spacing: AppSpacing.xs,
    runSpacing: AppSpacing.xs,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text('Watch', style: AppText.micro.copyWith(fontWeight: FontWeight.w700)),
      for (final s in symbols)
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs + 2,
            vertical: 2,
          ),
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
