[CmdletBinding()]
param([string[]]$IpAddress = @())
$ErrorActionPreference = 'Stop'

# Generates local TLS files only. Never installs a trust anchor automatically.
$directory = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../.cache/local-tls'))
$null = New-Item -ItemType Directory -Path $directory -Force
$caPath = Join-Path $directory 'ca.crt'
$caKeyPath = Join-Path $directory 'ca.key'
$certPath = Join-Path $directory 'server.crt'
$keyPath = Join-Path $directory 'server.key'
$manifestPath = Join-Path $directory 'hosts.json'
$now = [DateTimeOffset]::UtcNow
$ips = [Collections.Generic.SortedSet[string]]::new()
$null = $ips.Add('127.0.0.1')
if ($IpAddress.Count) {
    foreach ($value in $IpAddress) { $null = $ips.Add([Net.IPAddress]::Parse($value).ToString()) }
} else {
    foreach ($adapter in [Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
        if ($adapter.OperationalStatus -ne [Net.NetworkInformation.OperationalStatus]::Up) { continue }
        $properties = $adapter.GetIPProperties()
        if (!$properties.GatewayAddresses.Count) { continue }
        foreach ($unicast in $properties.UnicastAddresses) {
            if ($unicast.Address.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork) {
                $null = $ips.Add($unicast.Address.ToString())
            }
        }
    }
}
$dns = @('localhost', [Net.Dns]::GetHostName()) | Select-Object -Unique

function Write-Pem([string]$Path, [string]$Content) {
    [IO.File]::WriteAllText($Path, $Content + "`n", [Text.UTF8Encoding]::new($false))
}

function Protect-PrivateKey([string]$Path) {
    if ($IsWindows) {
        $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        & icacls $Path /inheritance:r /grant:r "*${sid}:(F)" '*S-1-5-18:(F)' *> $null
        if ($LASTEXITCODE -ne 0) { throw 'Cannot restrict private-key file permissions.' }
    } else {
        & chmod 600 $Path
        if ($LASTEXITCODE -ne 0) { throw 'Cannot restrict private-key file permissions.' }
    }
}

if ((Test-Path -LiteralPath $caPath) -ne (Test-Path -LiteralPath $caKeyPath)) {
    throw 'Local CA is incomplete. Restore its matching certificate/key; existing trust will not be replaced silently.'
}
$ca = $null
$caRsa = $null
$serverRsa = $null
$serverCert = $null
try {
    if (Test-Path -LiteralPath $caPath) {
        $ca = [Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromPemFile($caPath, $caKeyPath)
        if ($ca.NotAfter.ToUniversalTime() -lt $now.AddDays(91).UtcDateTime) {
            throw 'Local CA is approaching expiry. Renew it deliberately and update device trust.'
        }
    } else {
        $caRsa = [Security.Cryptography.RSA]::Create(3072)
        $request = [Security.Cryptography.X509Certificates.CertificateRequest]::new(
            'CN=SkillBattles Local Development CA', $caRsa,
            [Security.Cryptography.HashAlgorithmName]::SHA256, [Security.Cryptography.RSASignaturePadding]::Pkcs1)
        $request.CertificateExtensions.Add([Security.Cryptography.X509Certificates.X509BasicConstraintsExtension]::new($true, $false, 0, $true))
        $usage = [Security.Cryptography.X509Certificates.X509KeyUsageFlags]::KeyCertSign -bor [Security.Cryptography.X509Certificates.X509KeyUsageFlags]::CrlSign
        $request.CertificateExtensions.Add([Security.Cryptography.X509Certificates.X509KeyUsageExtension]::new($usage, $true))
        $request.CertificateExtensions.Add([Security.Cryptography.X509Certificates.X509SubjectKeyIdentifierExtension]::new($request.PublicKey, $false))
        $ca = $request.CreateSelfSigned($now.AddMinutes(-5), $now.AddYears(3))
        Write-Pem $caPath $ca.ExportCertificatePem()
        Write-Pem $caKeyPath $caRsa.ExportPkcs8PrivateKeyPem()
        Protect-PrivateKey $caKeyPath
    }

    $reuse = $false
    if ((Test-Path -LiteralPath $certPath) -and (Test-Path -LiteralPath $keyPath) -and (Test-Path -LiteralPath $manifestPath)) {
        $previous = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
        $serverCert = [Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromPemFile($certPath, $keyPath)
        $reuse = $serverCert.NotAfter.ToUniversalTime() -gt $now.AddDays(14).UtcDateTime -and
                 $previous.certificateSha256 -eq $serverCert.GetCertHashString([Security.Cryptography.HashAlgorithmName]::SHA256) -and
                 $previous.caSha256 -eq $ca.GetCertHashString([Security.Cryptography.HashAlgorithmName]::SHA256)
        foreach ($ip in $ips) { if ($ip -notin $previous.ips) { $reuse = $false } }
        foreach ($name in $dns) { if ($name -notin $previous.dns) { $reuse = $false } }
    }
    if (!$reuse) {
        if ($serverCert) { $serverCert.Dispose(); $serverCert = $null }
        $serverRsa = [Security.Cryptography.RSA]::Create(3072)
        $request = [Security.Cryptography.X509Certificates.CertificateRequest]::new(
            'CN=SkillBattles local frontend', $serverRsa,
            [Security.Cryptography.HashAlgorithmName]::SHA256, [Security.Cryptography.RSASignaturePadding]::Pkcs1)
        $san = [Security.Cryptography.X509Certificates.SubjectAlternativeNameBuilder]::new()
        foreach ($ip in $ips) { $san.AddIpAddress([Net.IPAddress]::Parse($ip)) }
        foreach ($name in $dns) { $san.AddDnsName($name) }
        $request.CertificateExtensions.Add($san.Build())
        $request.CertificateExtensions.Add([Security.Cryptography.X509Certificates.X509BasicConstraintsExtension]::new($false, $false, 0, $true))
        $usage = [Security.Cryptography.X509Certificates.X509KeyUsageFlags]::DigitalSignature -bor [Security.Cryptography.X509Certificates.X509KeyUsageFlags]::KeyEncipherment
        $request.CertificateExtensions.Add([Security.Cryptography.X509Certificates.X509KeyUsageExtension]::new($usage, $true))
        $purposes = [Security.Cryptography.OidCollection]::new()
        $null = $purposes.Add([Security.Cryptography.Oid]::new('1.3.6.1.5.5.7.3.1'))
        $request.CertificateExtensions.Add([Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]::new($purposes, $true))
        $serial = [Security.Cryptography.RandomNumberGenerator]::GetBytes(16)
        $serverCert = $request.Create($ca, $now.AddMinutes(-5), $now.AddDays(90), $serial)
        Write-Pem $certPath $serverCert.ExportCertificatePem()
        Write-Pem $keyPath $serverRsa.ExportPkcs8PrivateKeyPem()
        Protect-PrivateKey $keyPath
        $manifest = @{ ips=@($ips); dns=@($dns); caSha256=$ca.GetCertHashString([Security.Cryptography.HashAlgorithmName]::SHA256); certificateSha256=$serverCert.GetCertHashString([Security.Cryptography.HashAlgorithmName]::SHA256) }
        [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json) + "`n", [Text.UTF8Encoding]::new($false))
    }
    Write-Host "Local HTTPS certificate ready for: $($ips -join ', '). Existing CA preserved; no trust store changed."
    Write-Host "Public CA certificate: $caPath"
    Write-Host "CA SHA-256: $($ca.GetCertHashString([Security.Cryptography.HashAlgorithmName]::SHA256))"
} finally {
    if ($serverCert) { $serverCert.Dispose() }
    if ($serverRsa) { $serverRsa.Dispose() }
    if ($ca) { $ca.Dispose() }
    if ($caRsa) { $caRsa.Dispose() }
}
