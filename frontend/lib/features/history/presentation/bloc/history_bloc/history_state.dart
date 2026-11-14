part of 'history_bloc.dart';

final class HistoryState extends Equatable {
  const HistoryState({
    this.loadStatus = LoadStatus.initial,
    this.page,
    this.failure,
    this.disciplines = const <DisciplineEntity>[],
    this.params = const HistoryParamsEntity(size: HistoryBloc.pageSize),
  });

  final LoadStatus loadStatus;

  /// The page answering [params]; an older page while a new one loads.
  final HistoryPageEntity? page;
  final Failure? failure;
  final List<DisciplineEntity> disciplines;
  final HistoryParamsEntity params;

  HistoryState copyWith({
    LoadStatus? loadStatus,
    HistoryPageEntity? page,
    Failure? failure,
    List<DisciplineEntity>? disciplines,
    HistoryParamsEntity? params,
    bool resetFailure = false,
  }) {
    return HistoryState(
      loadStatus: loadStatus ?? this.loadStatus,
      page: page ?? this.page,
      failure: resetFailure ? null : failure ?? this.failure,
      disciplines: disciplines ?? this.disciplines,
      params: params ?? this.params,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loadStatus,
    page,
    failure,
    disciplines,
    params,
  ];
}
