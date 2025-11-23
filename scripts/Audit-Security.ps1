# Audit-Security.ps1
# Security vulnerability scanner

param(
    [string]$ScanPath = ".",
    [switch]$Verbose,
    [string]$ReportFile = ".agent/tmp/security-report.txt"
)

$ErrorActionPreference = "Continue"

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    SECURITY AUDIT REPORT                      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n📁 Scanning: $ScanPath`n" -ForegroundColor Yellow

$findings = @()
$critical = @()
$high = @()
$medium = @()
$low = @()

# ---------------------------------------------------------
'MEDIUM' { $medium += $finding }
'LOW' { $low += $finding }
}
}
}
}
}

# ---------------------------------------------------------
# File Permission Checks (Unix/Linux)
# ---------------------------------------------------------

if ($IsLinux -or $IsMacOS) {
    Write-Host "🔍 Checking file permissions...`n" -ForegroundColor Cyan
    
    $worldWritable = Get-ChildItem -Path $ScanPath -Recurse -File | 
    Where-Object { 
        $mode = (Get-Item $_.FullName).UnixMode
        $mode -match '......w.w'  # World writable
    }
    
    if ($worldWritable) {
        foreach ($file in $worldWritable) {
            $medium += "⚠️  MEDIUM: World-writable file - $($file.FullName)"
        }
    }
}

# ---------------------------------------------------------
# Configuration Issues
# ---------------------------------------------------------

Write-Host "🔍 Checking for configuration issues...`n" -ForegroundColor Cyan

# Check for exposed .git directory in web-accessible locations
$exposedGit = Get-ChildItem -Path $ScanPath -Recurse -Directory -Filter ".git" | 
Where-Object { $_.FullName -match '(public|www|wwwroot|htdocs)' }

if ($exposedGit) {
    foreach ($dir in $exposedGit) {
        $high += "⚠️  HIGH: Exposed .git directory in web root - $($dir.FullName)"
    }
}

# Check for debug mode in config files
$debugEnabled = Get-ChildItem -Path $ScanPath -Recurse -File -Include *.config, *.json, *.yml, *.yaml | 
Select-String -Pattern '(debug|DEBUG)\s*[:=]\s*(true|True|1|"true")'

if ($debugEnabled) {
    foreach ($match in $debugEnabled) {
        $low += "💡 LOW: Debug mode enabled - $($match.Filename):$($match.LineNumber)"
    }
}

# ---------------------------------------------------------
# Generate Report
# ---------------------------------------------------------

Write-Host "`n" + "─" * 64 -ForegroundColor Gray
Write-Host "`n📋 SECURITY AUDIT SUMMARY`n" -ForegroundColor Cyan

$totalFindings = $critical.Count + $high.Count + $medium.Count + $low.Count

if ($totalFindings -eq 0) {
    Write-Host "✅ No security issues detected!" -ForegroundColor Green
    exit 0
}

# Critical findings
if ($critical.Count -gt 0) {
    Write-Host "🚨 CRITICAL ($($critical.Count)):`n" -ForegroundColor Red
    $critical | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    Write-Host ""
}

# High severity
if ($high.Count -gt 0) {
    Write-Host "⚠️  HIGH ($($high.Count)):`n" -ForegroundColor Red
    $high | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    Write-Host ""
}

# Medium severity
if ($medium.Count -gt 0) {
    Write-Host "⚠️  MEDIUM ($($medium.Count)):`n" -ForegroundColor Yellow
    $medium | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
    Write-Host ""
}

# Low severity
if ($low.Count -gt 0) {
    Write-Host "💡 LOW ($($low.Count)):`n" -ForegroundColor Gray
    $low | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    Write-Host ""
}

# Save report
$reportContent = @"
SECURITY AUDIT REPORT
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Scan Path: $ScanPath

SUMMARY:
- Critical: $($critical.Count)
- High: $($high.Count)
- Medium: $($medium.Count)
- Low: $low.Count)

FINDINGS:
$($critical -join "`n")
$($high -join "`n")
$($medium -join "`n")
$($low -join "`n")
"@

# Ensure tmp directory exists
$reportDir = Split-Path $ReportFile -Parent
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$reportContent | Set-Content $ReportFile
Write-Host "📄 Full report saved to: $ReportFile`n" -ForegroundColor Gray

# Exit code based on severity
if ($critical.Count -gt 0) {
    Write-Host "❌ AUDIT FAILED - Critical issues must be addressed immediately" -ForegroundColor Red
    exit 1
}
elseif ($high.Count -gt 0) {
    Write-Host "⚠️  AUDIT WARNING - High severity issues found" -ForegroundColor Yellow
    exit 1
}
else {
    Write-Host "✅ Audit passed - only medium/low severity findings" -ForegroundColor Green
    exit 0
}
