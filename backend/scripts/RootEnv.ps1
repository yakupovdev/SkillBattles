# Dot-source this trusted script, never the .env data file.
Set-StrictMode -Version Latest

function Read-DotEnv {
    param([Parameter(Mandatory)][string]$Path)
    $values = @{}
    $literal = @{}
    $lineNumber = 0
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        $lineNumber++
        if ($line -match '^\s*(#|$)') { continue }
        if ($line -notmatch '^\s*([A-Z][A-Z0-9_]*)\s*=\s*(.*)$') {
            throw "Invalid ENV syntax at line $lineNumber. Values are not executed."
        }
        $key = $Matches[1]
        $value = $Matches[2].Trim()
        if ($values.ContainsKey($key)) { throw "Duplicate ENV key: $key" }
        $literal[$key] = $false
        if ($value.StartsWith("'")) {
            if ($value -notmatch "^'((?:\\'|[^'])*)'\s*(?:#.*)?$") { throw "Invalid quoting at ENV line $lineNumber" }
            $value = $Matches[1].Replace("\'", "'")
            $literal[$key] = $true
        } elseif ($value.StartsWith('"')) {
            if ($value -notmatch '^"((?:\\.|[^"\\])*)"\s*(?:#.*)?$') { throw "Invalid quoting at ENV line $lineNumber" }
            $value = [regex]::Replace($Matches[1], '\\([nrt"\\$])', {
                param($match)
                switch ($match.Groups[1].Value) {
                    'n' { "`n" }; 'r' { "`r" }; 't' { "`t" }
                    '$' { [string][char]0xE000 }; default { $match.Groups[1].Value }
                }
            })
        } else {
            $value = ($value -replace '\s+#.*$', '').TrimEnd()
        }
        $values[$key] = $value
    }
    # Resolve only ${NAME}, without shell evaluation or ambient environment fallback.
    $resolved = @{}
    $resolving = @{}
    function Resolve-DotEnvValue([string]$Name) {
        if ($resolved.ContainsKey($Name)) { return $resolved[$Name] }
        if (!$values.ContainsKey($Name)) { throw "Undefined ENV reference: $Name" }
        if ($resolving.ContainsKey($Name)) { throw "Cyclic ENV reference: $Name" }
        $resolving[$Name] = $true
        $result = $values[$Name]
        if (!$literal[$Name]) {
            $result = [regex]::Replace($result, '\$\{([A-Z][A-Z0-9_]*)\}', {
                param($match)
                Resolve-DotEnvValue $match.Groups[1].Value
            })
            $result = $result.Replace([string][char]0xE000, '$')
        }
        $resolving.Remove($Name)
        $resolved[$Name] = $result
        return $result
    }
    foreach ($key in $values.Keys) { $null = Resolve-DotEnvValue $key }
    return $resolved
}

function Import-RootEnv {
    $root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
    $envPath = Join-Path $root '.env'
    if (!(Test-Path -LiteralPath $envPath)) { throw 'Create the root .env from .env.example first.' }
    $settings = Read-DotEnv $envPath
    foreach ($required in @('POSTGRES_DB','POSTGRES_USER','POSTGRES_PASSWORD','POSTGRES_PORT','BACKEND_PORT','JWT_SECRET')) {
        if (!$settings.ContainsKey($required) -or [string]::IsNullOrWhiteSpace($settings[$required])) { throw "Missing root ENV setting: $required" }
    }
    foreach ($portName in @('POSTGRES_PORT','BACKEND_PORT')) {
        $port = 0
        if (![int]::TryParse($settings[$portName], [ref]$port) -or $port -lt 1 -or $port -gt 65535) { throw "Invalid port: $portName" }
    }
    foreach ($key in $settings.Keys) { [Environment]::SetEnvironmentVariable($key, $settings[$key], 'Process') }
    # Derived host connection always follows the published Compose port.
    $env:DB_URL = "jdbc:postgresql://localhost:$($settings.POSTGRES_PORT)/$($settings.POSTGRES_DB)"
    $env:DB_USERNAME = $settings.POSTGRES_USER
    $env:DB_PASSWORD = $settings.POSTGRES_PASSWORD
    $env:SERVER_PORT = $settings.BACKEND_PORT
    return $settings
}

function Set-RootEnvValue {
    param([Parameter(Mandatory)][string]$Name, [AllowEmptyString()][string]$Value)
    if ($Name -notmatch '^[A-Z][A-Z0-9_]*$' -or $Value.Contains("`n") -or $Value.Contains("`r")) { throw 'Invalid ENV update.' }
    $envPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../.env'))
    $lines = [Collections.Generic.List[string]]::new()
    $found = $false
    $encoded = "'" + $Value.Replace("'", "\'") + "'"
    foreach ($line in [IO.File]::ReadAllLines($envPath)) {
        if ($line -match "^\s*$Name\s*=") { $lines.Add("$Name=$encoded"); $found=$true }
        else { $lines.Add($line) }
    }
    if (!$found) { $lines.Add("$Name=$encoded") }
    [IO.File]::WriteAllLines($envPath, $lines, [Text.UTF8Encoding]::new($false))
}
