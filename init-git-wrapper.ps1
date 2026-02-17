$WrapperScript = Join-Path $PSScriptRoot "git-wrapper.ps1"

function global:git {
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )
    & $WrapperScript @Args
}

Set-Alias -Name g -Value git -Force -ErrorAction SilentlyContinue

Write-Host "Git wrapper loaded!" -ForegroundColor Green
Write-Host "Available commands: quick-commit, sync, undo, discard, branches, log-pretty, status-short" -ForegroundColor Cyan
