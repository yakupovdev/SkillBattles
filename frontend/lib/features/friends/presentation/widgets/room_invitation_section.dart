import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/router/app_routes.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/core/domain/usecases/generate_id_usecase.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_reason.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_status.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_list_item_entity.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friends_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_room_invitations_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/send_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/watch_duel_invitation_changes_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/withdraw_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/presentation/bloc/room_invitation_bloc/room_invitation_bloc.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friend_picker_dialog.dart';
import 'package:skill_battles/features/friends/presentation/widgets/host_invitation_panel.dart';
import 'package:skill_battles/features/friends/presentation/widgets/host_invitation_row.dart';

/// Provides [RoomInvitationBloc] for a waiting room of the host. The bloc is
/// keyed on the duel id, so a new room gets a new instance.
final class RoomInvitationScope extends StatelessWidget {
  const RoomInvitationScope({
    required this.duelId,
    required this.child,
    super.key,
  });

  final String duelId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<RoomInvitationBloc>(
      key: ValueKey<String>(duelId),
      create: (_) => RoomInvitationBloc(
        getRoomInvitations: dependencies.getDep<GetRoomInvitationsUsecase>(),
        getDuelInvitation: dependencies.getDep<GetDuelInvitationUsecase>(),
        sendDuelInvitation: dependencies.getDep<SendDuelInvitationUsecase>(),
        withdrawDuelInvitation: dependencies
            .getDep<WithdrawDuelInvitationUsecase>(),
        getFriends: dependencies.getDep<GetFriendsUsecase>(),
        watchDuelInvitationChanges: dependencies
            .getDep<WatchDuelInvitationChangesUsecase>(),
        watchConnection: dependencies.getDep<WatchConnectionUsecase>(),
        generateId: dependencies.getDep<GenerateIdUsecase>(),
      )..add(RoomInvitationStarted(duelId)),
      child: child,
    );
  }
}

/// The guest slot of the host's waiting room while an invitation is
/// pending; [fallback] (the empty waiting row) otherwise.
final class RoomGuestSlot extends StatelessWidget {
  const RoomGuestSlot({required this.fallback, super.key});

  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomInvitationBloc, RoomInvitationState>(
      buildWhen: (RoomInvitationState previous, RoomInvitationState current) =>
          previous.pendingInvitation != current.pendingInvitation ||
          previous.clockOffset != current.clockOffset,
      builder: (BuildContext context, RoomInvitationState state) {
        final DuelInvitationEntity? invitation = state.pendingInvitation;
        if (invitation == null) return fallback;
        return HostInvitationRow(
          invitation: invitation,
          clockOffset: state.clockOffset,
        );
      },
    );
  }
}

/// "Invite friend" / "Cancel invitation" with the outcome notices, and the
/// friend picker dialog.
final class RoomInvitationActions extends StatefulWidget {
  const RoomInvitationActions({required this.disciplineCode, super.key});

  final String disciplineCode;

  @override
  State<RoomInvitationActions> createState() => _RoomInvitationActionsState();
}

final class _RoomInvitationActionsState extends State<RoomInvitationActions> {
  late DateTime? _rateLimitedUntil;

  @override
  void initState() {
    super.initState();
    _rateLimitedUntil = null;
  }

  void _onSendFailure(BuildContext context, RoomInvitationState state) {
    final Failure? failure = state.sendFailure;
    if (failure is ApiFailure && failure.hasCode(ApiErrorCodes.rateLimited)) {
      final Duration wait = failure.retryAfter ?? const Duration(seconds: 60);
      setState(() => _rateLimitedUntil = DateTime.now().add(wait));
    }
  }

