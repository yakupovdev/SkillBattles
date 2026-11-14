import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/account/domain/entity/update_profile_params_entity.dart';
import 'package:skill_battles/features/account/domain/entity/update_profile_result_entity.dart';
import 'package:skill_battles/features/account/domain/usecases/update_profile_usecase.dart';

part 'edit_profile_event.dart';
part 'edit_profile_state.dart';

/// Nickname and password forms. A password change clears the session.
final class EditProfileBloc extends Bloc<EditProfileEvent, EditProfileState> {
  EditProfileBloc({required this._updateProfile})
    : super(const EditProfileState()) {
    on<EditProfileNicknameSubmitted>(_onNickname, transformer: droppable());
    on<EditProfilePasswordSubmitted>(_onPassword, transformer: droppable());
  }

  final UpdateProfileUsecase _updateProfile;

  Future<void> _onNickname(
    EditProfileNicknameSubmitted event,
    Emitter<EditProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        nicknameStatus: LoadStatus.loading,
        resetNicknameFailure: true,
      ),
    );
    final Either<Failure, UpdateProfileResultEntity> result =
        await _updateProfile(event.params);
    if (emit.isDone) return;
    result.match(
      (Failure failure) => emit(
        state.copyWith(
          nicknameStatus: LoadStatus.failure,
          nicknameFailure: failure,
        ),
      ),
      (UpdateProfileResultEntity value) => emit(
        state.copyWith(nicknameStatus: LoadStatus.success, result: value),
      ),
    );
  }

  Future<void> _onPassword(
    EditProfilePasswordSubmitted event,
    Emitter<EditProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        passwordStatus: LoadStatus.loading,
        resetPasswordFailure: true,
      ),
    );
    final Either<Failure, UpdateProfileResultEntity> result =
        await _updateProfile(event.params);
    if (emit.isDone) return;
    result.match(
      (Failure failure) => emit(
        state.copyWith(
          passwordStatus: LoadStatus.failure,
          passwordFailure: failure,
        ),
      ),
      (UpdateProfileResultEntity value) => emit(
        state.copyWith(passwordStatus: LoadStatus.success, result: value),
      ),
    );
  }
}
