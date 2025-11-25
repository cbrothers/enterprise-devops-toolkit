# Start-Issue.ps1
# Helper to start working on a new issue with proper git workflow
# IDEMPOTENT: Safe to run multiple times

param(
    [Parameter(Mandatory = $true)]
    [int]$IssueNumber,
    
    [Parameter(Mandatory = $false)]
    [string]$BranchSuffix
)

$ErrorActionPreference = "Stop"

Write-Host "`n🚀 Starting work on Issue #$IssueNumber..." -ForegroundColor Cyan

# 1. Fetch issue details
Write-Host "📋 Fetching issue details..." -ForegroundColor Yellow
$issueJson = gh issue view $IssueNumber --json title, body, labels 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to fetch issue #$IssueNumber" -ForegroundColor Red
    exit 1
}

$issue = $issueJson | ConvertFrom-Json
$issueTitle = $issue.title -replace '[^a-zA-Z0-9\s]', '' -replace '\s+', '-' | ForEach-Object { $_.ToLower() }

# Use provided suffix or generate from title
if (-not $BranchSuffix) {
    $BranchSuffix = $issueTitle.Substring(0, [Math]::Min(30, $issueTitle.Length))
}

$branchName = "feature/issue-$IssueNumber-$BranchSuffix"

# 2. Create and checkout branch (or just checkout if exists)
Write-Host "🌿 Checking branch: $branchName" -ForegroundColor Yellow
$branchExists = git branch --list $branchName
if ($branchExists) {
    Write-Host "   ✓ Branch exists, checking out..." -ForegroundColor Gray
    git checkout $branchName 2>&1 | Out-Null
}
else {
    Write-Host "   ✓ Creating new branch..." -ForegroundColor Gray
    git checkout -b $branchName 2>&1 | Out-Null
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to checkout/create branch" -ForegroundColor Red
    exit 1
}

# 3. Update issue status and move on project board
Write-Host "📝 Updating issue status and project board..." -ForegroundColor Yellow
& "$PSScriptRoot\issue-update-enhanced.ps1" -InputJson (@{
        issue_number = $IssueNumber
        action       = "start"
        comment      = "Working on feature branch: $branchName"
    } | ConvertTo-Json -Compress) | Out-Null

# 4. Display issue info
Write-Host "`n✅ Ready to work on Issue #$IssueNumber" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Title: " -NoNewline -ForegroundColor White
Write-Host $issue.title -ForegroundColor Yellow
Write-Host "Branch: " -NoNewline -ForegroundColor White
Write-Host $branchName -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

return @{
    IssueNumber = $IssueNumber
    Title       = $issue.title
    Branch      = $branchName
}
