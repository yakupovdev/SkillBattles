$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'RootEnv.ps1')
$testDir = Join-Path $PSScriptRoot '../target/env-check'
$null = New-Item -ItemType Directory -Path $testDir -Force
$fixture = Join-Path $testDir 'parser.txt'
$marker = Join-Path $testDir 'must-not-exist.txt'
try {
    # Literal shell syntax must stay data; never create this marker file.
    $data = @'
BASE=55432
URL=jdbc:postgresql://localhost:${BASE}/test
SINGLE='literal $HOME # and ${BASE}' # comment
DOUBLE="quoted # text ${BASE}"
PASSWORD='literal\'quote$#'
EMPTY=
UNTRUSTED=$(Set-Content -LiteralPath '__MARKER__' -Value executed)
'@.Replace('__MARKER__', $marker.Replace("'", "''"))
    [IO.File]::WriteAllText($fixture, $data)
    $parsed = Read-DotEnv $fixture
    if ($parsed.URL -ne 'jdbc:postgresql://localhost:55432/test' -or
        $parsed.SINGLE -ne 'literal $HOME # and ${BASE}' -or
        $parsed.DOUBLE -ne 'quoted # text 55432' -or
        $parsed.PASSWORD -ne "literal'quote`$#" -or
        $parsed.EMPTY -ne '' -or !( $parsed.UNTRUSTED.StartsWith('$(')) -or
        (Test-Path -LiteralPath $marker)) { throw 'ENV quoting/reference/no-execution check failed.' }
    foreach ($invalid in @(
        ('DUP=one' + "`n" + 'DUP=two'),
        'A=${B}',
        ('A=${B}' + "`n" + 'B=${A}'),
        'INVALID LINE',
        'A="unterminated'
    )) {
        [IO.File]::WriteAllText($fixture, $invalid)
        $rejected = $false
        try { $null = Read-DotEnv $fixture } catch { $rejected = $true }
        if (!$rejected) { throw 'Invalid ENV syntax/reference was accepted.' }
    }
    Write-Host 'ENV checks passed: quoting, references, literal commands, duplicates, undefined/cyclic references and malformed lines.'
} finally {
    Remove-Item -LiteralPath $fixture -ErrorAction SilentlyContinue
}