  void _openPicker(BuildContext context) {
    final RoomInvitationBloc bloc = context.read<RoomInvitationBloc>();
    bloc
      ..add(const RoomInvitationResultCleared())
      ..add(const RoomInvitationFriendsRequested());
    setState(() => _rateLimitedUntil = null);
    showDialog<void>(
      context: context,
      barrierColor: AppColors.scrim,
      builder: (BuildContext dialogContext) =>
          BlocProvider<RoomInvitationBloc>.value(
            value: bloc,
            child: _PickerHost(disciplineCode: widget.disciplineCode),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoomInvitationBloc, RoomInvitationState>(
      listenWhen: (RoomInvitationState previous, RoomInvitationState current) =>
          previous.sendFailure != current.sendFailure &&
          current.sendFailure != null,
      listener: _onSendFailure,
      buildWhen: (RoomInvitationState previous, RoomInvitationState current) =>
          previous.invitation != current.invitation ||
          previous.clockOffset != current.clockOffset ||
          previous.withdrawStatus != current.withdrawStatus ||
          previous.withdrawFailure != current.withdrawFailure ||
          previous.sendFailure != current.sendFailure,
      builder: (BuildContext context, RoomInvitationState state) {
        return HostInvitationPanel(
          hasPendingInvitation: state.pendingInvitation != null,
          isCancelling: state.withdrawStatus.isLoading,
          notice: _noticeOf(state.invitation),
          errorText: _errorOf(state),
          rateLimitedUntil: _rateLimitedUntil,
          clockOffset: state.clockOffset,
          onInvite: () => _openPicker(context),
          onCancelInvitation: () => context.read<RoomInvitationBloc>().add(
            const RoomInvitationWithdrawRequested(),
          ),
        );
      },
    );
  }

  /// The note for a finished invitation (sheet 37, states 2-4). Own
  /// withdrawals and room-level closings raise nothing.
  static HostInvitationNotice? _noticeOf(DuelInvitationEntity? invitation) {
    if (invitation == null) return null;
    return switch (invitation.status) {
      DuelInvitationStatus.declined => HostInvitationNotice.declined(
        invitation.recipient.nickname,
      ),
      DuelInvitationStatus.expired =>
        invitation.reason == DuelInvitationReason.duelExpired
            ? null
            : HostInvitationNotice.expired,
      DuelInvitationStatus.cancelled =>
        invitation.reason == DuelInvitationReason.friendRemoved
            ? HostInvitationNotice.friendRemoved
            : null,
      DuelInvitationStatus.pending || DuelInvitationStatus.accepted => null,
    };
  }

  static String? _errorOf(RoomInvitationState state) {
    final Failure? send = state.sendFailure;
    if (send is ApiFailure &&
        send.hasCode(ApiErrorCodes.duelInvitationAlreadyPending)) {
      return 'This room already has a pending invitation. Cancel it before '
          'inviting someone else.';
    }
    final Failure? withdraw = state.withdrawFailure;
    if (withdraw != null &&
        !withdraw.hasCode(ApiErrorCodes.matchAlreadyFound)) {
      return "Couldn't cancel the invitation. Try again.";
    }
    return null;
  }
}

/// Binds [FriendPickerDialog] to [RoomInvitationBloc] and closes it on the
/// outcomes the room card explains.
final class _PickerHost extends StatefulWidget {
  const _PickerHost({required this.disciplineCode});

  final String disciplineCode;

  @override
  State<_PickerHost> createState() => _PickerHostState();
}

final class _PickerHostState extends State<_PickerHost> {
  late String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = null;
  }

  /// Outcomes that close the dialog; the room card or its closed state tells
  /// the story.
  static bool _closesDialog(RoomInvitationState state) {
    if (state.sendStatus.isSuccess) return true;
    final Failure? failure = state.sendFailure;
    if (!state.sendStatus.isFailure || failure is! ApiFailure) return false;
    return const <String>{
      ApiErrorCodes.duelInvitationAlreadyPending,
      ApiErrorCodes.rateLimited,
      ApiErrorCodes.duelNotJoinable,
      ApiErrorCodes.duelExpired,
      ApiErrorCodes.duelNotFound,
    }.contains(failure.errorCode);
  }

  static String? _errorOf(RoomInvitationState state) {
    final Failure? failure = state.sendFailure;
    if (failure == null || !state.sendStatus.isFailure) return null;
    if (failure.hasCode(ApiErrorCodes.friendNotFound)) {
      return 'You are no longer friends with this player.';
    }
    return "Couldn't send the invitation. Try again.";
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoomInvitationBloc, RoomInvitationState>(
      listenWhen: (RoomInvitationState previous, RoomInvitationState current) =>
          previous.sendStatus != current.sendStatus && _closesDialog(current),
      listener: (BuildContext context, RoomInvitationState state) =>
          Navigator.of(context).pop(),
      builder: (BuildContext context, RoomInvitationState state) {
        final bool isRemovedFriend =
            state.sendFailure?.hasCode(ApiErrorCodes.friendNotFound) ?? false;
        final bool hasSelection =
            _selectedId != null &&
            !isRemovedFriend &&
            state.friends.any(
              (FriendListItemEntity f) => f.friend.id == _selectedId,
            );
        return FriendPickerDialog(
          disciplineName: formatDisciplineCode(widget.disciplineCode),
          status: switch (state.friendsStatus) {
            LoadStatus.failure when state.friends.isEmpty =>
              FriendPickerStatus.failed,
            LoadStatus.initial || LoadStatus.loading
                when state.friends.isEmpty =>
              FriendPickerStatus.loading,
            _ => FriendPickerStatus.ready,
          },
          friends: state.friends,
          page: state.friendsPage,
          selectedFriendId: hasSelection ? _selectedId : null,
          isSending: state.sendStatus.isLoading,
          isChangingPage: state.friendsPageStatus.isLoading,
          errorText: _errorOf(state),
          onSelected: (String id) => setState(() => _selectedId = id),
          onSend: () {
            final String? id = _selectedId;
            if (id == null) return;
            context.read<RoomInvitationBloc>().add(
              RoomInvitationSendRequested(id),
            );
          },
          onClose: () => Navigator.of(context).pop(),
          onRetry: () => context.read<RoomInvitationBloc>().add(
            const RoomInvitationFriendsRequested(),
          ),
          onPageSelected: (int page) => context.read<RoomInvitationBloc>().add(
            RoomInvitationFriendsPageRequested(page),
          ),
          onAddFriends: () {
            Navigator.of(context).pop();
            context.goNamed(AppRoutes.friends.name);
          },
        );
      },
    );
  }
}
