# Review-Code.ps1
# Automated code review with security and quality checks

param(
    [string]$BaseBranch = "main",
    [string]$FeatureBranch = (git branch --show-current),
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    CODE REVIEW REPORT                         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n📊 Comparing: " -NoNewline -ForegroundColor Yellow
Write-Host "$FeatureBranch → $BaseBranch`n" -ForegroundColor White

# Get diff
$diff = git diff $BaseBranch...$FeatureBranch

if (-not $diff) {
    Write-Host "✅ No changes detected" -ForegroundColor Green
    exit 0
}

$issues = @()
$warnings = @()
$info = @()

# ---------------------------------------------------------
# Security Checks
# ---------------------------------------------------------

Write-Host "🔒 SECURITY ANALYSIS`n" -ForegroundColor Cyan

# Check 1: Hardcoded credentials
$credentialPatterns = @(
    '(password|passwd|pwd)\s*=\s*["\'][^"\']{3,}["\']',
    '(api[_-]?key|apikey)\s*=\s*["\'][^"\']{10,}["\']',
    '(secret|token)\s*=\s*["\'][^"\']{10,}["\']',
    'Authorization:\s*Bearer\s+[A-Za-z0-9\-_]+'
)

foreach ($pattern in $credentialPatterns) {
    $foundMatches = $diff | Select-String -Pattern $pattern
    if ($foundMatches) {
        $issues += "🚨 CRITICAL: Potential hardcoded credentials detected"
        if ($Verbose) {
            foreach ($match in $foundMatches) {
                $issues += "    Line: $($match.Line.Trim())"
            }
        }
    }
}

# Check 2: Insecure functions
$insecureFunctions = @(
    @{Pattern = 'Invoke-Expression|iex\s'; Name = 'Invoke-Expression (code injection risk)' },
    @{Pattern = 'ConvertTo-SecureString\s+-AsPlainText'; Name = 'ConvertTo-SecureString -AsPlainText (insecure)' },
    @{Pattern = 'eval\('; Name = 'eval() (code injection risk)' },
    @{Pattern = 'innerHTML\s*='; Name = 'innerHTML (XSS risk)' }
)

foreach ($func in $insecureFunctions) {
    $foundMatches = $diff | Select-String -Pattern $func.Pattern
    if ($foundMatches) {
        $warnings += "⚠️  WARNING: Potentially insecure function: $($func.Name)"
    }
}

# ---------------------------------------------------------

Write-Host "`n" + "─" * 64 -ForegroundColor Gray
Write-Host "`n📋 SUMMARY`n" -ForegroundColor Cyan

$totalIssues = $issues.Count + $warnings.Count + $info.Count

if ($totalIssues -eq 0) {
    Write-Host "✅ No issues detected - code looks good!" -ForegroundColor Green
    exit 0
}

# Critical Issues
if ($issues.Count -gt 0) {
    Write-Host "🚨 CRITICAL ISSUES ($($issues.Count)):`n" -ForegroundColor Red
    $issues | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    Write-Host ""
}

# Warnings
if ($warnings.Count -gt 0) {
    Write-Host "⚠️  WARNINGS ($($warnings.Count)):`n" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
    Write-Host ""
}

# Suggestions
if ($info.Count -gt 0) {
    Write-Host "💡 SUGGESTIONS ($($info.Count)):`n" -ForegroundColor Gray
    $info | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    Write-Host ""
}

# Exit code
if ($issues.Count -gt 0) {
    Write-Host "❌ Review failed - critical issues must be addressed" -ForegroundColor Red
    exit 1
}
elseif ($warnings.Count -gt 0) {
    Write-Host "⚠️  Review passed with warnings - consider addressing before merge" -ForegroundColor Yellow
    exit 0
}
else {
    Write-Host "✅ Review passed - only minor suggestions" -ForegroundColor Green
    exit 0
}
