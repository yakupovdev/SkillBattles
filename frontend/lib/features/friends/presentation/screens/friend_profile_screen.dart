import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/router/app_routes.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_status_view.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';
import 'package:skill_battles/core/utils/extensions/go_router_extension.dart';
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
typedef _Catalog = ({
  List<DisciplineEntity> disciplines,
  RankLadderEntity? ranks,
});

/// A friend's public profile (Paper: "43 Friend profile — loaded", "44"
/// skeleton, "45" no longer friends, "46" load error).
final class FriendProfileScreen extends StatefulWidget
    implements GoRouterWrapper {
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
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<FriendProfileBloc>(
      create: (_) =>
          FriendProfileBloc(
            getFriendProfile: dependencies.getDep<GetFriendProfileUsecase>(),
            removeFriend: dependencies.getDep<RemoveFriendUsecase>(),
            watchFriendshipChanges: dependencies
                .getDep<WatchFriendshipChangesUsecase>(),
            watchConnection: dependencies.getDep<WatchConnectionUsecase>(),
          )..add(
            FriendProfileStarted(
              friendId: friendId,
              relationshipId: relationshipId,
            ),
          ),
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
    _catalog = ValueNotifier<_Catalog>((
      disciplines: const <DisciplineEntity>[],
      ranks: null,
    ));
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
    final List<DisciplineEntity> disciplines =
        (await dependencies.getDep<GetDisciplinesUsecase>()(const NoParams()))
            .getOrElse((_) => const <DisciplineEntity>[]);
    final RankLadderEntity? ranks =
        (await dependencies.getDep<GetRanksUsecase>()(const NoParams()))
            .toNullable();
    if (!mounted) return;
    _catalog.value = (disciplines: disciplines, ranks: ranks);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FriendProfileBloc, FriendProfileState>(
      listenWhen: (FriendProfileState previous, FriendProfileState current) =>
          previous.removeStatus != current.removeStatus &&
          current.removeStatus.isSuccess,
      listener: (BuildContext context, FriendProfileState state) {
        // After the dialog closes itself.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.goNamed(AppRoutes.friends.name);
        });
      },
      child: AppDesktopViewport(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(64, 24, 64, 64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 32,
            children: <Widget>[
              const _BackLink(),
              _Body(catalog: _catalog),
            ],
          ),
        ),
      ),
    );
  }
}

final class _BackLink extends StatelessWidget {
  const _BackLink();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: AppTappable(
        onTap: () => context.goNamed(AppRoutes.friends.name),
        borderRadius: BorderRadius.circular(4),
        semanticLabel: 'Back to Friends',
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: <Widget>[
              const AppSvgIcon(AppIcons.chevronLeft, width: 16, height: 16),
              Text(
                'Friends',
                style: AppTextStyles.buttonMd.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _Body extends StatelessWidget {
  const _Body({required this.catalog});

  final ValueNotifier<_Catalog> catalog;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendProfileBloc, FriendProfileState>(
      buildWhen: (FriendProfileState previous, FriendProfileState current) =>
          previous.loadStatus != current.loadStatus ||
          previous.profile != current.profile ||
          previous.isNoLongerFriends != current.isNoLongerFriends,
      builder: (BuildContext context, FriendProfileState state) {
        if (state.isNoLongerFriends) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 72),
            child: AppEmptyView(
              title: 'This profile is no longer available',
              message: 'You are no longer friends with this player.',
              action: AppButton(
                label: 'Back to Friends',
                variant: AppButtonVariant.outline,
                size: AppButtonSize.medium,
                onPressed: () => context.goNamed(AppRoutes.friends.name),
              ),
            ),
          );
        }
        final FriendProfileEntity? profile = state.profile;
        if (profile == null && state.loadStatus.isFailure) {
          return AppErrorView(
            title: "Couldn't load this profile",
            message: 'Check your connection and try again.',
            onRetry: () => context.read<FriendProfileBloc>().add(
              const FriendProfileRefreshRequested(),
            ),
          );
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
    return showDialog<void>(
      context: context,
      barrierColor: AppColors.scrim,
      builder: (BuildContext dialogContext) =>
          BlocProvider<FriendProfileBloc>.value(
            value: bloc,
            child: const _RemoveHost(),
          ),
    );
  }
}

final class _Content extends StatelessWidget {
  const _Content({
    required this.profile,
    required this.catalog,
    required this.onRemove,
  });

  final FriendProfileEntity profile;
  final ValueNotifier<_Catalog> catalog;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 32,
      children: <Widget>[
        FriendProfileHeader(profile: profile, onRemove: onRemove ?? () {}),
        ValueListenableBuilder<_Catalog>(
          valueListenable: catalog,
          builder: (BuildContext context, _Catalog names, _) =>
              _DisciplineCards(disciplines: profile.disciplines, names: names),
        ),
      ],
    );
  }
}

final class _DisciplineCards extends StatelessWidget {
  const _DisciplineCards({required this.disciplines, required this.names});

  final List<FriendDisciplineStatsEntity> disciplines;
  final _Catalog names;

  @override
  Widget build(BuildContext context) {
    // Two cards per row, equally tall; a third wraps.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: <Widget>[
        for (int i = 0; i < disciplines.length; i += 2)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 24,
              children: <Widget>[
                for (final FriendDisciplineStatsEntity stats
                    in disciplines.skip(i).take(2))
                  Expanded(
                    child: FriendDisciplineCard(
                      stats: stats,
                      disciplineName: names.disciplines.nameOf(
                        stats.disciplineCode,
                      ),
                      allTimePeakRankName: names.ranks.nameOf(
                        stats.allTimePeakRankCode,
                      ),
                      seasonPeakRankName: names.ranks.nameOf(
                        stats.seasonPeakRankCode,
                      ),
                    ),
                  ),
                if (i + 1 >= disciplines.length && disciplines.length > 1)
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
      ],
    );
  }
}

/// Binds [RemoveFriendDialog] to the removal state of the profile.
final class _RemoveHost extends StatelessWidget {
  const _RemoveHost();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FriendProfileBloc, FriendProfileState>(
      listenWhen: (FriendProfileState previous, FriendProfileState current) =>
          previous.removeStatus != current.removeStatus &&
          current.removeStatus.isSuccess,
      listener: (BuildContext context, FriendProfileState state) =>
          Navigator.of(context).pop(),
      buildWhen: (FriendProfileState previous, FriendProfileState current) =>
          previous.removeStatus != current.removeStatus ||
          previous.profile != current.profile,
      builder: (BuildContext context, FriendProfileState state) {
        final FriendProfileEntity? profile = state.profile;
        if (profile == null) return const SizedBox.shrink();
        return RemoveFriendDialog(
          nickname: profile.friend.nickname,
          friendsSince: profile.friendsSince,
          isRemoving: state.removeStatus.isLoading,
          hasFailed: state.removeStatus.isFailure,
          onConfirm: () => context.read<FriendProfileBloc>().add(
            const FriendProfileRemoveRequested(),
          ),
          onClose: () => Navigator.of(context).pop(),
        );
      },
    );
  }
}
