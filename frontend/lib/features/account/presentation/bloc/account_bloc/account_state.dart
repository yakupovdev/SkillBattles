part of 'account_bloc.dart';

final class AccountState extends Equatable {
  const AccountState({
    required this.isSignedIn,
    this.status = LoadStatus.initial,
    this.account,
    this.failure,
    this.logoutStatus = LoadStatus.initial,
  });

  final bool isSignedIn;
  final LoadStatus status;
  final AccountStateEntity? account;
  final Failure? failure;
  final LoadStatus logoutStatus;

  EntitlementsEntity? get entitlements => account?.limits.entitlements;

  bool get isPro => account?.subscription.entitlements.isPro ?? false;

  /// Changes whenever access rights change; paid views re-read on change.
  int? get entitlementsVersion => account?.subscription.entitlements.version;

  AccountState copyWith({
    bool? isSignedIn,
    LoadStatus? status,
    AccountStateEntity? account,
    Failure? failure,
    LoadStatus? logoutStatus,
    bool resetFailure = false,
  }) {
    return AccountState(
      isSignedIn: isSignedIn ?? this.isSignedIn,
      status: status ?? this.status,
      account: account ?? this.account,
      failure: resetFailure ? null : failure ?? this.failure,
      logoutStatus: logoutStatus ?? this.logoutStatus,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    isSignedIn,
    status,
    account,
    failure,
    logoutStatus,
  ];
}
