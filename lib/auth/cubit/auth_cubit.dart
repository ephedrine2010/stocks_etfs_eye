import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/models.dart';
import '../../services/auth_service.dart';
import 'auth_state.dart';

export 'auth_state.dart';

/// The signed-in session, app-wide.
///
/// Lives above the page because the uid decides where "My stocks" is stored,
/// but it gates **nothing else** — the dashboard, tiles, screener, charts and
/// details all render signed-out exactly as they do today.
///
/// `FirebaseAuth.authStateChanges()` is the source of truth; this cubit only
/// mirrors it and tracks the in-flight attempt, which that stream can't express.
class AuthCubit extends Cubit<AuthState> {
  final AuthService service;

  StreamSubscription<AuthUser?>? _sub;

  AuthCubit(this.service)
    : super(AuthState(available: service.isAvailable)) {
    _sub = service.changes.listen(_onUser);
  }

  void _onUser(AuthUser? user) {
    if (isClosed) return;
    // The stream's first value is null while a sign-in is still running. Taking
    // it would flip the button back to "Sign in" mid-flow, so an in-flight
    // attempt stays in charge until it finishes.
    if (user == null && state.status == AuthStatus.signingIn) return;
    emit(
      state.copyWith(
        status: user == null ? AuthStatus.signedOut : AuthStatus.signedIn,
        user: user,
        clearUser: user == null,
        clearError: true,
      ),
    );
  }

  Future<void> signIn() async {
    if (state.isBusy) return;
    emit(state.copyWith(status: AuthStatus.signingIn, clearError: true));
    try {
      final user = await service.signInWithGoogle();
      if (isClosed) return;
      if (user == null) {
        // Cancelled. Back where we started, with nothing to apologise for.
        emit(state.copyWith(status: AuthStatus.signedOut, clearUser: true));
        return;
      }
      // The stream reports this too; emitting here means the UI doesn't wait on
      // it, and a second identical state is dropped by equality anyway.
      emit(state.copyWith(status: AuthStatus.signedIn, user: user));
    } on AuthFailure catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AuthStatus.signedOut,
          clearUser: true,
          error: e.message,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AuthStatus.signedOut,
          clearUser: true,
          error: "Sign-in didn't complete. Please try again.",
        ),
      );
    }
  }

  Future<void> signOut() async {
    await service.signOut();
    if (isClosed) return;
    emit(state.copyWith(status: AuthStatus.signedOut, clearUser: true, clearError: true));
  }

  void dismissError() {
    if (state.error != null) emit(state.copyWith(clearError: true));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
