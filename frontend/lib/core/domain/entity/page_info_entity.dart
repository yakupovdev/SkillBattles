import 'package:equatable/equatable.dart';

/// Metadata of one server page (zero-based [page]).
final class PageInfoEntity extends Equatable {
  const PageInfoEntity({
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  bool get hasPrevious => page > 0;
  bool get hasNext => page + 1 < totalPages;

  @override
  List<Object?> get props => <Object?>[page, size, totalElements, totalPages];
}
