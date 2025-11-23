# Inject-Version.ps1
# Replaces version placeholders in HTML files with actual git commit info

$gitHash = git rev-parse --short HEAD
$buildDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm") + " UTC"

$files = @(
    "public/index.html",
    "public/privacy-policy.html"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        $content = $content -replace '{{GIT_COMMIT_HASH}}', $gitHash
        $content = $content -replace '{{BUILD_DATE}}', $buildDate
        $content | Set-Content $file -NoNewline
        
        Write-Host "✅ Version injected into $file" -ForegroundColor Green
    }
    else {
        Write-Warning "File not found: $file"
    }
}

Write-Host "`n📌 Version: $gitHash ($buildDate)" -ForegroundColor Cyan
