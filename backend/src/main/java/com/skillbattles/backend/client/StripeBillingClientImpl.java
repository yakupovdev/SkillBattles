package com.skillbattles.backend.client;
import com.fasterxml.jackson.databind.*;
import com.skillbattles.backend.config.BillingProperties;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.exception.*;
import com.stripe.StripeClient;
import com.stripe.net.*;
import org.springframework.stereotype.Component;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.*;
@Component
public class StripeBillingClientImpl implements StripeBillingClient {
    public static final String API_VERSION="2026-10-28.endive";
    private final BillingProperties properties;
    private final ObjectMapper json;
    private final StripeClient stripe;
    @org.springframework.beans.factory.annotation.Autowired
    public StripeBillingClientImpl(BillingProperties properties,ObjectMapper json) {
        this(properties,json,new StripeClient(properties.getSecretKey().isBlank()?"sk_test_unconfigured":properties.getSecretKey()));
    }
    StripeBillingClientImpl(BillingProperties properties,ObjectMapper json,StripeClient stripe) {
        this.properties=properties;this.json=json;
        this.stripe=stripe;
    }
    private boolean trustedUrl(String value) {try {var u=URI.create(value);return u.getUserInfo()==null&&u.getHost()!=null&&("https".equals(u.getScheme()) || ("http".equals(u.getScheme())&&Set.of("localhost","127.0.0.1","[::1]").contains(u.getHost())));}catch(Exception ex){return false;}}
    @Override public boolean available() {
        return "TEST".equals(properties.getMode()) && (properties.getSecretKey().startsWith("sk_test_")||properties.getSecretKey().startsWith("rk_test_"))
            && properties.getWebhookSecret().startsWith("whsec_") && properties.getMonthlyPrice().startsWith("price_") && properties.getAnnualPrice().startsWith("price_")
            && trustedUrl(properties.getSuccessUrl()) && trustedUrl(properties.getCancelUrl()) && trustedUrl(properties.getPortalReturnUrl());
    }
    private String encode(String s) {return URLEncoder.encode(s,StandardCharsets.UTF_8);}
    private JsonNode request(ApiResource.RequestMethod method,String path,Map<String,String> params,String key) {
        if(!available()) throw new BillingUnavailableException();
        try {
            String form=params.entrySet().stream().sorted(Map.Entry.comparingByKey()).map(e -> encode(e.getKey())+"="+encode(e.getValue())).collect(java.util.stream.Collectors.joining("&"));
            var options=RawRequestOptions.builder().setAdditionalHeaders(Map.of("Stripe-Version",API_VERSION)).setConnectTimeout(5000).setReadTimeout(10000).setMaxNetworkRetries(2);
            if(key!=null) options.setIdempotencyKey(key);
            // Stripe raw GET does not move string content into the query automatically.
            String url=method==ApiResource.RequestMethod.GET&&!form.isEmpty()?path+"?"+form:path;
            var result=json.readTree(stripe.rawRequest(method,url,method==ApiResource.RequestMethod.GET?"":form,options.build()).body());
            if(result.path("livemode").asBoolean(false)) throw new BillingUnavailableException();return result;
        } catch(BillingUnavailableException ex) {throw ex;} catch(Exception ex) {throw new BillingUnavailableException();}
    }
    private JsonNode get(String path,Map<String,String> params) {return request(ApiResource.RequestMethod.GET,path,params,null);}
    @Override public String customer(UUID id) {return request(ApiResource.RequestMethod.POST,"/v1/customers",Map.of("metadata[skillbattles_user_id]",id.toString()),"skillbattles:customer:"+id).path("id").asText();}
    private List<JsonNode> subscriptions(String customer) {
        var result=new ArrayList<JsonNode>();var cursors=new HashSet<String>();String cursor=null;
        while(true) {
            var params=new HashMap<>(Map.of("customer",customer,"status","all","limit","100","expand[]","data.latest_invoice"));if(cursor!=null)params.put("starting_after",cursor);
            var page=get("/v1/subscriptions",params);var data=page.path("data");if(!data.isArray())throw new BillingUnavailableException();data.forEach(result::add);
            if(!page.path("has_more").asBoolean())return result;
            if(data.isEmpty())throw new BillingUnavailableException();cursor=data.get(data.size()-1).path("id").asText();
            if(cursor.isBlank()||!cursors.add(cursor))throw new BillingUnavailableException();
        }
    }
    private boolean blocking(JsonNode s) {return !Set.of("canceled","incomplete_expired").contains(s.path("status").asText());}
    @Override public boolean hasSubscription(String customer) {return subscriptions(customer).stream().anyMatch(this::blocking);}
    private String price(String plan) {return "PRO_MONTHLY".equals(plan)?properties.getMonthlyPrice():properties.getAnnualPrice();}
    private void verifyPrice(String plan) {
        var p=get("/v1/prices/"+price(plan),Map.of());boolean monthly="PRO_MONTHLY".equals(plan);
        if(!p.path("active").asBoolean() || p.path("unit_amount").asLong()!= (monthly?799:4799) || !"usd".equals(p.path("currency").asText())
            || !p.path("recurring").path("interval").asText().equals(monthly?"month":"year") || p.path("recurring").path("interval_count").asInt()!=1) throw new BillingUnavailableException();
    }
    @Override public CheckoutDto checkout(UUID user,String customer,String plan,UUID requestId) {
        verifyPrice(plan);
        String label=requestId.toString().replace("-","").substring(0,8).chars().mapToObj(c -> String.valueOf((char)('a'+Character.digit(c,16)))).collect(java.util.stream.Collectors.joining());
        var p=new HashMap<String,String>();p.put("mode","subscription");p.put("customer",customer);p.put("client_reference_id",user.toString());
        p.put("line_items[0][price]",price(plan));p.put("line_items[0][quantity]","1");p.put("success_url",properties.getSuccessUrl());p.put("cancel_url",properties.getCancelUrl());
        p.put("subscription_data[metadata][skillbattles_user_id]",user.toString());p.put("integration_identifier","skillbattles-"+label);
        var s=request(ApiResource.RequestMethod.POST,"/v1/checkout/sessions",p,"skillbattles:checkout:"+user+":"+requestId);
        if(!s.path("id").asText().startsWith("cs_test_")||!s.path("customer").asText().equals(customer)) throw new BillingUnavailableException();
        return new CheckoutDto(s.path("id").asText(),s.path("url").asText(),Instant.ofEpochSecond(s.path("expires_at").asLong()));
    }
    @Override public PortalDto portal(String customer) {return new PortalDto(request(ApiResource.RequestMethod.POST,"/v1/billing_portal/sessions",Map.of("customer",customer,"return_url",properties.getPortalReturnUrl()),null).path("url").asText());}
    private Instant instant(JsonNode n) {return n.isNumber()?Instant.ofEpochSecond(n.asLong()):null;}
    @Override public ProviderSubscriptionDto latest(String customer) {
        var values=subscriptions(customer);
        long open=values.stream().filter(this::blocking).count();if(open>1) throw new BillingUnavailableException();
        var selected=values.stream().filter(this::blocking).findFirst().orElseGet(() -> values.stream().max(Comparator.comparingLong(s -> s.path("created").asLong())).orElse(null));
        if(selected==null) return new ProviderSubscriptionDto(customer,null,null,"NONE",null,null,false,false,false);
        if(selected.path("livemode").asBoolean() || !selected.path("customer").asText().equals(customer)) throw new BillingUnavailableException();
        var items=selected.path("items").path("data");if(items.size()!=1 || items.get(0).path("quantity").asInt()!=1) throw new BillingUnavailableException();
        var item=items.get(0);var invoice=selected.path("latest_invoice");
        boolean paid="paid".equals(invoice.path("status").asText()) && customer.equals(invoice.path("customer").asText()) && !invoice.path("livemode").asBoolean();
        String status=switch(selected.path("status").asText()) {case "active" -> "ACTIVE";case "past_due" -> "PAST_DUE";case "canceled" -> "CANCELED";case "unpaid" -> "UNPAID";case "incomplete_expired" -> "EXPIRED";default -> "INCOMPLETE";};
        return new ProviderSubscriptionDto(customer,selected.path("id").asText(),item.path("price").path("id").asText(),status,instant(item.path("current_period_start")),instant(item.path("current_period_end")),selected.path("cancel_at_period_end").asBoolean(),paid,false);
    }
}
