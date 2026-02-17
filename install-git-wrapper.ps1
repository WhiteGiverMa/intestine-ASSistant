param(
    [switch]$Uninstall
)

$WrapperPath = $PSScriptRoot
$WrapperScript = Join-Path $WrapperPath "git-wrapper.ps1"
$ProfileDir = Split-Path $PROFILE -Parent
$WrapperFunctionName = "git-wrapper"

if ($Uninstall) {
    Write-Host "Uninstalling git-wrapper..." -ForegroundColor Yellow

    $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if ($profileContent) {
        $pattern = "(?ms)# Git Wrapper Start.*?# Git Wrapper End\r?\n?"
        $newContent = $profileContent -replace $pattern, ""
        Set-Content -Path $PROFILE -Value $newContent -NoNewline

        Write-Host "Git wrapper uninstalled successfully!" -ForegroundColor Green
        Write-Host "Please restart your PowerShell session." -ForegroundColor Cyan
    }
    exit
}

if (-not (Test-Path $WrapperScript)) {
    Write-Host "Error: git-wrapper.ps1 not found in $WrapperPath" -ForegroundColor Red
    exit 1
}

Write-Host "Installing git-wrapper..." -ForegroundColor Cyan
Write-Host "Wrapper script: $WrapperScript" -ForegroundColor Gray

if (-not (Test-Path $ProfileDir)) {
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
}

$wrapperBlock = @"

# Git Wrapper Start
function global:git {
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments = `$true)]
        [string[]]`$Args
    )
    & "$WrapperScript" @Args
}
Set-Alias -Name g -Value git -Force -ErrorAction SilentlyContinue
# Git Wrapper End
"@

if (Test-Path $PROFILE) {
    $profileContent = Get-Content $PROFILE -Raw

    if ($profileContent -match "# Git Wrapper Start") {
        $pattern = "(?ms)# Git Wrapper Start.*?# Git Wrapper End"
        $newContent = $profileContent -replace $pattern, $wrapperBlock.TrimEnd()
        Set-Content -Path $PROFILE -Value $newContent -NoNewline
        Write-Host "Git wrapper updated in profile!" -ForegroundColor Green
    } else {
        Add-Content -Path $PROFILE -Value $wrapperBlock
        Write-Host "Git wrapper added to profile!" -ForegroundColor Green
    }
} else {
    $ProfileDir = Split-Path $PROFILE -Parent
    if (-not (Test-Path $ProfileDir)) {
        New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
    }
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    Set-Content -Path $PROFILE -Value $wrapperBlock.TrimEnd()
    Write-Host "Created profile and added git wrapper!" -ForegroundColor Green
}

Write-Host @"

Installation complete!
To activate, run: . `$PROFILE
Or restart your PowerShell session.

Available git wrapper commands:
  git quick-commit  - Add all and commit with timestamp
  git sync          - Pull and push in one command
  git undo          - Soft reset last commit (use --hard for hard reset)
  git discard       - Discard all uncommitted changes
  git branches      - List all branches
  git log-pretty    - Pretty git log graph
  git status-short  - Short status

Regular git commands work as normal, with logging enabled.
"@ -ForegroundColor Cyan
