import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/user_entity.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/presentation/bloc/signal_bloc.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/auth/domain/entity/age_check_params_entity.dart';
import 'package:skill_battles/features/auth/domain/entity/age_check_result.dart';
import 'package:skill_battles/features/auth/domain/entity/login_params_entity.dart';
import 'package:skill_battles/features/auth/domain/entity/register_params_entity.dart';
import 'package:skill_battles/features/auth/domain/usecases/check_age_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/login_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/register_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Age screen, sign-up and log-in. A successful submit signs the session
/// in; the router then leaves the auth screen.
final class AuthBloc extends SignalBloc<AuthEvent, AuthState> {
  AuthBloc({
    required this._checkAge,
    required this._register,
    required this._login,
  }) : super(const AuthState()) {
    handle<AuthAgeSubmitted>(_onAgeSubmitted);
    handle<AuthAgeEdited>(_onAgeEdited);
    handle<AuthRegisterSubmitted>(_onRegisterSubmitted, transformer: droppable());
    handle<AuthLoginSubmitted>(_onLoginSubmitted, transformer: droppable());
    handle<AuthFieldEdited>(_onFieldEdited);
  }

  final CheckAgeUsecase _checkAge;
  final RegisterUsecase _register;
  final LoginUsecase _login;

  void _onAgeSubmitted(AuthAgeSubmitted event, Emitter<AuthState> emit) {
    emit(
      stateValue.copyWith(
        ageResult: _checkAge(event.params),
        resetFailure: true,
        submitStatus: LoadStatus.initial,
      ),
    );
  }

  void _onAgeEdited(AuthAgeEdited event, Emitter<AuthState> emit) {
    if (stateValue.ageResult == null) return;
    // Keep "needs day" so the day field stays visible while editing it.
    emit(
      stateValue.copyWith(
        resetAgeResult: stateValue.ageResult != AgeCheckResult.needsDay,
        resetFailure: true,
      ),
    );
  }

  Future<void> _onRegisterSubmitted(
    AuthRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(stateValue.copyWith(submitStatus: LoadStatus.loading, resetFailure: true));
    final Either<Failure, UserEntity> result = await _register(event.params);
    if (emit.isDone) return;
    result.match((Failure failure) {
      // The server's age decision wins over the client pre-check.
      if (failure.hasCode(ApiErrorCodes.ageRestricted)) {
        emit(
          stateValue.copyWith(
            submitStatus: LoadStatus.failure,
            ageResult: AgeCheckResult.restricted,
            failure: failure,
          ),
        );
        return;
      }
      final bool needsDay = switch (failure) {
        ApiFailure(:final Map<String, String> fieldErrors) ||
        ValidationFailure(
          :final Map<String, String> fieldErrors,
        ) => fieldErrors.containsKey(ApiErrorCodes.birthDayField),
        _ => false,
      };
      emit(
        stateValue.copyWith(
          submitStatus: LoadStatus.failure,
          ageResult: needsDay ? AgeCheckResult.needsDay : null,
          failure: failure,
        ),
      );
    }, (_) => emit(stateValue.copyWith(submitStatus: LoadStatus.success)));
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(stateValue.copyWith(submitStatus: LoadStatus.loading, resetFailure: true));
    final Either<Failure, UserEntity> result = await _login(event.params);
    if (emit.isDone) return;
    result.match(
      (Failure failure) => emit(
        stateValue.copyWith(submitStatus: LoadStatus.failure, failure: failure),
      ),
      (_) => emit(stateValue.copyWith(submitStatus: LoadStatus.success)),
    );
  }

  void _onFieldEdited(AuthFieldEdited event, Emitter<AuthState> emit) {
    if (stateValue.failure == null) return;
    emit(stateValue.copyWith(resetFailure: true));
  }
}
