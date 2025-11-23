# Onboard-Developer.ps1
# Automated developer onboarding and environment setup

param(
    [string]$DeveloperName,
    [switch]$SkipOptional
)

$ErrorActionPreference = "Continue"

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              DEVELOPER ONBOARDING WIZARD                      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

if ([string]::IsNullOrWhiteSpace($DeveloperName)) {
    $DeveloperName = Read-Host "`n👋 Welcome! What's your name?"
}

Write-Host "`n🎉 Welcome to the team, $DeveloperName!`n" -ForegroundColor Green

$checks = @{
    Passed   = @()
    Failed   = @()
    Warnings = @()
}

# ---------------------------------------------------------
# Check Required Tools
# ---------------------------------------------------------

Write-Host "🔍 Checking required tools...`n" -ForegroundColor Cyan

# Git
Write-Host "  Checking Git... " -NoNewline
try {
    $gitVersion = git --version 2>$null
    if ($gitVersion) {
        Write-Host "✅ $gitVersion" -ForegroundColor Green
        $checks.Passed += "Git"
    }
    else {
        throw "Not found"
    }
}
catch {
    Write-Host "❌ Not installed" -ForegroundColor Red
    $checks.Failed += "Git - Download from https://git-scm.com/"
}

# PowerShell Version
Write-Host "  Checking PowerShell... " -NoNewline
$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -ge 5) {
    Write-Host "✅ Version $psVersion" -ForegroundColor Green
    $checks.Passed += "PowerShell"
}
else {
    Write-Host "⚠️  Version $psVersion (upgrade recommended)" -ForegroundColor Yellow
    $checks.Warnings += "PowerShell - Consider upgrading to PowerShell 7+"
}

# Pester
Write-Host "  Checking Pester... " -NoNewline
try {
    $pesterModule = Get-Module -ListAvailable -Name Pester | Sort-Object Version -Descending | Select-Object -First 1
    if ($pesterModule) {
        Write-Host "✅ Version $($pesterModule.Version)" -ForegroundColor Green
        $checks.Passed += "Pester"
    }
    else {
        throw "Not found"
    }
}
catch {
    Write-Host "⚠️  Not installed" -ForegroundColor Yellow
    $checks.Warnings += "Pester - Install with: Install-Module -Name Pester -Force"
}

# ---------------------------------------------------------
# Check Optional Tools
# ---------------------------------------------------------

if (-not $SkipOptional) {
    Write-Host "`n🔍 Checking optional tools...`n" -ForegroundColor Cyan
    
    # VS Code
    Write-Host "  Checking VS Code... " -NoNewline
    try {
        $codeVersion = code --version 2>$null
        if ($codeVersion) {
            Write-Host "✅ Installed" -ForegroundColor Green
        }
        else {
            throw "Not found"
        }
    }
    catch {
        Write-Host "💡 Not installed (recommended)" -ForegroundColor Gray
    }
    
    # Docker
    Write-Host "  Checking Docker... " -NoNewline
    try {
        $dockerVersion = docker --version 2>$null
        if ($dockerVersion) {
            Write-Host "✅ $dockerVersion" -ForegroundColor Green
        }
        else {
            throw "Not found"
        }
    }
    catch {
        Write-Host "💡 Not installed (optional)" -ForegroundColor Gray
    }
}

# ---------------------------------------------------------
# Git Configuration
# ---------------------------------------------------------

Write-Host "`n⚙️  Configuring Git...`n" -ForegroundColor Cyan

$gitUserName = git config --global user.name 2>$null
$gitUserEmail = git config --global user.email 2>$null

if ([string]::IsNullOrWhiteSpace($gitUserName)) {
    $gitUserName = Read-Host "  Enter your Git name (e.g., John Doe)"
    git config --global user.name $gitUserName
    Write-Host "  ✅ Set Git user.name" -ForegroundColor Green
}
else {
    Write-Host "  ✅ Git user.name: $gitUserName" -ForegroundColor Green
}

