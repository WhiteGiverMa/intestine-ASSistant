$files = @(
    "backend/app/routers/ai.py",
    "backend/app/routers/auth.py",
    "backend/app/services/llm_service.py",
    "frontend_ReactWeb/src/api/index.ts",
    "frontend_ReactWeb/src/pages/Register.tsx",
    "frontend_ReactWeb/src/pages/Settings.tsx",
    "migrate_add_ai_config.py"
)

foreach ($file in $files) {
    $fullPath = Join-Path $PSScriptRoot $file
    if (Test-Path $fullPath) {
        $content = Get-Content $fullPath -Raw
        $newContent = $content -replace '[ \t]+(\r?\n)', '$1'
        if ($content -ne $newContent) {
            Set-Content -Path $fullPath -Value $newContent -NoNewline
            Write-Host "Fixed: $file"
        } else {
            Write-Host "Clean: $file"
        }
    }
}
