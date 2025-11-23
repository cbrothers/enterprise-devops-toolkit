# Get-DeploymentStatus.ps1
# Displays deployment status across all environments

param(
    [Parameter(Mandatory = $false)]
    [string]$ProjectName,
    
    [Parameter(Mandatory = $false)]
    [hashtable]$Environments = @{
        "Stage"      = "https://stage.thesilentwhistleband.com"
        "Production" = "https://www.thesilentwhistleband.com"
    }
)

$ErrorActionPreference = "Continue"

# Auto-detect project name from git remote if not provided
if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    $remote = git config --get remote.origin.url 2>$null
    if ($remote -match '([^/]+)\.git$') {
        $ProjectName = $matches[1]
    }
    else {
        $ProjectName = (Get-Item -Path ".").Name
    }
}

# Get current branch info
$currentBranch = git branch --show-current 2>$null

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          DEPLOYMENT STATUS DASHBOARD                          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n📦 Project: " -NoNewline -ForegroundColor Yellow
Write-Host $ProjectName -ForegroundColor White

Write-Host "🌿 Current Branch: " -NoNewline -ForegroundColor Yellow
Write-Host $currentBranch -ForegroundColor White

Write-Host "`n" + "─" * 64 -ForegroundColor Gray

# Fetch latest from remote
Write-Host "`n🔄 Fetching latest from remote..." -ForegroundColor Gray
git fetch origin --quiet 2>$null

# Display branch status
$branches = @("main", "stage", "production")

Write-Host "`n📊 BRANCH STATUS`n" -ForegroundColor Cyan

foreach ($branch in $branches) {
    $exists = git rev-parse --verify "origin/$branch" 2>$null
    if ($exists) {
        $commit = git log -n 1 origin/$branch --format="%h - %s (%cr)" 2>$null
        $color = switch ($branch) {
            "main" { "White" }
            "stage" { "Yellow" }
            "production" { "Green" }
        }
        
        Write-Host "  $branch".PadRight(15) -NoNewline -ForegroundColor $color
        Write-Host $commit -ForegroundColor Gray
    }
}

# Display environment status
Write-Host "`n🌐 ENVIRONMENT STATUS`n" -ForegroundColor Cyan

foreach ($env in $Environments.GetEnumerator()) {
    $envName = $env.Key
    $url = $env.Value
    
    Write-Host "  $envName".PadRight(15) -NoNewline -ForegroundColor Yellow
    Write-Host $url -NoNewline -ForegroundColor Gray
    
    # Try to check if site is accessible
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        Write-Host " ✅" -ForegroundColor Green
    }
    catch {
        Write-Host " ⚠️  (unreachable)" -ForegroundColor Red
    }
}

Write-Host "`n" + "─" * 64 -ForegroundColor Gray

# Show what's ahead/behind
Write-Host "`n📈 DEPLOYMENT PIPELINE`n" -ForegroundColor Cyan

$mainCommit = git rev-parse origin/main 2>$null
$stageCommit = git rev-parse origin/stage 2>$null
$prodCommit = git rev-parse origin/production 2>$null

if ($stageCommit -eq $mainCommit) {
    Write-Host "  Stage ↔ Main:       " -NoNewline
    Write-Host "✅ In Sync" -ForegroundColor Green
}
else {
    $ahead = (git rev-list --count origin/stage..origin/main 2>$null)
    Write-Host "  Stage ← Main:       " -NoNewline
    Write-Host "⚠️  $ahead commit(s) behind" -ForegroundColor Yellow
}

if ($prodCommit -eq $stageCommit) {
    Write-Host "  Production ↔ Stage: " -NoNewline
    Write-Host "✅ In Sync" -ForegroundColor Green
}
else {
    $ahead = (git rev-list --count origin/production..origin/stage 2>$null)
    Write-Host "  Production ← Stage: " -NoNewline
    Write-Host "⚠️  $ahead commit(s) behind" -ForegroundColor Yellow
}

Write-Host ""
