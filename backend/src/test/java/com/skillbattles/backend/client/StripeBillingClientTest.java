package com.skillbattles.backend.client;
import com.fasterxml.jackson.databind.json.JsonMapper;
import com.skillbattles.backend.config.BillingProperties;
import com.stripe.StripeClient;
import com.stripe.net.*;
import org.junit.jupiter.api.*;
import org.mockito.ArgumentCaptor;
import java.util.*;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;
class StripeBillingClientTest {
    private final BillingProperties p=new BillingProperties();private final StripeClient sdk=mock(StripeClient.class);
    private StripeBillingClientImpl client;
    @BeforeEach void setup(){p.setSecretKey("rk_test_fixture_only");p.setWebhookSecret("whsec_fixture");p.setMonthlyPrice("price_m");p.setAnnualPrice("price_a");p.setSuccessUrl("http://localhost:5173/success");p.setCancelUrl("http://localhost:5173/cancel");p.setPortalReturnUrl("http://localhost:5173/portal");client=new StripeBillingClientImpl(p,JsonMapper.builder().build(),sdk);}
    private StripeResponse response(String body){return new StripeResponse(200,HttpHeaders.of(Map.of()),body);}
    @Test void checkoutUsesVerifiedPriceServerUrlsPinnedVersionAndStableIdempotencyKey() throws Exception {
        when(sdk.rawRequest(eq(ApiResource.RequestMethod.GET),eq("/v1/prices/price_m"),anyString(),any())).thenReturn(response("{\"active\":true,\"livemode\":false,\"unit_amount\":799,\"currency\":\"usd\",\"recurring\":{\"interval\":\"month\",\"interval_count\":1}}"));
        when(sdk.rawRequest(eq(ApiResource.RequestMethod.POST),eq("/v1/checkout/sessions"),anyString(),any())).thenReturn(response("{\"id\":\"cs_test_fixture\",\"customer\":\"cus_fixture\",\"url\":\"https://checkout.stripe.com/test\",\"expires_at\":1794659000,\"livemode\":false}"));
        UUID user=UUID.randomUUID(),request=UUID.randomUUID();client.checkout(user,"cus_fixture","PRO_MONTHLY",request);client.checkout(user,"cus_fixture","PRO_MONTHLY",request);
        var form=ArgumentCaptor.forClass(String.class);var options=ArgumentCaptor.forClass(RawRequestOptions.class);
        verify(sdk,times(2)).rawRequest(eq(ApiResource.RequestMethod.POST),eq("/v1/checkout/sessions"),form.capture(),options.capture());
        assertThat(form.getAllValues().get(0)).isEqualTo(form.getAllValues().get(1));
        assertThat(form.getValue()).contains("mode=subscription","price_m","success_url=http%3A%2F%2Flocalhost","integration_identifier=skillbattles-")
                .doesNotContain("unit_amount","payment_method_types","api_key","sk_test");
        assertThat(options.getValue().getAdditionalHeaders()).containsEntry("Stripe-Version","2026-10-28.endive");
        assertThat(options.getAllValues()).extracting(RawRequestOptions::getIdempotencyKey).containsOnly("skillbattles:checkout:"+user+":"+request);
    }
    @Test void providerPeriodIsReadFromItemAndPaidInvoiceMustMatchCustomer() throws Exception {
        String body="{\"data\":[{\"id\":\"sub_fixture\",\"customer\":\"cus_fixture\",\"livemode\":false,\"status\":\"active\",\"cancel_at_period_end\":true,\"items\":{\"data\":[{\"quantity\":1,\"price\":{\"id\":\"price_m\"},\"current_period_start\":1000,\"current_period_end\":2000}]},\"latest_invoice\":{\"customer\":\"cus_fixture\",\"status\":\"paid\",\"livemode\":false}}],\"has_more\":false}";
        when(sdk.rawRequest(any(),startsWith("/v1/subscriptions?"),anyString(),any())).thenReturn(response(body));
        var state=client.latest("cus_fixture");assertThat(state.getCurrentPeriodStart().getEpochSecond()).isEqualTo(1000);assertThat(state.getCurrentPeriodEnd().getEpochSecond()).isEqualTo(2000);assertThat(state.isInvoicePaid()).isTrue();
        verify(sdk).rawRequest(eq(ApiResource.RequestMethod.GET),contains("customer=cus_fixture"),eq(""),any());
        when(sdk.rawRequest(any(),startsWith("/v1/subscriptions?"),anyString(),any())).thenReturn(response(body.replace("\"latest_invoice\":{\"customer\":\"cus_fixture\"","\"latest_invoice\":{\"customer\":\"cus_other\"")));
        assertThat(client.latest("cus_fixture").isInvoicePaid()).isFalse();
    }
    @Test void wrongPriceLiveKeysAndUntrustedConfigurationNeverCreateCheckout() throws Exception {
        when(sdk.rawRequest(any(),anyString(),anyString(),any())).thenReturn(response("{\"active\":true,\"unit_amount\":1,\"currency\":\"usd\",\"recurring\":{\"interval\":\"month\",\"interval_count\":1}}"));
        assertThatThrownBy(() -> client.checkout(UUID.randomUUID(),"cus_fixture","PRO_MONTHLY",UUID.randomUUID())).isInstanceOf(com.skillbattles.backend.exception.BillingUnavailableException.class);
        verify(sdk,never()).rawRequest(eq(ApiResource.RequestMethod.POST),anyString(),anyString(),any());
        p.setSecretKey("sk_live_forbidden");assertThat(client.available()).isFalse();p.setSecretKey("rk_test_fixture_only");p.setSuccessUrl("javascript:alert(1)");assertThat(client.available()).isFalse();
        p.setSuccessUrl("http://external.example.com/success");assertThat(client.available()).isFalse();p.setSuccessUrl("https://trusted.example.com/success");p.setMode("LIVE");assertThat(client.available()).isFalse();
    }
    @Test void subscriptionsOnLaterPagesStillBlockASecondPurchase() throws Exception {
        when(sdk.rawRequest(eq(ApiResource.RequestMethod.GET),startsWith("/v1/subscriptions?"),eq(""),any())).thenAnswer(call -> {
            String url=call.getArgument(1);return response(url.contains("starting_after=sub_old")?"{\"data\":[{\"id\":\"sub_active\",\"status\":\"active\"}],\"has_more\":false}":"{\"data\":[{\"id\":\"sub_old\",\"status\":\"canceled\"}],\"has_more\":true}");
        });
        assertThat(client.hasSubscription("cus_fixture")).isTrue();
        verify(sdk).rawRequest(eq(ApiResource.RequestMethod.GET),contains("starting_after=sub_old"),eq(""),any());
    }
}
