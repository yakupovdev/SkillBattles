# Reuses TEST catalog objects. Never creates Customers, Checkout or subscriptions.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'RootEnv.ps1')
$settings = Import-RootEnv
if ($settings.BILLING_MODE -ne 'TEST' -or $settings.STRIPE_SECRET_KEY -notmatch '^(sk|rk)_test_') { throw 'A Stripe TEST key in root .env is required.' }

function Invoke-StripeTest {
    param([string]$Path, [hashtable]$Data = @{}, [string]$Method = 'GET', [string]$IdempotencyKey)
    $headers = @{ Authorization = "Bearer $($settings.STRIPE_SECRET_KEY)"; 'Stripe-Version' = '2026-10-28.endive' }
    if ($IdempotencyKey) { $headers['Idempotency-Key'] = $IdempotencyKey }
    try {
        $result = Invoke-RestMethod -Uri "https://api.stripe.com/v1/$Path" -Method $Method -Headers $headers -Body $Data -TimeoutSec 30
    } catch {
        $status = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
        # Never include request headers, response bodies or exception dumps in output.
        throw "Stripe TEST request failed (HTTP $status, resource $Path)."
    }
    if ($result.PSObject.Properties['livemode'] -and $result.livemode) { throw 'Refusing a live Stripe object.' }
    return $result
}
function Get-StripeTestList([string]$Path, [hashtable]$Filters = @{}) {
    $items = [Collections.Generic.List[object]]::new()
    $query = @{} + $Filters
    $query.limit = '100'
    do {
        $page = Invoke-StripeTest $Path $query
        foreach ($item in $page.data) {
            if ($item.livemode) { throw 'Refusing a live Stripe object.' }
            $items.Add($item)
        }
        if ($page.has_more) {
            if ($page.data.Count -eq 0) { throw 'Invalid Stripe pagination.' }
            $query.starting_after = $page.data[-1].id
        }
    } while ($page.has_more)
    return $items.ToArray()
}

$account = Invoke-StripeTest 'account'
Write-Host "Stripe TEST key validated for account $($account.id)."
$products = @(Get-StripeTestList 'products' @{active='true'})
$product = $products | Where-Object { $_.name -eq 'SkillBattles Pro' } | Select-Object -First 1
if (!$product) {
    $product = Invoke-StripeTest 'products' @{id='prod_skillbattles_pro_test';name='SkillBattles Pro';'metadata[application]'='skillbattles'} 'POST' 'skillbattles:setup:product:v1'
}
$prices = @(Get-StripeTestList 'prices' @{active='true';type='recurring';product=$product.id})
foreach ($plan in @(
    @{Name='STRIPE_PRICE_PRO_MONTHLY';Amount=799;Interval='month';Lookup='skillbattles_pro_monthly_usd_799'},
    @{Name='STRIPE_PRICE_PRO_ANNUAL';Amount=4799;Interval='year';Lookup='skillbattles_pro_annual_usd_4799'}
)) {
    $price = $null
    if ($settings[$plan.Name]) { $price = Invoke-StripeTest "prices/$($settings[$plan.Name])" }
    if (!$price) {
        $price = $prices | Where-Object { $_.currency -eq 'usd' -and $_.unit_amount -eq $plan.Amount -and $_.recurring.interval -eq $plan.Interval -and $_.recurring.interval_count -eq 1 } | Select-Object -First 1
    }
    if (!$price) {
        $price = Invoke-StripeTest 'prices' @{product=$product.id;currency='usd';unit_amount=[string]$plan.Amount;'recurring[interval]'=$plan.Interval;lookup_key=$plan.Lookup;'metadata[application]'='skillbattles'} 'POST' "skillbattles:setup:$($plan.Lookup):v1"
    }
    if (!$price.active -or $price.currency -ne 'usd' -or $price.unit_amount -ne $plan.Amount -or $price.recurring.interval -ne $plan.Interval -or $price.recurring.interval_count -ne 1) { throw "Invalid TEST Price for $($plan.Name)." }
    Set-RootEnvValue $plan.Name $price.id
    Write-Host "$($plan.Name): validated and saved in root .env."
}

$configs = @(Get-StripeTestList 'billing_portal/configurations' @{active='true'})
$portal = $configs | Where-Object is_default | Select-Object -First 1
if (!$portal) {
    $portal = Invoke-StripeTest 'billing_portal/configurations' @{
        name='SkillBattles local TEST';default_return_url=$settings.BILLING_PORTAL_RETURN_URL
        'business_profile[headline]'='Manage your SkillBattles Pro subscription'
        'features[invoice_history][enabled]'='true'
        'features[payment_method_update][enabled]'='true'
        'features[subscription_cancel][enabled]'='true'
        'features[subscription_cancel][mode]'='at_period_end'
    } 'POST' 'skillbattles:setup:portal:v1'
}
if (!$portal.is_default) { throw 'Set the SkillBattles TEST configuration as default in Stripe Dashboard; the backend uses the default Portal.' }
if (!$portal.features.subscription_cancel.enabled -or !$portal.features.payment_method_update.enabled) {
    Write-Warning 'Default TEST Portal exists; enable cancellation and payment method updates in its Dashboard configuration.'
}
Write-Host 'Default TEST Customer Portal validated. Existing default configuration was preserved.'
Write-Host 'No subscriptions or payments created. Start the real Stripe listener, then restart backend.'
