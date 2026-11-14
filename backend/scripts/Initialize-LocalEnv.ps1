[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'RootEnv.ps1')
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$envPath = Join-Path $root '.env'
if (!(Test-Path -LiteralPath $envPath)) { Copy-Item -LiteralPath (Join-Path $root '.env.example') -Destination $envPath }
$settings = Read-DotEnv $envPath
if ([string]::IsNullOrWhiteSpace($settings.POSTGRES_PASSWORD)) {
    Set-RootEnvValue 'POSTGRES_PASSWORD' ([Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(24)))
}
if ([string]::IsNullOrWhiteSpace($settings.JWT_SECRET)) {
    Set-RootEnvValue 'JWT_SECRET' ([Convert]::ToBase64String([Security.Cryptography.RandomNumberGenerator]::GetBytes(32)))
}
Write-Host 'Root .env initialized. Existing secrets/settings preserved; external credentials were not invented.'
