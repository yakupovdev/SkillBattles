part of 'ranked_search_bloc.dart';

sealed class RankedSearchEvent extends Equatable {
  const RankedSearchEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Joins in [disciplineCode], or resumes [entryId] after a reload.
final class RankedSearchStarted extends RankedSearchEvent {
  const RankedSearchStarted({this.disciplineCode, this.entryId});

  final String? disciplineCode;
  final String? entryId;

  @override
  List<Object?> get props => <Object?>[disciplineCode, entryId];
}

final class RankedSearchCancelRequested extends RankedSearchEvent {
  const RankedSearchCancelRequested();
}

final class _EntryReceived extends RankedSearchEvent {
  const _EntryReceived(this.entry);

  final QueueEntryEntity entry;

  @override
  List<Object?> get props => <Object?>[entry];
}

/// Poll / reconnect fallback for lost events.
final class _RefreshTick extends RankedSearchEvent {
  const _RefreshTick();
}

/// Loads the own ratings for the rating range.
final class _StatisticsRequested extends RankedSearchEvent {
  const _StatisticsRequested();
}
