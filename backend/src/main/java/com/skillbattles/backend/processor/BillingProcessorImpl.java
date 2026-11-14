package com.skillbattles.backend.processor;
import com.skillbattles.backend.client.StripeBillingClient;
import com.skillbattles.backend.config.BillingProperties;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.exception.*;
import com.skillbattles.backend.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import java.util.*;
import java.util.concurrent.locks.ReentrantLock;
/** The MVP serializes billing network operations without holding a DB transaction across HTTP. */
@Component @RequiredArgsConstructor
public class BillingProcessorImpl implements BillingProcessor {
    private final SubscriptionService subscriptions;private final UserService users;private final StripeBillingClient stripe;
    private final StripeWebhookService signatures;private final BillingProperties properties;
    private final ReentrantLock lock=new ReentrantLock(true);
    private void available(){if(!stripe.available())throw new BillingUnavailableException();}
    @Override public List<SubscriptionPlanDto> plans() {return List.of(
        new SubscriptionPlanDto("FREE","Free",0,"USD","NONE",0,0,0,false,List.of("5 ranked matches per ET day","Latest 10 matches","Basic statistics")),
        new SubscriptionPlanDto("PRO_MONTHLY","SkillBattles Pro Monthly",799,"USD","MONTH",1,799,0,stripe.available(),List.of("Unlimited ranked matches","Full history","Answer explanations")),
        new SubscriptionPlanDto("PRO_ANNUAL","SkillBattles Pro Annual",4799,"USD","YEAR",1,400,50,stripe.available(),List.of("Unlimited ranked matches","Full history","Answer explanations")));}
    @Override public SubscriptionDto current(UUID user){users.getById(user);return subscriptions.current(user);}
    @Override public CheckoutDto checkout(UUID user,String plan,UUID requestId) {
        users.getById(user);available();if(!Set.of("PRO_MONTHLY","PRO_ANNUAL").contains(plan)||requestId==null) throw new BusinessValidationException("VALIDATION_ERROR","A paid plan and requestId are required.");
        lock.lock();try {
            var intent=subscriptions.reserve(user,plan,requestId);if(intent.getCheckout()!=null)return intent.getCheckout();
            var a=subscriptions.account(user);String customer=a.getCustomerId();
            if(customer==null){customer=stripe.customer(user);subscriptions.bindCustomer(user,customer);}
            if(stripe.hasSubscription(customer)) throw new ConflictException("SUBSCRIPTION_ALREADY_ACTIVE","Manage the existing subscription in the portal.");
            var checkout=stripe.checkout(user,customer,plan,requestId);subscriptions.checkoutCreated(user,requestId,checkout);return checkout;
        }finally{lock.unlock();}
    }
    @Override public PortalDto portal(UUID user) {users.getById(user);available();var customer=subscriptions.account(user).getCustomerId();if(customer==null)throw new ConflictException("BILLING_CUSTOMER_NOT_FOUND","No billing customer exists.");return stripe.portal(customer);}
    @Override public void webhook(byte[] raw,String signature) {
        var e=signatures.verify(raw,signature);String type=e.path("type").asText(),event=e.path("id").asText();
        if(!Set.of("checkout.session.completed","checkout.session.async_payment_succeeded","invoice.paid","invoice.payment_failed","customer.subscription.created","customer.subscription.updated","customer.subscription.deleted").contains(type)) return;
        lock.lock();try {
            if(subscriptions.processed(event)) return;
            var customer=e.path("data").path("object").path("customer");String id=customer.isTextual()?customer.asText():customer.path("id").asText();
            if(id.isBlank()) throw new BusinessValidationException("INVALID_WEBHOOK_EVENT","Customer binding is required.");
            var owner=subscriptions.owner(id);if(owner.isEmpty())return;
            available();var state=stripe.latest(id);
            String plan=Objects.equals(state.getPriceId(),properties.getMonthlyPrice())?"PRO_MONTHLY":Objects.equals(state.getPriceId(),properties.getAnnualPrice())?"PRO_ANNUAL":"FREE";
            if("FREE".equals(plan)) state.setInvoicePaid(false);
            subscriptions.apply(owner.get(),event,state,plan);
        }finally{lock.unlock();}
    }
}
