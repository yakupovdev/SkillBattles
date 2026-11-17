import 'dart:async';

import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/entitlements_entity.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/presentation/bloc/signal_bloc.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/account/domain/entity/account_state_entity.dart';
import 'package:skill_battles/features/account/domain/usecases/get_account_state_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/watch_account_changes_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/logout_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/watch_signed_in_usecase.dart';

part 'account_event.dart';
part 'account_state.dart';

/// App-level account: profile, verified subscription, limits and the
/// entitlement version every screen with paid data listens to.
///
/// ACCOUNT_CHANGED replaces the state at once; a sign-out drops it, so no
/// paid data outlives the session in memory.
final class AccountBloc extends SignalBloc<AccountEvent, AccountState> {
  AccountBloc({
    required this._getAccountState,
    required this._watchAccountChanges,
    required this._watchSignedIn,
    required this._logout,
    required bool isSignedIn,
  }) : super(AccountState(isSignedIn: isSignedIn)) {
    handle<AccountStarted>(_onStarted);
    handle<AccountRefreshRequested>(_onRefreshRequested);
    handle<AccountLogoutRequested>(_onLogoutRequested);
    handle<_AccountSignedInChanged>(_onSignedInChanged);
    handle<_AccountChangeReceived>(_onChangeReceived);
  }

  final GetAccountStateUsecase _getAccountState;
  final WatchAccountChangesUsecase _watchAccountChanges;
  final WatchSignedInUsecase _watchSignedIn;
  final LogoutUsecase _logout;

  StreamSubscription<bool>? _sessionSubscription;
  StreamSubscription<AccountStateEntity>? _changesSubscription;
  int _loadVersion = 0;

  Future<void> _onStarted(
    AccountStarted event,
    Emitter<AccountState> emit,
  ) async {
    _sessionSubscription ??= _watchSignedIn(const NoParams())
        .listen((bool signedIn) => add(_AccountSignedInChanged(signedIn)));
    _changesSubscription ??= _watchAccountChanges(const NoParams()).listen(
      (AccountStateEntity account) => add(_AccountChangeReceived(account)),
    );
    if (stateValue.isSignedIn) await _load(emit);
  }

  Future<void> _onRefreshRequested(
    AccountRefreshRequested event,
    Emitter<AccountState> emit,
  ) async {
    if (stateValue.isSignedIn) await _load(emit);
  }

  Future<void> _onSignedInChanged(
    _AccountSignedInChanged event,
    Emitter<AccountState> emit,
  ) async {
    if (!event.isSignedIn) {
      _loadVersion++;
      emit(AccountState(isSignedIn: false));
      return;
    }
    emit(stateValue.copyWith(isSignedIn: true));
    await _load(emit);
  }

  void _onChangeReceived(
    _AccountChangeReceived event,
    Emitter<AccountState> emit,
  ) {
    if (!stateValue.isSignedIn) return;
    // A later full read must not overwrite this newer push.
    _loadVersion++;
    emit(
      stateValue.copyWith(
        status: LoadStatus.success,
        account: event.account,
        resetFailure: true,
      ),
    );
  }

  Future<void> _onLogoutRequested(
    AccountLogoutRequested event,
    Emitter<AccountState> emit,
  ) async {
    emit(stateValue.copyWith(logoutStatus: LoadStatus.loading));
    await _logout(const NoParams());
    if (emit.isDone) return;
    emit(stateValue.copyWith(logoutStatus: LoadStatus.success));
  }

  Future<void> _load(Emitter<AccountState> emit) async {
    final int version = ++_loadVersion;
    emit(stateValue.copyWith(status: LoadStatus.loading));
    final Either<Failure, AccountStateEntity> result = await _getAccountState(
      const NoParams(),
    );
    if (emit.isDone || version != _loadVersion || !stateValue.isSignedIn) return;
    result.match(
      (Failure failure) => emit(stateValue.copyWith(status: LoadStatus.failure, failure: failure)),
      (AccountStateEntity account) => emit(
        stateValue.copyWith(
          status: LoadStatus.success,
          // Keep streaks from a previous push; a full read has none.
          account: account.streaks == null && stateValue.account?.streaks != null
              ? AccountStateEntity(
                  user: account.user,
                  subscription: account.subscription,
                  limits: account.limits,
                  streaks: stateValue.account?.streaks,
                )
              : account,
          resetFailure: true,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sessionSubscription?.cancel();
    await _changesSubscription?.cancel();
    return super.close();
  }
}
