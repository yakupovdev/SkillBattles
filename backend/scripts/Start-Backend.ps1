[CmdletBinding()]
param(
    [ValidateSet('Run','Jar','Verify','Check','ImportQuestions')][string]$Action = 'Run',
    [string]$QuestionsFile,
    [switch]$Apply
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'RootEnv.ps1')
$null = Import-RootEnv
if ($Action -eq 'Check') {
    Write-Host 'Root ENV loaded; host JDBC and server ports resolved. No secrets displayed.'
    return
}
if ($env:JAVA_HOME -and (Test-Path (Join-Path $env:JAVA_HOME 'bin/java.exe'))) {
    $env:PATH = (Join-Path $env:JAVA_HOME 'bin') + [IO.Path]::PathSeparator + $env:PATH
}
if ($Action -eq 'ImportQuestions' -and !$QuestionsFile) { throw '-QuestionsFile is required.' }
if ($QuestionsFile) { $QuestionsFile = (Resolve-Path -LiteralPath $QuestionsFile).Path }
Push-Location (Join-Path $PSScriptRoot '..')
try {
    switch ($Action) {
        'Run' { & ./mvnw.cmd spring-boot:run }
        'Verify' { & ./mvnw.cmd -B -ntp verify }
        'Jar' { & java '-Duser.timezone=UTC' -jar target/backend-0.0.1-SNAPSHOT.jar }
        'ImportQuestions' {
            & java '-Duser.timezone=UTC' -jar target/backend-0.0.1-SNAPSHOT.jar --spring.profiles.active=question-import "--questions.file=$QuestionsFile" "--questions.apply=$($Apply.IsPresent.ToString().ToLowerInvariant())"
        }
    }
    if ($LASTEXITCODE -ne 0) { throw "Backend command failed (exit $LASTEXITCODE)." }
} finally { Pop-Location }
