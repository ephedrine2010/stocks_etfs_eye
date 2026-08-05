import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/models.dart';
import '../../services/dashboard_repository.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  /// The markets this state carries, or empty while loading/failed. Lets the
  /// page feed the section cubits without switching on the state everywhere.
  List<Market> get markets => const [];

  @override
  List<Object?> get props => [];
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final Dashboard dashboard;

  /// True while a background refresh runs over already-loaded data.
  final bool refreshing;

  const HomeLoaded(this.dashboard, {this.refreshing = false});

  @override
  List<Market> get markets => dashboard.markets;

  @override
  List<Object?> get props => [dashboard, refreshing];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Owns loading and refreshing the whole dashboard payload for the home page.
/// The sections (screener, markets list) keep their own view state and are fed
/// the markets from here.
class HomeCubit extends Cubit<HomeState> {
  final DashboardRepository _repo;

  HomeCubit(this._repo) : super(const HomeLoading());

  Future<void> load() async {
    emit(const HomeLoading());
    await _fetch();
  }

  /// Silent refresh — keeps current data visible while re-fetching.
  Future<void> refresh() async {
    final current = state;
    if (current is HomeLoaded) {
      emit(HomeLoaded(current.dashboard, refreshing: true));
    }
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      final dashboard = await _repo.load();
      emit(HomeLoaded(dashboard));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
