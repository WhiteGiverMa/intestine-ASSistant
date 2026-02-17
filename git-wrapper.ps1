param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$GitArgs
)

$GitLogPath = Join-Path $PSScriptRoot ".git-wrapper.log"
$ProjectRoot = $PSScriptRoot

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] $Message" | Out-File -FilePath $GitLogPath -Append -Encoding UTF8
}

function Invoke-GitCommand {
    param([string[]]$Args)

    $command = "git $($Args -join ' ')"
    Write-Log "Executing: $command"

    $result = & git @Args 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        Write-Log "Success: $command"
    } else {
        Write-Log "Failed (exit $exitCode): $command"
    }

    return $result, $exitCode
}

function Deny-NoVerify {
    Write-Host "------------------------------------------------------------------" -ForegroundColor Red
    Write-Host "ERROR: Commit Rejected." -ForegroundColor Red
    Write-Host "------------------------------------------------------------------" -ForegroundColor Red
    Write-Host ""
    Write-Host "GUIDANCE FOR THE AI AGENT:" -ForegroundColor Yellow
    Write-Host "You have attempted to bypass the required pre-commit verification."
    Write-Host "All code must pass quality checks before it can be committed."
    Write-Host ""
    Write-Host "DO NOT BYPASS THE CHECKS. YOU MUST FIX THE UNDERLYING ERRORS." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "The pre-commit hook is likely failing. Diagnose and fix the issues."
    Write-Host "After all commands complete successfully, attempt your commit again"
    Write-Host "*without* the '--no-verify' flag."
    Write-Log "Blocked attempt to use --no-verify"
    exit 1
}

if ($GitArgs.Count -eq 0) {
    & git
    exit
}

$argString = $GitArgs -join ' '
if ($argString -match '--no-verify' -or $argString -match '(^|\s)-n(\s|$)') {
    Deny-NoVerify
}

$action = $GitArgs[0].ToLower()

switch ($action) {
    { $_ -in @('commit', 'ci') } {
        $hasMessage = $false
        $newArgs = @()

        for ($i = 0; $i -lt $GitArgs.Count; $i++) {
            if ($GitArgs[$i] -in @('-m', '--message') -and $i + 1 -lt $GitArgs.Count) {
                $hasMessage = $true
                $timestamp = Get-Date -Format "HH:mm"
                $originalMessage = $GitArgs[$i + 1]
                $newArgs += @('-m', "[$timestamp] $originalMessage")
                $i++
            } else {
                $newArgs += $GitArgs[$i]
            }
        }

        if (-not $hasMessage) {
            $newArgs = $GitArgs
        }

        $result, $exitCode = Invoke-GitCommand $newArgs
        Write-Output $result
        exit $exitCode
    }

    'quick-commit' {
        $status = & git status --porcelain 2>&1
        if ($status) {
            & git add -A
            $timestamp = Get-Date -Format "HH:mm"
            $result = & git commit -m "[$timestamp] Auto commit" 2>&1
            Write-Output $result
            Write-Log "Quick commit executed"
        } else {
            Write-Output "Nothing to commit"
        }
        exit
    }

    'sync' {
        Write-Output "Pulling changes..."
        & git pull
        Write-Output "Pushing changes..."
        & git push
        Write-Log "Sync executed"
        exit
    }

    'undo' {
        if ($GitArgs.Count -gt 1 -and $GitArgs[1] -eq '--hard') {
            & git reset --hard HEAD~1
        } else {
            & git reset --soft HEAD~1
        }
        Write-Log "Undo executed"
        exit
    }

    'branches' {
        & git branch -a
        exit
    }

    'discard' {
        & git checkout -- .
        & git clean -fd
        Write-Output "All uncommitted changes discarded"
        Write-Log "Discard executed"
        exit
    }

    'log-pretty' {
        & git log --graph --oneline --all --decorate -20
        exit
    }

    'status-short' {
        & git status -s
        exit
    }

    default {
        $result, $exitCode = Invoke-GitCommand $GitArgs
        Write-Output $result
        exit $exitCode
    }
}
