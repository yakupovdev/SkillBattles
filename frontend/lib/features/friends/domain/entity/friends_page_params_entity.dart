import 'package:equatable/equatable.dart';

/// Zero-based page of accepted friends; [size] is 1..100.
final class FriendsPageParamsEntity extends Equatable {
  const FriendsPageParamsEntity({this.page = 0, this.size = 20});

  final int page;
  final int size;

  @override
  List<Object?> get props => <Object?>[page, size];
}
