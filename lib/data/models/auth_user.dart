import 'package:equatable/equatable.dart';

/// Who is signed in.
///
/// Deliberately thin: the app needs a [uid] to find the user's Firestore doc
/// and something short to show beside the sign-out affordance — nothing else.
/// Keeping it separate from `firebase_auth`'s `User` means the cubit, the store
/// and the widgets never import the SDK, so swapping the provider stays an edit
/// to `auth_service.dart` alone.
class AuthUser extends Equatable {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  const AuthUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  /// Shortest honest label for the UI: given name, else the email's local part,
  /// else nothing — never the raw uid, which means nothing to the user.
  String? get label {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name.split(' ').first;
    final mail = email?.trim();
    if (mail != null && mail.contains('@')) return mail.split('@').first;
    return null;
  }

  @override
  List<Object?> get props => [uid, displayName, email, photoUrl];
}
