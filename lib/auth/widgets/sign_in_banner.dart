import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../app/theme.dart';
import '../../shared/widgets/controls.dart';
import '../cubit/auth_cubit.dart';

/// The whole visible surface of sign-in: one thin strip inside "My stocks".
///
/// It exists because the saved list is per-account. Nothing else in the app is
/// gated on it — the dashboard, tiles, screener and charts all work signed-out
/// — so this never grows into a login wall.
///
/// Renders nothing when sign-in can't run here (Firebase down, or a platform
/// with no flow yet). An affordance that could only fail is worse than none.
class SignInBanner extends StatelessWidget {
  const SignInBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.unknown) return const SizedBox.shrink();
        if (!state.available && !state.isSignedIn) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: state.isSignedIn
              ? _SignedIn(state: state)
              : _SignedOut(state: state),
        );
      },
    );
  }
}

class _SignedOut extends StatelessWidget {
  final AuthState state;
  const _SignedOut({required this.state});

  @override
  Widget build(BuildContext context) {
    final error = state.error;
    return _Strip(
      icon: error != null ? TablerIcons.alert_triangle : TablerIcons.cloud_off,
      tint: error != null ? AppColors.loss : AppColors.ink3,
      // The error replaces the invitation rather than stacking under it — the
      // user needs one sentence here, not two.
      text: error ?? 'Sign in to save your stocks across devices.',
      trailing: AppPill(
        label: state.isBusy ? 'Signing in…' : 'Sign in',
        icon: TablerIcons.brand_google,
        active: false,
        onTap: () => context.read<AuthCubit>().signIn(),
      ),
    );
  }
}

class _SignedIn extends StatelessWidget {
  final AuthState state;
  const _SignedIn({required this.state});

  @override
  Widget build(BuildContext context) {
    final label = state.user?.label;
    return _Strip(
      icon: TablerIcons.cloud_check,
      tint: AppColors.gain,
      text: label == null ? 'Saved to your account.' : 'Saved to $label\'s account.',
      trailing: AppPill(
        label: 'Sign out',
        icon: TablerIcons.logout,
        active: false,
        onTap: () => context.read<AuthCubit>().signOut(),
      ),
    );
  }
}

/// Flat, bordered, one line — deliberately quieter than the tables it sits
/// above, because it is housekeeping, not data.
class _Strip extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String text;
  final Widget trailing;

  const _Strip({
    required this.icon,
    required this.tint,
    required this.text,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    decoration: BoxDecoration(
      color: AppColors.surface2,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      children: [
        Icon(icon, size: AppIconSize.inline, color: tint),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppText.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        trailing,
      ],
    ),
  );
}
