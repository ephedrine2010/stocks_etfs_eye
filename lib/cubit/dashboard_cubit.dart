import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/models.dart';
import '../data/repository/dashboard_repository.dart';

sealed class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final Dashboard dashboard;

  /// True while a background refresh runs over already-loaded data.
  final bool refreshing;

  const DashboardLoaded(this.dashboard, {this.refreshing = false});

  @override
  List<Object?> get props => [dashboard, refreshing];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Owns loading/refreshing the dashboard payload.
class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _repo;

  DashboardCubit(this._repo) : super(const DashboardLoading());

  Future<void> load() async {
    emit(const DashboardLoading());
    await _fetch();
  }

  /// Silent refresh — keeps current data visible while re-fetching.
  Future<void> refresh() async {
    final current = state;
    if (current is DashboardLoaded) {
      emit(DashboardLoaded(current.dashboard, refreshing: true));
    }
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      final dashboard = await _repo.load();
      emit(DashboardLoaded(dashboard));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
