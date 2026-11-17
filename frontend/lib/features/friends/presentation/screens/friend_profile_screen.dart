import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/router/app_routes.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/presentation/overlay/app_overlay.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_status_view.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';
import 'package:skill_battles/core/utils/extensions/route_extension.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/rank_ladder_entity.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_disciplines_usecase.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_ranks_usecase.dart';
import 'package:skill_battles/features/catalog/presentation/extensions/catalog_labels.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_discipline_stats_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_profile_entity.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friend_profile_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/remove_friend_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/watch_friendship_changes_usecase.dart';
import 'package:skill_battles/features/friends/presentation/bloc/friend_profile_bloc/friend_profile_bloc.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friend_discipline_card.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friend_profile_header.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friends_skeleton_data.dart';
import 'package:skill_battles/features/friends/presentation/widgets/remove_friend_dialog.dart';

/// Catalogue names the cards need: disciplines and the rank ladder.
typedef _Catalog = ({List<DisciplineEntity> disciplines, RankLadderEntity? ranks});

/// A friend's public profile (Paper: "43 Friend profile — loaded", "44"
/// skeleton, "45" no longer friends, "46" load error).
final class FriendProfileScreen extends StatefulComponent implements RouteWrapper {
  const FriendProfileScreen({
    required this.friendId,
    this.relationshipId,
    super.key,
  });

  /// User id of the friend.
  final String friendId;

  /// Set when opened from the friends list.
  final String? relationshipId;

  @override
  Component wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocSignalProvider<FriendProfileBloc>(
      create: (_) => FriendProfileBloc(
        getFriendProfile: dependencies.getDep<GetFriendProfileUsecase>(),
        removeFriend: dependencies.getDep<RemoveFriendUsecase>(),
        watchFriendshipChanges: dependencies.getDep<WatchFriendshipChangesUsecase>(),
        watchConnection: dependencies.getDep<WatchConnectionUsecase>(),
      )..add(FriendProfileStarted(friendId: friendId, relationshipId: relationshipId)),
      child: this,
    );
  }

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

final class _FriendProfileScreenState extends State<FriendProfileScreen> {
  late final ValueNotifier<_Catalog> _catalog;
  late bool _isCatalogRequested;

  @override
  void initState() {
    super.initState();
    _catalog = ValueNotifier<_Catalog>((disciplines: const <DisciplineEntity>[], ranks: null));
    _isCatalogRequested = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isCatalogRequested) return;
    _isCatalogRequested = true;
    _loadCatalog(AppDependenciesProvider.of(context));
  }

  @override
  void dispose() {
    _catalog.dispose();
    super.dispose();
  }

  /// Display names only; a failure leaves the readable code fallbacks.
  Future<void> _loadCatalog(AppDependencies dependencies) async {
    final List<DisciplineEntity> disciplines = (await dependencies.getDep<GetDisciplinesUsecase>()(
      const NoParams(),
    )).getOrElse((_) => const <DisciplineEntity>[]);
    final RankLadderEntity? ranks = (await dependencies.getDep<GetRanksUsecase>()(const NoParams())).toNullable();
    if (!mounted) return;
    _catalog.value = (disciplines: disciplines, ranks: ranks);
  }

  @override
  Component build(BuildContext context) {
    return BlocSignalListener<FriendProfileBloc, FriendProfileState>(
      listenWhen: (FriendProfileState previous, FriendProfileState current) =>
          previous.removeStatus != current.removeStatus && current.removeStatus.isSuccess,
      listener: (BuildContext context, FriendProfileState state) {
        // After the dialog closes itself.
        context.binding.addPostFrameCallback(() {
          if (mounted) context.goNamed(AppRoutes.friends.name);
        });
      },
      child: AppDesktopViewport(
        child: div(classes: 'friend-profile-screen', <Component>[
          const _BackLink(),
          _Body(catalog: _catalog),
        ]),
      ),
    );
  }
}

final class _BackLink extends StatelessComponent {
  const _BackLink();

  @override
  Component build(BuildContext context) {
    return AppTappable(
      onTap: () => context.goNamed(AppRoutes.friends.name),
      radius: 4,
      semanticLabel: 'Back to Friends',
      classes: 'friend-profile-screen__back',
      child: Component.fragment(<Component>[
        const AppSvgIcon(AppIcons.chevronLeft, width: 16, height: 16),
        span(classes: 'friend-profile-screen__back-label', <Component>[Component.text('Friends')]),
      ]),
    );
  }
}

final class _Body extends StatelessComponent {
  const _Body({required this.catalog});

  final ValueNotifier<_Catalog> catalog;

