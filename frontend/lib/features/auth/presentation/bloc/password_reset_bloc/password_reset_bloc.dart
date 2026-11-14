import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/auth/domain/entity/password_reset_confirm_params_entity.dart';
import 'package:skill_battles/features/auth/domain/entity/password_reset_request_params_entity.dart';
import 'package:skill_battles/features/auth/domain/usecases/confirm_password_reset_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/request_password_reset_usecase.dart';

part 'password_reset_event.dart';
part 'password_reset_state.dart';

/// "Forgot password" (generic answer for any email) and the one-use token
/// confirmation of the reset link.
final class PasswordResetBloc
    extends Bloc<PasswordResetEvent, PasswordResetState> {
  PasswordResetBloc({required this._requestReset, required this._confirmReset})
    : super(const PasswordResetState()) {
    on<PasswordResetRequested>(_onRequested, transformer: droppable());
    on<PasswordResetConfirmed>(_onConfirmed, transformer: droppable());
  }

  final RequestPasswordResetUsecase _requestReset;
  final ConfirmPasswordResetUsecase _confirmReset;

  Future<void> _onRequested(
    PasswordResetRequested event,
    Emitter<PasswordResetState> emit,
  ) async {
    emit(state.copyWith(status: LoadStatus.loading, resetFailure: true));
    final Either<Failure, String> result = await _requestReset(event.params);
    if (emit.isDone) return;
    result.match(
      (Failure failure) =>
          emit(state.copyWith(status: LoadStatus.failure, failure: failure)),
      (String message) =>
          emit(state.copyWith(status: LoadStatus.success, message: message)),
    );
  }

  Future<void> _onConfirmed(
    PasswordResetConfirmed event,
    Emitter<PasswordResetState> emit,
  ) async {
    emit(state.copyWith(status: LoadStatus.loading, resetFailure: true));
    final Either<Failure, Unit> result = await _confirmReset(event.params);
    if (emit.isDone) return;
    result.match(
      (Failure failure) =>
          emit(state.copyWith(status: LoadStatus.failure, failure: failure)),
      (_) => emit(state.copyWith(status: LoadStatus.success)),
    );
  }
}
