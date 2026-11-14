# Runs in the foreground; no raw CLI output (which contains the signing secret).
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'RootEnv.ps1')
$settings = Import-RootEnv
if ($settings.BILLING_MODE -ne 'TEST' -or $settings.STRIPE_SECRET_KEY -notmatch '^(sk|rk)_test_') { throw 'A Stripe TEST key in root .env is required.' }
$events = 'checkout.session.completed,checkout.session.async_payment_succeeded,invoice.paid,invoice.payment_failed,customer.subscription.created,customer.subscription.updated,customer.subscription.deleted'
$forwardTo = "http://localhost:$($settings.BACKEND_PORT)/api/v1/subscriptions/webhook"
$stripe = Get-Command stripe -ErrorAction Stop
$node = (Get-Command node -ErrorAction Stop).Source
# npm's cross-platform wrapper launches the installed official CLI. No keys in argv.
$shim = Join-Path (Split-Path $stripe.Source) 'node_modules/@stripe/cli/bin/shim.js'
if (!(Test-Path -LiteralPath $shim)) { throw 'Install the CLI with npm install -g @stripe/cli first.' }
$start = [Diagnostics.ProcessStartInfo]::new()
$start.FileName = $node
$start.UseShellExecute = $false
$start.CreateNoWindow = $true
$start.RedirectStandardOutput = $true
$start.RedirectStandardError = $true
$start.Environment['STRIPE_API_KEY'] = $settings.STRIPE_SECRET_KEY
foreach ($arg in @($shim,'listen','--forward-to',$forwardTo,'--events',$events)) { $start.ArgumentList.Add($arg) }
$process = [Diagnostics.Process]::new()
$process.StartInfo = $start
$saved = $false
try {
    $null = $process.Start()
    $stdout = $process.StandardOutput.ReadLineAsync()
    $stderr = $process.StandardError.ReadLineAsync()
    while (!$process.HasExited -or !$stdout.IsCompleted -or !$stderr.IsCompleted) {
        foreach ($stream in @('stdout','stderr')) {
            $task = Get-Variable -Name $stream -ValueOnly
            if ($task.IsCompleted) {
                $line = $task.GetAwaiter().GetResult()
                if ($null -ne $line) {
                    if ($line -match 'whsec_[A-Za-z0-9_]+') {
                        Set-RootEnvValue 'STRIPE_WEBHOOK_SECRET' $Matches[0]
                        if (!$saved) { Write-Host "TEST listener ready: $forwardTo. Signing secret saved privately in root .env; restart backend."; $saved=$true }
                    }
                    # Only safe event IDs/types/statuses, never arbitrary CLI lines.
                    elseif ($line -match '(evt_[A-Za-z0-9]+)') { Write-Host "Stripe event $($Matches[1]) observed; verify delivery in backend/Stripe Dashboard." }
                    $reader = if ($stream -eq 'stdout') { $process.StandardOutput } else { $process.StandardError }
                    Set-Variable -Name $stream -Value ($reader.ReadLineAsync())
                }
            }
        }
        if ($process.HasExited -and $stdout.IsCompleted -and $stderr.IsCompleted) { break }
        Start-Sleep -Milliseconds 100
    }
    if (!$saved -or $process.ExitCode -ne 0) { throw 'Stripe listener did not stay connected. Check CLI execution policy, network and TEST account/CLI access; no signing secret was fabricated.' }
} finally {
    if (!$process.HasExited) { $process.Kill($true) }
    $process.Dispose()
}