  @override
  Component build(BuildContext context) {
    return BlocSignalBuilder<FriendProfileBloc, FriendProfileState>(
      buildWhen: (FriendProfileState previous, FriendProfileState current) =>
          previous.loadStatus != current.loadStatus ||
          previous.profile != current.profile ||
          previous.isNoLongerFriends != current.isNoLongerFriends,
      builder: (BuildContext context, FriendProfileState state) {
        if (state.isNoLongerFriends) {
          return div(classes: 'friend-profile-screen__status', <Component>[
            AppEmptyView(
              title: 'This profile is no longer available',
              message: 'You are no longer friends with this player.',
              action: AppButton(
                label: 'Back to Friends',
                variant: AppButtonVariant.outline,
                size: AppButtonSize.medium,
                onPressed: () => context.goNamed(AppRoutes.friends.name),
              ),
            ),
          ]);
        }
        final FriendProfileEntity? profile = state.profile;
        if (profile == null && state.loadStatus.isFailure) {
          return div(classes: 'friend-profile-screen__status', <Component>[
            AppErrorView(
              title: "Couldn't load this profile",
              message: 'Check your connection and try again.',
              onRetry: () => context.read<FriendProfileBloc>().add(const FriendProfileRefreshRequested()),
            ),
          ]);
        }
        return Skeletonizer(
          enabled: profile == null,
          child: _Content(
            profile: profile ?? FriendsSkeletonData.profile,
            catalog: catalog,
            onRemove: profile == null ? null : () => _confirmRemove(context),
          ),
        );
      },
    );
  }

  Future<void> _confirmRemove(BuildContext context) {
    final FriendProfileBloc bloc = context.read<FriendProfileBloc>();
    return showAppDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => BlocSignalProvider<FriendProfileBloc>.value(
        value: bloc,
        child: const _RemoveHost(),
      ),
    );
  }
}

final class _Content extends StatelessComponent {
  const _Content({
    required this.profile,
    required this.catalog,
    required this.onRemove,
  });

  final FriendProfileEntity profile;
  final ValueNotifier<_Catalog> catalog;
  final VoidCallback? onRemove;

  @override
  Component build(BuildContext context) {
    return div(classes: 'friend-profile-screen__content', <Component>[
      FriendProfileHeader(profile: profile, onRemove: onRemove ?? () {}),
      ValueListenableBuilder<_Catalog>(
        listenable: catalog,
        builder: (BuildContext context, _Catalog names) =>
            _DisciplineCards(disciplines: profile.disciplines, names: names),
      ),
    ]);
  }
}

final class _DisciplineCards extends StatelessComponent {
  const _DisciplineCards({required this.disciplines, required this.names});

  final List<FriendDisciplineStatsEntity> disciplines;
  final _Catalog names;

  @override
  Component build(BuildContext context) {
    // Two cards per row, equally tall; a third wraps. A single card takes the
    // whole row.
    return div(
      classes: disciplines.length == 1
          ? 'friend-profile-screen__cards friend-profile-screen__cards--single'
          : 'friend-profile-screen__cards',
      <Component>[
        for (final FriendDisciplineStatsEntity stats in disciplines)
          FriendDisciplineCard(
            stats: stats,
            disciplineName: names.disciplines.nameOf(stats.disciplineCode),
            allTimePeakRankName: names.ranks.nameOf(stats.allTimePeakRankCode),
            seasonPeakRankName: names.ranks.nameOf(stats.seasonPeakRankCode),
          ),
      ],
    );
  }
}

/// Binds [RemoveFriendDialog] to the removal state of the profile.
final class _RemoveHost extends StatelessComponent {
  const _RemoveHost();

  @override
  Component build(BuildContext context) {
    return BlocSignalConsumer<FriendProfileBloc, FriendProfileState>(
      listenWhen: (FriendProfileState previous, FriendProfileState current) =>
          previous.removeStatus != current.removeStatus && current.removeStatus.isSuccess,
      listener: (BuildContext context, FriendProfileState state) => closeAppDialog<void>(context),
      buildWhen: (FriendProfileState previous, FriendProfileState current) =>
          previous.removeStatus != current.removeStatus || previous.profile != current.profile,
      builder: (BuildContext context, FriendProfileState state) {
        final FriendProfileEntity? profile = state.profile;
        if (profile == null) return const Component.empty();
        return RemoveFriendDialog(
          nickname: profile.friend.nickname,
          friendsSince: profile.friendsSince,
          isRemoving: state.removeStatus.isLoading,
          hasFailed: state.removeStatus.isFailure,
          onConfirm: () => context.read<FriendProfileBloc>().add(const FriendProfileRemoveRequested()),
          onClose: () => closeAppDialog<void>(context),
        );
      },
    );
  }
}

@css
List<StyleRule> get friendProfileScreenStyles => <StyleRule>[
  css('.friend-profile-screen').styles(
    display: Display.flex,
    padding: const Padding.fromLTRB(Unit.pixels(64), Unit.pixels(24), Unit.pixels(64), Unit.pixels(64)),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(32)),
  ),
  css('.friend-profile-screen__back').styles(
    display: Display.flex,
    width: Unit.fitContent,
    height: const Unit.pixels(48),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(6)),
  ),
  css('.friend-profile-screen__back-label')
      .combine(AppTextStyles.buttonMd)
      .combine(const Styles(color: AppColors.muted)),
  css('.friend-profile-screen__status').styles(
    display: Display.flex,
    padding: const Padding.symmetric(vertical: Unit.pixels(72)),
  ),
  css('.friend-profile-screen__content').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(32)),
  ),
  css('.friend-profile-screen__cards').styles(
    display: Display.grid,
    gap: const Gap(row: Unit.pixels(24), column: Unit.pixels(24)),
    raw: const <String, String>{'grid-template-columns': 'repeat(2, minmax(0, 1fr))'},
  ),
  css('.friend-profile-screen__cards--single').styles(
    raw: const <String, String>{'grid-template-columns': 'minmax(0, 1fr)'},
  ),
];