if ([string]::IsNullOrWhiteSpace($gitUserEmail)) {
    $gitUserEmail = Read-Host "  Enter your Git email"
    git config --global user.email $gitUserEmail
    Write-Host "  ✅ Set Git user.email" -ForegroundColor Green
}
else {
    Write-Host "  ✅ Git user.email: $gitUserEmail" -ForegroundColor Green
}

# Recommended Git settings
git config --global core.autocrlf false
git config --global core.eol lf
git config --global pull.rebase false

Write-Host "  ✅ Applied recommended Git settings" -ForegroundColor Green

# ---------------------------------------------------------
# Repository Setup
# ---------------------------------------------------------

Write-Host "`n📦 Setting up repository...`n" -ForegroundColor Cyan

# Check if we're in a Git repository
$isGitRepo = Test-Path ".git"

if ($isGitRepo) {
    Write-Host "  ✅ Already in a Git repository" -ForegroundColor Green
    
    # Fetch latest
    Write-Host "  📥 Fetching latest changes..." -ForegroundColor Gray
    git fetch origin --quiet
    
    # Check branch
    $currentBranch = git branch --show-current
    Write-Host "  ✅ Current branch: $currentBranch" -ForegroundColor Green
}
else {
    Write-Host "  ⚠️  Not in a Git repository" -ForegroundColor Yellow
    Write-Host "  💡 Clone the repository first" -ForegroundColor Gray
}

# ---------------------------------------------------------
# Run Tests
# ---------------------------------------------------------

Write-Host "`n🧪 Running initial tests...`n" -ForegroundColor Cyan

if (Test-Path ".agent/scripts/Run-Tests.ps1") {
    try {
        & .agent/scripts/Run-Tests.ps1
        Write-Host "`n  ✅ Tests passed!" -ForegroundColor Green
        $checks.Passed += "Initial tests"
    }
    catch {
        Write-Host "`n  ⚠️  Some tests failed (this is okay for now)" -ForegroundColor Yellow
        $checks.Warnings += "Initial tests - Review failures with your mentor"
    }
}
else {
    Write-Host "  💡 No test script found (skipping)" -ForegroundColor Gray
}

# ---------------------------------------------------------
# Generate Summary
# ---------------------------------------------------------

Write-Host "`n" + "─" * 64 -ForegroundColor Gray
Write-Host "`n📋 ONBOARDING SUMMARY`n" -ForegroundColor Cyan

if ($checks.Passed.Count -gt 0) {
    Write-Host "✅ PASSED ($($checks.Passed.Count)):`n" -ForegroundColor Green
    $checks.Passed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Green }
    Write-Host ""
}

if ($checks.Warnings.Count -gt 0) {
    Write-Host "⚠️  WARNINGS ($($checks.Warnings.Count)):`n" -ForegroundColor Yellow
    $checks.Warnings | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host ""
}

if ($checks.Failed.Count -gt 0) {
    Write-Host "❌ FAILED ($($checks.Failed.Count)):`n" -ForegroundColor Red
    $checks.Failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host ""
}

# ---------------------------------------------------------
# Next Steps
# ---------------------------------------------------------

Write-Host "🚀 NEXT STEPS`n" -ForegroundColor Cyan

Write-Host "  1. Read the documentation:" -ForegroundColor White
Write-Host "     - README.md" -ForegroundColor Gray
Write-Host "     - .agent/workflows/ (workflow guides)" -ForegroundColor Gray

Write-Host "`n  2. Try the Smart Patch workflow:" -ForegroundColor White
Write-Host "     - See .agent/workflows/smart-edit.md" -ForegroundColor Gray

Write-Host "`n  3. Run code review on a branch:" -ForegroundColor White
Write-Host "     - .agent/scripts/Review-Code.ps1" -ForegroundColor Gray

Write-Host "`n  4. Ask your mentor for a 'good first issue'" -ForegroundColor White

Write-Host "`n  5. Join team communication channels" -ForegroundColor White

Write-Host ""

# Final message
if ($checks.Failed.Count -eq 0) {
    Write-Host "🎉 You're all set, $DeveloperName! Happy coding!" -ForegroundColor Green
}
else {
    Write-Host "⚠️  Please address the failed checks above before proceeding" -ForegroundColor Yellow
}

Write-Host ""
