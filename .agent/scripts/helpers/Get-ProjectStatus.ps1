# Get-ProjectStatus.ps1
# Helper to get comprehensive project status

param(
    [switch]$Detailed
)

$ErrorActionPreference = "Stop"

Write-Host "`n📊 Project Status Report" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════`n" -ForegroundColor Cyan

# Git info
$currentBranch = git branch --show-current
$uncommitted = git status --porcelain
Write-Host "🌿 Branch: " -NoNewline -ForegroundColor White
Write-Host $currentBranch -ForegroundColor Yellow

if ($uncommitted) {
    Write-Host "📝 Uncommitted changes: " -NoNewline -ForegroundColor White
    Write-Host "Yes" -ForegroundColor Yellow
}
else {
    Write-Host "📝 Uncommitted changes: " -NoNewline -ForegroundColor White
    Write-Host "None" -ForegroundColor Green
}

# Issue stats
Write-Host "`n📋 GitHub Issues:" -ForegroundColor Cyan
$issues = gh issue list --json number, title, state, labels --limit 100 2>&1 | ConvertFrom-Json

$open = ($issues | Where-Object { $_.state -eq "OPEN" }).Count
$closed = ($issues | Where-Object { $_.state -eq "CLOSED" }).Count
$total = $issues.Count

Write-Host "   Open: $open" -ForegroundColor Yellow
Write-Host "   Closed: $closed" -ForegroundColor Green
Write-Host "   Total: $total" -ForegroundColor White
Write-Host "   Progress: $([Math]::Round(($closed / $total) * 100, 1))%" -ForegroundColor Cyan

if ($Detailed) {
    Write-Host "`n📌 Open Issues:" -ForegroundColor Cyan
    $issues | Where-Object { $_.state -eq "OPEN" } | ForEach-Object {
        Write-Host "   #$($_.number): $($_.title)" -ForegroundColor Gray
    }
}

# Recent commits
Write-Host "`n📝 Recent Commits (last 5):" -ForegroundColor Cyan
git log --oneline -5 | ForEach-Object {
    Write-Host "   $_" -ForegroundColor Gray
}

Write-Host "`n═══════════════════════════════════════`n" -ForegroundColor Cyan
