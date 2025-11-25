# Sync-Branch.ps1
# Helper to sync feature branch with main

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$currentBranch = git branch --show-current

if ($currentBranch -eq "main") {
    Write-Host "⚠️  Already on main branch" -ForegroundColor Yellow
    exit 0
}

Write-Host "🔄 Syncing $currentBranch with main..." -ForegroundColor Cyan

# Stash changes if any
$hasChanges = git status --porcelain
if ($hasChanges) {
    Write-Host "💾 Stashing uncommitted changes..." -ForegroundColor Yellow
    git stash
}

# Fetch and merge main
Write-Host "⬇️  Fetching latest main..." -ForegroundColor Yellow
git fetch origin main

Write-Host "🔀 Merging main into $currentBranch..." -ForegroundColor Yellow
git merge origin/main

# Pop stash if we stashed
if ($hasChanges) {
    Write-Host "📤 Restoring stashed changes..." -ForegroundColor Yellow
    git stash pop
}

Write-Host "✅ Branch synced successfully!" -ForegroundColor Green
