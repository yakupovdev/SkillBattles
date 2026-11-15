import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/presentation/widgets/app_notice.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_code_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/send_friend_request_params_entity.dart';
import 'package:skill_battles/features/friends/presentation/bloc/friends_bloc/friends_bloc.dart';
import 'package:skill_battles/features/friends/presentation/controllers/friend_code_input.dart';
import 'package:skill_battles/features/friends/presentation/widgets/add_friend_form.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friend_code_card.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friends_skeleton_data.dart';

/// The own friend code, skeletonized while it loads.
final class FriendsCodeSection extends StatelessWidget {
  const FriendsCodeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendsBloc, FriendsState>(
      buildWhen: (FriendsState previous, FriendsState current) =>
          previous.codeStatus != current.codeStatus ||
          previous.code != current.code,
      builder: (BuildContext context, FriendsState state) {
        final FriendCodeEntity? code = state.code;
        return Skeletonizer(
          enabled: code == null && !state.codeStatus.isFailure,
          child: FriendCodeCard(
            code: code ?? FriendsSkeletonData.friendCode,
            hasFailed: code == null && state.codeStatus.isFailure,
            onRetry: () => context.read<FriendsBloc>().add(
              const FriendsRefreshRequested(),
            ),
          ),
        );
      },
    );
  }
}

/// The add-friend form wired to [FriendsBloc]. The screen owns the form key,
/// controller and focus node (forms.md); this widget owns the local
/// "server error dismissed by typing" flag and the rate-limit instant.
final class FriendsAddSection extends StatefulWidget {
  const FriendsAddSection({
    required this.formKey,
    required this.controller,
    required this.focusNode,
    required this.onShowIncoming,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final FocusNode focusNode;

  /// Switches the requests section to Incoming and scrolls to it.
  final VoidCallback onShowIncoming;

  @override
  State<FriendsAddSection> createState() => _FriendsAddSectionState();
}

final class _FriendsAddSectionState extends State<FriendsAddSection> {
  late bool _isErrorDismissed;
  late DateTime? _rateLimitedUntil;

  @override
  void initState() {
    super.initState();
    _isErrorDismissed = false;
    _rateLimitedUntil = null;
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(widget.formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isErrorDismissed = false;
      _rateLimitedUntil = null;
    });
    context.read<FriendsBloc>().add(
      FriendRequestSubmitted(
        SendFriendRequestParamsEntity(friendCode: widget.controller.text),
      ),
    );
  }

  void _onSendStatusChanged(BuildContext context, FriendsState state) {
    if (state.sendStatus.isSuccess) {
      widget.controller.clear();
      return;
    }
    final Failure? failure = state.sendFailure;
    if (failure is ApiFailure && failure.hasCode(ApiErrorCodes.rateLimited)) {
      final Duration? wait = failure.retryAfter;
      setState(() {
        _rateLimitedUntil = wait == null ? null : DateTime.now().add(wait);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FriendsBloc, FriendsState>(
      listenWhen: (FriendsState previous, FriendsState current) =>
          previous.sendStatus != current.sendStatus &&
          (current.sendStatus.isSuccess || current.sendStatus.isFailure),
      listener: _onSendStatusChanged,
      buildWhen: (FriendsState previous, FriendsState current) =>
          previous.sendStatus != current.sendStatus ||
          previous.sendFailure != current.sendFailure ||
          previous.sentRequest != current.sentRequest,
      builder: (BuildContext context, FriendsState state) {
        final Failure? failure = _isErrorDismissed ? null : state.sendFailure;
        final _SendOutcome outcome = _SendOutcome.of(
          state.sendStatus,
          failure,
          rateLimitedUntil: _rateLimitedUntil,
        );
        final RelationshipEntity? sent = state.sentRequest;
        return AddFriendForm(
          formKey: widget.formKey,
          controller: widget.controller,
          focusNode: widget.focusNode,
          onSubmit: _submit,
          isSending: state.sendStatus.isLoading,
          serverError: outcome.fieldError,
          rateLimitedUntil: _rateLimitedUntil,
          onRateLimitElapsed: () => setState(() {
            _rateLimitedUntil = null;
            _isErrorDismissed = true;
          }),
          failureMessage: outcome.message,
          notice: outcome.isAlreadyReceived
              ? AddFriendNotice(
                  message:
                      'This player already sent you a request. Accept it '
                      'under Incoming.',
                  actionLabel: 'Show',
                  onAction: widget.onShowIncoming,
                )
              : state.sendStatus.isSuccess && sent != null
              ? AddFriendNotice(
                  message:
                      'Request sent to ${sent.recipient.nickname}. '
                      "It's under Outgoing.",
                  tone: AppNoticeTone.success,
                )
              : null,
          onEdited: () => setState(() => _isErrorDismissed = true),
        );
      },
    );
  }
}

/// What a failed send looks like in the form.
final class _SendOutcome {
  const _SendOutcome({
    this.fieldError,
    this.message,
    this.isAlreadyReceived = false,
  });

  /// Shown through the field's `errorText`.
  final String? fieldError;

  /// Shown as an inline error under the field.
  final String? message;
  final bool isAlreadyReceived;

  factory _SendOutcome.of(
    LoadStatus status,
    Failure? failure, {
    required DateTime? rateLimitedUntil,
  }) {
    if (!status.isFailure || failure == null) return const _SendOutcome();
    if (failure is ValidationFailure) {
      return const _SendOutcome(fieldError: FriendCodeInput.invalidMessage);
    }
    if (failure is ApiFailure) {
      switch (failure.errorCode) {
        case ApiErrorCodes.validationError:
          return const _SendOutcome(fieldError: FriendCodeInput.invalidMessage);
        case ApiErrorCodes.friendCodeNotFound:
          return const _SendOutcome(
            fieldError:
                'No player has this friend code. Check it and try '
                'again.',
          );
        case ApiErrorCodes.selfFriendRequestNotAllowed:
          return const _SendOutcome(
            fieldError:
                "That's your own friend code. Share it with a friend instead.",
          );
        case ApiErrorCodes.friendAlreadyExists:
          return const _SendOutcome(
            fieldError: "You're already friends with this player.",
          );
        case ApiErrorCodes.friendRequestAlreadyReceived:
          return const _SendOutcome(isAlreadyReceived: true);
        case ApiErrorCodes.rateLimited:
          // With a Retry-After the field shows the countdown.
          return rateLimitedUntil != null
              ? const _SendOutcome()
              : const _SendOutcome(
                  message: 'Too many requests. Try again in a moment.',
                );
      }
    }
    return const _SendOutcome(
      message:
          "Couldn't send the request. Check your connection and try again.",
    );
  }
}

/// Copies the canonical friend code (the empty-state button).
Future<void> copyFriendCode(BuildContext context) async {
  final FriendCodeEntity? code = context.read<FriendsBloc>().state.code;
  if (code == null) return;
  await Clipboard.setData(ClipboardData(text: code.code));
}
