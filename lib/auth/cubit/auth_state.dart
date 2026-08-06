import 'package:equatable/equatable.dart';

import '../../data/models/models.dart';

/// Where the session is. [unknown] only ever holds until the auth stream
/// delivers its first value, so the UI can avoid flashing "signed out" at a
/// user who is in fact signed in.
enum AuthStatus { unknown, signedOut, signingIn, signedIn }

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthUser? user;

  /// Sign-in can run on this platform at all (Firebase is up and a flow exists).
  /// False is a fact about the platform, not a failure — the UI says so rather
  /// than offering a button that can't work.
  final bool available;

  /// The last failure, cleared as soon as anything else happens. A user
  /// cancelling the flow does **not** set this.
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.available = false,
    this.error,
  });

  bool get isSignedIn => status == AuthStatus.signedIn && user != null;
  bool get isBusy => status == AuthStatus.signingIn;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    bool? available,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) => AuthState(
    status: status ?? this.status,
    user: clearUser ? null : (user ?? this.user),
    available: available ?? this.available,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props => [status, user, available, error];
}
