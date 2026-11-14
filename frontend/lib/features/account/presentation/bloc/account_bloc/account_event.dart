part of 'account_bloc.dart';

sealed class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Subscribes to the session and ACCOUNT_CHANGED, then loads.
final class AccountStarted extends AccountEvent {
  const AccountStarted();
}

/// Re-reads profile, subscription and limits (after a match, on return
/// from billing, on screen open).
final class AccountRefreshRequested extends AccountEvent {
  const AccountRefreshRequested();
}

final class AccountLogoutRequested extends AccountEvent {
  const AccountLogoutRequested();
}

final class _AccountSignedInChanged extends AccountEvent {
  const _AccountSignedInChanged(this.isSignedIn);

  final bool isSignedIn;

  @override
  List<Object?> get props => <Object?>[isSignedIn];
}

final class _AccountChangeReceived extends AccountEvent {
  const _AccountChangeReceived(this.account);

  final AccountStateEntity account;

  @override
  List<Object?> get props => <Object?>[account];
}
