import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/presentation/bloc/signal_bloc.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/account/domain/entity/update_profile_params_entity.dart';
import 'package:skill_battles/features/account/domain/entity/update_profile_result_entity.dart';
import 'package:skill_battles/features/account/domain/usecases/update_profile_usecase.dart';

part 'edit_profile_event.dart';
part 'edit_profile_state.dart';

/// Nickname and password forms. A password change clears the session.
final class EditProfileBloc extends SignalBloc<EditProfileEvent, EditProfileState> {
  EditProfileBloc({required this._updateProfile})
    : super(const EditProfileState()) {
    handle<EditProfileNicknameSubmitted>(_onNickname, transformer: droppable());
    handle<EditProfilePasswordSubmitted>(_onPassword, transformer: droppable());
  }

  final UpdateProfileUsecase _updateProfile;

  Future<void> _onNickname(
    EditProfileNicknameSubmitted event,
    Emitter<EditProfileState> emit,
  ) async {
    emit(
      stateValue.copyWith(
        nicknameStatus: LoadStatus.loading,
        resetNicknameFailure: true,
      ),
    );
    final Either<Failure, UpdateProfileResultEntity> result =
        await _updateProfile(event.params);
    if (emit.isDone) return;
    result.match(
      (Failure failure) => emit(
        stateValue.copyWith(
          nicknameStatus: LoadStatus.failure,
          nicknameFailure: failure,
        ),
      ),
      (UpdateProfileResultEntity value) => emit(
        stateValue.copyWith(nicknameStatus: LoadStatus.success, result: value),
      ),
    );
  }

  Future<void> _onPassword(
    EditProfilePasswordSubmitted event,
    Emitter<EditProfileState> emit,
  ) async {
    emit(
      stateValue.copyWith(
        passwordStatus: LoadStatus.loading,
        resetPasswordFailure: true,
      ),
    );
    final Either<Failure, UpdateProfileResultEntity> result =
        await _updateProfile(event.params);
    if (emit.isDone) return;
    result.match(
      (Failure failure) => emit(
        stateValue.copyWith(
          passwordStatus: LoadStatus.failure,
          passwordFailure: failure,
        ),
      ),
      (UpdateProfileResultEntity value) => emit(
        stateValue.copyWith(passwordStatus: LoadStatus.success, result: value),
      ),
    );
  }
}
