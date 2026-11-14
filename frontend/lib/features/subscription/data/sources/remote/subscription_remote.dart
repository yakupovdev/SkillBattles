import 'package:skill_battles/core/data/models/subscription_model.dart';
import 'package:skill_battles/core/utils/network/api_client.dart';
import 'package:skill_battles/core/utils/network/app_api.dart';
import 'package:skill_battles/core/utils/network/json_object.dart';
import 'package:skill_battles/features/subscription/data/models/checkout_model.dart';
import 'package:skill_battles/features/subscription/data/models/checkout_request_model.dart';
import 'package:skill_battles/features/subscription/data/models/portal_model.dart';
import 'package:skill_battles/features/subscription/data/models/subscription_plan_model.dart';

/// The Stripe webhook is server-to-server and has no client counterpart.
abstract interface class SubscriptionRemote {
  Future<List<SubscriptionPlanModel>> getPlans();

  Future<SubscriptionModel> getMySubscription();

  Future<CheckoutModel> createCheckout(CheckoutRequestModel request);

  Future<PortalModel> createPortal();
}

final class SubscriptionRemoteImpl implements SubscriptionRemote {
  const SubscriptionRemoteImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<SubscriptionPlanModel>> getPlans() async {
    final Object? json = await _client.get(AppApi.subscriptionPlans);
    return asJsonObjectList(json)
        .map(SubscriptionPlanModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<SubscriptionModel> getMySubscription() async {
    final Object? json = await _client.get(AppApi.subscriptionMe);
    return SubscriptionModel.fromJson(asJsonObject(json));
  }

  @override
  Future<CheckoutModel> createCheckout(CheckoutRequestModel request) async {
    final Object? json = await _client.post(
      AppApi.subscriptionCheckout,
      data: request.toJson(),
    );
    return CheckoutModel.fromJson(asJsonObject(json));
  }

  @override
  Future<PortalModel> createPortal() async {
    final Object? json = await _client.post(AppApi.subscriptionPortal);
    return PortalModel.fromJson(asJsonObject(json));
  }
}
