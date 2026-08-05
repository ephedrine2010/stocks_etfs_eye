import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../app/theme.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/controls.dart';
import '../../shared/widgets/surfaces.dart';
import '../cubit/my_stocks_cubit.dart';
import '../cubit/stock_search_cubit.dart';

/// Search this market's exchange for a stock and add it to "My stocks".
///
/// Takes the already-built [MyStocksCubit] by value so the section behind it
/// updates the moment something is added — the dialog never owns the list.
Future<void> showAddStock(BuildContext context, MyStocksCubit myStocks) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: myStocks),
        BlocProvider(
          create: (_) => StockSearchCubit(
            service: myStocks.service,
            market: myStocks.market,
          ),
        ),
      ],
      child: const AddStockDialog(),
    ),
  );
}

/// Header → search field → results. Closes from the top-left `X`, the same
/// place as every other surface that opens over the page.
class AddStockDialog extends StatelessWidget {
  const AddStockDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final market = context.read<MyStocksCubit>().market;
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.line),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(market: market),
            const Divider(height: 1, color: AppColors.line),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: AppSearchField(
                hint: 'Ticker or company name',
                maxWidth: double.infinity,
                onChanged: context.read<StockSearchCubit>().search,
              ),
            ),
            const Flexible(child: _Results()),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Text(
                'Results are limited to ${market.name} listings, so an added '
                'row keeps this market\'s currency and trading hours.',
                style: AppText.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final MarketConfig market;
  const _Header({required this.market});

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
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs + 2),
            child: IconChip(TablerIcons.search),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add a stock', style: AppText.title),
                  const SizedBox(height: 3),
                  Text(
                    '${market.flag} ${market.name} · ${market.currency}',
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

class _Results extends StatelessWidget {
  const _Results();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockSearchCubit, StockSearchState>(
      builder: (context, search) {
        if (search.searching) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.huge),
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

        if (search.results.isEmpty) {
          final market = context.read<MyStocksCubit>().market;
          return EmptyState(
            icon: search.searched
                ? TablerIcons.search_off
                : TablerIcons.zoom_scan,
            title: search.searched
                ? 'Nothing matching "${search.query}"'
                : 'Search ${market.name}',
            hint: search.searched
                ? 'Try the ticker itself, or a shorter part of the name.'
                : 'Type at least two characters of a ticker or company name.',
          );
        }

        return BlocBuilder<MyStocksCubit, MyStocksState>(
          builder: (context, mine) {
            final savedKeys = {for (final s in mine.saved) s.key};
            return ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              itemCount: search.results.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.line),
              itemBuilder: (_, i) {
                final hit = search.results[i];
                return _ResultRow(
                  hit: hit,
                  added: savedKeys.contains(hit.key),
                  onAdd: () => context.read<MyStocksCubit>().add(hit),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ResultRow extends StatelessWidget {
  final SavedStock hit;
  final bool added;
  final VoidCallback onAdd;

  const _ResultRow({
    required this.hit,
    required this.added,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              hit.symbol,
              style: AppText.numCell,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              hit.name,
              style: AppText.bodyMuted,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (added)
            Text(
              'Added',
              style: AppText.caption.copyWith(color: AppColors.gain),
            )
          else
            AppPill(label: 'Add', active: false, icon: TablerIcons.plus, onTap: onAdd),
        ],
      ),
    );
  }
}
