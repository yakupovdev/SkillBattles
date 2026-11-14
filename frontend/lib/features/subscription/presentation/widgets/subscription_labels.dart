import 'package:skill_battles/core/domain/entity/plan_code.dart';
import 'package:skill_battles/core/domain/entity/subscription_status.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';

extension PlanCodeLabel on PlanCode {
  String get label => switch (this) {
    PlanCode.free => 'Free',
    PlanCode.proMonthly => 'Pro Monthly',
    PlanCode.proAnnual => 'Pro Annual',
  };
}

extension SubscriptionStatusLabel on SubscriptionStatus {
  String get label => switch (this) {
    SubscriptionStatus.none => 'No subscription',
    SubscriptionStatus.incomplete => 'Payment not completed',
    SubscriptionStatus.active => 'Active',
    SubscriptionStatus.pastDue => 'Payment past due',
    SubscriptionStatus.canceled => 'Cancelled',
    SubscriptionStatus.unpaid => 'Unpaid',
    SubscriptionStatus.expired => 'Expired',
  };
}

extension BillingFailureMessage on Failure {
  String get billingMessage {
    if (hasCode(ApiErrorCodes.checkoutInProgress)) {
      return 'A checkout is already open for this account. Finish it in the '
          'other tab, or wait until it expires.';
    }
    if (hasCode(ApiErrorCodes.subscriptionAlreadyActive)) {
      return 'Pro is already active on this account.';
    }
    if (hasCode(ApiErrorCodes.billingUnavailable)) {
      return 'Test billing is not available right now. Try again later.';
    }
    if (hasCode(ApiErrorCodes.billingCustomerNotFound)) {
      return 'There is no billing profile for this account yet.';
    }
    return userMessage;
  }
}
