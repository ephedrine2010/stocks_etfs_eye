import 'package:flutter_bloc/flutter_bloc.dart';

/// Holds the currently-selected market id (drives the detail panel).
/// Null until the first dashboard load picks a default (USA).
class SelectionCubit extends Cubit<String?> {
  SelectionCubit() : super(null);

  void select(String id) => emit(id);

  /// Default to the first market once data is available, if nothing chosen yet.
  void ensureSelection(String defaultId) {
    if (state == null) emit(defaultId);
  }
}
