import 'package:equatable/equatable.dart';

/// Stripe-hosted test Checkout. Opening it grants nothing: only the
/// verified subscription status does.
final class CheckoutEntity extends Equatable {
  const CheckoutEntity({
    required this.sessionId,
    required this.url,
    required this.expiresAt,
  });

  final String sessionId;
  final String url;
  final DateTime expiresAt;

  // The URL is not logged.
  @override
  String toString() => 'CheckoutEntity($sessionId)';

  @override
  List<Object?> get props => <Object?>[sessionId, url, expiresAt];
}
