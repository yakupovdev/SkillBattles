[CmdletBinding()]
param([string]$PublicOrigin = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'RootEnv.ps1')
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$destination = Join-Path $root '.env.heroku'
if (Test-Path -LiteralPath $destination) { throw '.env.heroku already exists; edit it locally to preserve your values.' }
$sourceValues = Read-DotEnv -Path (Join-Path $root '.env')
if ($PublicOrigin) {
    $uri = $null
    if (![Uri]::TryCreate($PublicOrigin, [UriKind]::Absolute, [ref]$uri) -or $uri.Scheme -ne 'https' -or
        $uri.IsLoopback -or !$uri.Host.Contains('.') -or $uri.UserInfo -or $uri.Query -or $uri.Fragment -or
        $uri.AbsolutePath -ne '/') { throw 'PublicOrigin must be the actual public HTTPS origin, without path/query/credentials.' }
    $PublicOrigin = $PublicOrigin.TrimEnd('/')
}
$values = [ordered]@{SPRING_PROFILES_ACTIVE='heroku'}
# Explicit allowlist. No Compose/database credentials, PORT, local URLs or build-time secrets.
foreach ($key in @('JWT_SECRET','JWT_ISSUER','JWT_ACCESS_TTL','JWT_REFRESH_TTL',
    'PASSWORD_RESET_TTL','SEASON_SCAN_MS','SEASON_SCHEDULING_ENABLED','MATCHMAKING_SEARCH_SECONDS',
    'PRIVATE_DUEL_SECONDS','READY_TIMEOUT_SECONDS','COUNTDOWN_SECONDS','REVEAL_SECONDS',
    'RECONNECT_GRACE_SECONDS','QUESTION_HISTORY_BATTLES')) {
    if ($sourceValues.ContainsKey($key)) { $values[$key] = $sourceValues[$key] }
}
if (!$values.Contains('JWT_SECRET') -or !$values['JWT_SECRET']) { throw 'JWT_SECRET is missing in local .env.' }
$values['PASSWORD_RESET_BASE_URL'] = if ($PublicOrigin) { "$PublicOrigin/auth/reset" } else { '' }
# Reuse SMTP only when an external host actually exists; never copy mailhog/Compose DNS.
$externalSmtp = $sourceValues.ContainsKey('SMTP_HOST') -and $sourceValues.SMTP_HOST -match '\.' -and
    $sourceValues.SMTP_HOST -notmatch 'localhost|127\.0\.0\.1|\.local$'
foreach ($key in @('SMTP_HOST','SMTP_USERNAME','SMTP_PASSWORD','MAIL_FROM')) {
    $values[$key] = if ($externalSmtp -and $sourceValues.ContainsKey($key)) { $sourceValues[$key] } else { '' }
}
if ($externalSmtp) {
    foreach ($key in @('SMTP_PORT','SMTP_AUTH','SMTP_STARTTLS')) {
        if ($sourceValues.ContainsKey($key)) { $values[$key] = $sourceValues[$key] }
    }
}
$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# LOCAL SECRET FILE. Never commit, print, or pass it to a frontend build.')
$lines.Add('# DATABASE_URL is supplied by the attached Heroku Postgres; PORT by Heroku.')
$lines.Add('# Empty values below are unknown, not invented. Complete them in a local editor.')
$lines.Add('# Obtain the actual HTTPS origin from Heroku Settings > Domains and certificates.')
$lines.Add('# SMTP credentials, MAIL_FROM and SMTP_PORT/AUTH/STARTTLS: your SMTP provider.')
foreach ($key in $values.Keys) {
    $value = [string]$values[$key]
    if ($value.Contains("`n") -or $value.Contains("`r")) { throw "Multiline value is not supported: $key" }
    $lines.Add($key + "='" + $value.Replace("'", "\'") + "'")
}
if (!$externalSmtp) {
    $lines.Add('# SMTP_PORT=   # Set the provider port; omit while SMTP is unconfigured.')
    $lines.Add('# SMTP_AUTH=   # Set from provider documentation.')
    $lines.Add('# SMTP_STARTTLS=   # Set from provider documentation.')
}
[IO.File]::WriteAllLines($destination, $lines, [Text.UTF8Encoding]::new($false))
Write-Output 'Created ignored .env.heroku using an allowlist. Original .env was not changed.'
Write-Output 'Missing: actual public HTTPS URL and SMTP configuration.'
