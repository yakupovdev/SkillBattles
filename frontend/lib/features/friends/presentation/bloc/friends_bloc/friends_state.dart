part of 'friends_bloc.dart';

/// The three paged lists of the Friends screen.
enum FriendsList { friends, incoming, outgoing }

/// One server-paged list shown one page at a time (Previous / Next and
/// page numbers). [loadStatus] drives the first load and refreshes of the
/// current page (skeleton only while [items] is empty, error view);
/// [pageStatus] drives a page change, so the current page stays visible
/// while the next one loads.
final class FriendsListSlice<T> extends Equatable {
  const FriendsListSlice({
    this.loadStatus = LoadStatus.initial,
    this.items = const <Never>[],
    this.page,
    this.failure,
    this.pageStatus = LoadStatus.initial,
    this.pageFailure,
  });

  final LoadStatus loadStatus;

  /// Items of the current page only.
  final List<T> items;

  /// Metadata of the shown page (zero-based `page`, `totalPages`);
  /// `null` before the first success.
  final PageInfoEntity? page;
  final Failure? failure;

  /// Status of the last page change ([FriendsPageRequested]).
  final LoadStatus pageStatus;
  final Failure? pageFailure;

  bool get hasPrevious => page?.hasPrevious ?? false;
  bool get hasNext => page?.hasNext ?? false;

  /// Server total at the last read (a snapshot; refetched on change).
  int get totalElements => page?.totalElements ?? 0;

  FriendsListSlice<T> copyWith({
    LoadStatus? loadStatus,
    List<T>? items,
    PageInfoEntity? page,
    Failure? failure,
    LoadStatus? pageStatus,
    Failure? pageFailure,
    bool resetFailure = false,
    bool resetPageFailure = false,
  }) {
    return FriendsListSlice<T>(
      loadStatus: loadStatus ?? this.loadStatus,
      items: items ?? this.items,
      page: page ?? this.page,
      failure: resetFailure ? null : failure ?? this.failure,
      pageStatus: pageStatus ?? this.pageStatus,
      pageFailure: resetPageFailure ? null : pageFailure ?? this.pageFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loadStatus,
    items,
    page,
    failure,
    pageStatus,
    pageFailure,
  ];
}

/// Per-item command state: `loading` while running, `success` until the
/// refetched list drops the item, `failure` with [failure].
final class FriendsItemAction extends Equatable {
  const FriendsItemAction({required this.status, this.failure});

  final LoadStatus status;
  final Failure? failure;

  @override
  List<Object?> get props => <Object?>[status, failure];
}

final class FriendsState extends Equatable {
  const FriendsState({
    this.codeStatus = LoadStatus.initial,
    this.code,
    this.codeFailure,
    this.friends = const FriendsListSlice<FriendListItemEntity>(),
    this.incoming = const FriendsListSlice<RelationshipEntity>(),
    this.outgoing = const FriendsListSlice<RelationshipEntity>(),
    this.sendStatus = LoadStatus.initial,
    this.sendFailure,
    this.sentRequest,
    this.requestActions = const <String, FriendsItemAction>{},
    this.friendActions = const <String, FriendsItemAction>{},
  });

  final LoadStatus codeStatus;
  final FriendCodeEntity? code;
  final Failure? codeFailure;

  final FriendsListSlice<FriendListItemEntity> friends;

  /// Incoming PENDING requests (Accept / Decline).
  final FriendsListSlice<RelationshipEntity> incoming;

  /// Own outgoing PENDING requests (Cancel).
  final FriendsListSlice<RelationshipEntity> outgoing;

  /// Add-friend submit. `success` stays until the next submit.
  final LoadStatus sendStatus;
  final Failure? sendFailure;

  /// The request created or found by the last successful submit.
  final RelationshipEntity? sentRequest;

  /// requestId → Accept / Decline / Cancel state.
  final Map<String, FriendsItemAction> requestActions;

  /// friendId (USER id) → Remove state.
  final Map<String, FriendsItemAction> friendActions;

  FriendsListSlice<Object> slice(FriendsList list) => switch (list) {
    FriendsList.friends => friends,
    FriendsList.incoming => incoming,
    FriendsList.outgoing => outgoing,
  };

  FriendsState copyWith({
    LoadStatus? codeStatus,
    FriendCodeEntity? code,
    Failure? codeFailure,
    FriendsListSlice<FriendListItemEntity>? friends,
    FriendsListSlice<RelationshipEntity>? incoming,
    FriendsListSlice<RelationshipEntity>? outgoing,
    LoadStatus? sendStatus,
    Failure? sendFailure,
    RelationshipEntity? sentRequest,
    Map<String, FriendsItemAction>? requestActions,
    Map<String, FriendsItemAction>? friendActions,
    bool resetCodeFailure = false,
    bool resetSendFailure = false,
    bool resetSentRequest = false,
  }) {
    return FriendsState(
      codeStatus: codeStatus ?? this.codeStatus,
      code: code ?? this.code,
      codeFailure: resetCodeFailure ? null : codeFailure ?? this.codeFailure,
      friends: friends ?? this.friends,
      incoming: incoming ?? this.incoming,
      outgoing: outgoing ?? this.outgoing,
      sendStatus: sendStatus ?? this.sendStatus,
      sendFailure: resetSendFailure ? null : sendFailure ?? this.sendFailure,
      sentRequest: resetSentRequest ? null : sentRequest ?? this.sentRequest,
      requestActions: requestActions ?? this.requestActions,
      friendActions: friendActions ?? this.friendActions,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    codeStatus,
    code,
    codeFailure,
    friends,
    incoming,
    outgoing,
    sendStatus,
    sendFailure,
    sentRequest,
    requestActions,
    friendActions,
  ];
}
