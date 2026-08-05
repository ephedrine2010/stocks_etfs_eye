import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../app/theme.dart';
import '../../data/models/models.dart';
import '../../services/dashboard_repository.dart';
import '../../services/price_history_service.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/controls.dart';
import '../../shared/widgets/price_chart.dart';
import '../../shared/widgets/surfaces.dart';
import '../cubit/instrument_chart_cubit.dart';

/// Open one instrument's price curve over the market details dialog. Reusable
/// from any table that can resolve a [HistoryTarget] — movers, leaders, or a
/// market's own index.
Future<void> showInstrumentChart(BuildContext context, HistoryTarget target) {
  final service = context.read<DashboardRepository>().history;
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => BlocProvider(
      create: (_) => InstrumentChartCubit(service, target)..load(),
      child: const InstrumentChartDialog(),
    ),
  );
}

/// Header → range pills → curve (or "N.A."). Closes from the top-left `X`, the
/// same place as every other surface that opens over the page.
class InstrumentChartDialog extends StatelessWidget {
  const InstrumentChartDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InstrumentChartCubit, InstrumentChartState>(
      builder: (context, state) {
        return Dialog(
          insetPadding: const EdgeInsets.all(AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: const BorderSide(color: AppColors.line),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(target: state.target),
                const Divider(height: 1, color: AppColors.line),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RangePills(selected: state.range),
                      const SizedBox(height: AppSpacing.lg),
                      _Curve(state: state),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Historical prices are informational only — '
                        'not investment advice.',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final HistoryTarget target;
  const _Header({required this.target});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(TablerIcons.x, size: AppIconSize.standard),
            color: AppColors.ink2,
          ),
          const SizedBox(width: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs + 2),
            child: const IconChip(TablerIcons.chart_line),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    target.symbol,
                    style: AppText.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    target.name,
                    style: AppText.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangePills extends StatelessWidget {
  final HistoryRange selected;
  const _RangePills({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final range in HistoryRange.values)
          AppPill(
            label: range.label,
            tooltip: range.longLabel,
            active: range == selected,
            onTap: () =>
                context.read<InstrumentChartCubit>().select(range),
          ),
      ],
    );
  }
}

/// The curve, a placeholder of the same height while it loads, or "N.A." when
/// the source has nothing for this instrument and window.
class _Curve extends StatelessWidget {
  final InstrumentChartState state;
  const _Curve({required this.state});

  static const _height = 236.0;

  @override
  Widget build(BuildContext context) {
    if (state.loading) {
      return const SizedBox(
        height: _height,
        child: Center(
          child: SizedBox(
            width: AppIconSize.standard,
            height: AppIconSize.standard,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accent,
            ),
          ),
        ),
      );
    }

    final history = state.history;
    if (history == null) {
      return SizedBox(
        height: _height,
        child: Center(
          child: EmptyState(
            icon: TablerIcons.chart_bar_off,
            title: 'N.A. — no ${state.range.longLabel.toLowerCase()} history',
            hint: 'This source has no series for ${state.target.symbol}. '
                'Try another period.',
          ),
        ),
      );
    }

    // Sizes itself: the placeholders above hold [_height] so the dialog doesn't
    // jump much between states, but a real curve is never squeezed into it.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        PriceChart(history: history),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            InfoChip('Source · ${history.source}'),
            InfoChip(history.currency),
            InfoChip('${history.points.length} pts'),
          ],
        ),
      ],
    );
  }
}
