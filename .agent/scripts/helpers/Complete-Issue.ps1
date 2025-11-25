# Complete-Issue.ps1
# Helper to complete an issue and merge to main
# IDEMPOTENT: Checks state before each operation

param(
    [Parameter(Mandatory = $true)]
    [int]$IssueNumber,
    
    [Parameter(Mandatory = $false)]
    [string]$Summary,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipChecklist
)

$ErrorActionPreference = "Stop"

Write-Host "`n🏁 Completing Issue #$IssueNumber..." -ForegroundColor Cyan

# Get current branch
$currentBranch = git branch --show-current

# Check if already on main
if ($currentBranch -eq "main") {
    Write-Host "⚠️  Already on main branch. Nothing to merge." -ForegroundColor Yellow
    exit 0
}

# 1. Run pre-merge checklist
if (-not $SkipChecklist) {
    Write-Host "🔍 Running pre-merge checklist..." -ForegroundColor Yellow
    & "$PSScriptRoot\..\Pre-Merge-Checklist.ps1" -Quick
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Pre-merge checklist failed" -ForegroundColor Red
        exit 1
    }
}

# 2. Commit any uncommitted changes
$status = git status --porcelain
if ($status) {
    Write-Host "📝 Committing final changes..." -ForegroundColor Yellow
    git add -A
    git commit -m "chore: final cleanup for issue #$IssueNumber" 2>&1 | Out-Null
}

# 3. Switch to main
Write-Host "🔄 Switching to main..." -ForegroundColor Yellow
git checkout main 2>&1 | Out-Null

# 4. Merge feature branch
Write-Host "🔀 Merging $currentBranch..." -ForegroundColor Yellow
git merge $currentBranch --no-ff -m "Merge $currentBranch into main" 2>&1 | Out-Null

# 5. Push to GitHub
Write-Host "⬆️  Pushing to GitHub..." -ForegroundColor Yellow
git push origin main 2>&1 | Out-Null

# 6. Delete feature branch
Write-Host "🗑️  Cleaning up branch..." -ForegroundColor Yellow
git branch -d $currentBranch 2>&1 | Out-Null

# 7. Update issue and move on project board
Write-Host "✅ Marking issue as complete and updating project board..." -ForegroundColor Yellow
$comment = if ($Summary) { $Summary } else { "Issue completed and merged to main" }
& "$PSScriptRoot\issue-update-enhanced.ps1" -InputJson (@{
        issue_number = $IssueNumber
        action       = "complete"
        comment      = $comment
    } | ConvertTo-Json -Compress) | Out-Null

Write-Host "`n🎉 Issue #$IssueNumber completed successfully!`n" -ForegroundColor Green
