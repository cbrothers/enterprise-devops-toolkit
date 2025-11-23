# Run-IntegrationTests.ps1
# Integration testing framework

param(
    [string]$TestSuite = "all",
    [switch]$Coverage,
    [switch]$Parallel,
    [string]$TestPath = "tests/integration",
    [string]$ReportPath = ".agent/tmp/integration-test-report.xml"
)

$ErrorActionPreference = "Continue"

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║               INTEGRATION TEST RUNNER                         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n🧪 Test Suite: " -NoNewline -ForegroundColor Yellow
Write-Host "$TestSuite`n" -ForegroundColor White

# Check if test directory exists
if (-not (Test-Path $TestPath)) {
    Write-Host "❌ Test directory not found: $TestPath" -ForegroundColor Red
    Write-Host "💡 Create integration tests in: $TestPath" -ForegroundColor Gray
    exit 1
}

# Discover test files
$testFiles = @()

if ($TestSuite -eq "all") {
    $testFiles = Get-ChildItem -Path $TestPath -Recurse -Filter "*.tests.ps1"
}
else {
    $suitePath = Join-Path $TestPath $TestSuite
    if (Test-Path $suitePath) {
        $testFiles = Get-ChildItem -Path $suitePath -Recurse -Filter "*.tests.ps1"
    }
    else {
        Write-Host "❌ Test suite not found: $TestSuite" -ForegroundColor Red
        exit 1
    }
}

if ($testFiles.Count -eq 0) {
    Write-Host "⚠️  No test files found" -ForegroundColor Yellow
    exit 0
}

Write-Host "📋 Found $($testFiles.Count) test file(s)`n" -ForegroundColor Gray

# Check for Pester
try {
    Import-Module Pester -ErrorAction Stop -MinimumVersion 5.0
}
catch {
    Write-Host "❌ Pester 5.0+ is required" -ForegroundColor Red
    Write-Host "💡 Install with: Install-Module -Name Pester -Force -SkipPublisherCheck" -ForegroundColor Yellow
    exit 1
}

# Configure Pester
$pesterConfig = New-PesterConfiguration

$pesterConfig.Run.Path = $testFiles.FullName
$pesterConfig.Run.PassThru = $true

if ($Parallel) {
    $pesterConfig.Run.Parallel = $true
    Write-Host "⚡ Running tests in parallel`n" -ForegroundColor Cyan
}

if ($Coverage) {
    $pesterConfig.CodeCoverage.Enabled = $true
    $pesterConfig.CodeCoverage.Path = "*.ps1"
    Write-Host "📊 Code coverage enabled`n" -ForegroundColor Cyan
}

# Output configuration
$pesterConfig.Output.Verbosity = 'Detailed'

# Test results
if ($ReportPath) {
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = $ReportPath
    $pesterConfig.TestResult.OutputFormat = 'NUnitXml'
    
    # Ensure directory exists
    $reportDir = Split-Path $ReportPath -Parent
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
}

# Run tests
Write-Host "🚀 Running integration tests...`n" -ForegroundColor Cyan
$startTime = Get-Date

$result = Invoke-Pester -Configuration $pesterConfig

$duration = (Get-Date) - $startTime

# Display results
Write-Host "`n" + "─" * 64 -ForegroundColor Gray
Write-Host "`n📊 TEST RESULTS`n" -ForegroundColor Cyan

Write-Host "  Total:      " -NoNewline -ForegroundColor Gray
Write-Host "$($result.TotalCount)" -ForegroundColor White

Write-Host "  Passed:     " -NoNewline -ForegroundColor Gray
Write-Host "$($result.PassedCount)" -ForegroundColor Green

Write-Host "  Failed:     " -NoNewline -ForegroundColor Gray
$failColor = if ($result.FailedCount -gt 0) { 'Red' } else { 'Green' }
Write-Host "$($result.FailedCount)" -ForegroundColor $failColor

Write-Host "  Skipped:    " -NoNewline -ForegroundColor Gray
Write-Host "$($result.SkippedCount)" -ForegroundColor Yellow

Write-Host "  Duration:   " -NoNewline -ForegroundColor Gray
Write-Host "$([Math]::Round($duration.TotalSeconds, 2))s" -ForegroundColor White

# Coverage report
if ($Coverage -and $result.CodeCoverage) {
    Write-Host "`n📈 CODE COVERAGE`n" -ForegroundColor Cyan
    
    $coverage = $result.CodeCoverage
    $coveragePercent = 0
    
    if ($coverage.NumberOfCommandsAnalyzed -gt 0) {
        $coveragePercent = [Math]::Round(
            ($coverage.NumberOfCommandsExecuted / $coverage.NumberOfCommandsAnalyzed) * 100, 
            2
        )
    }
    
    Write-Host "  Commands Analyzed:  " -NoNewline -ForegroundColor Gray
    Write-Host "$($coverage.NumberOfCommandsAnalyzed)" -ForegroundColor White
    
    Write-Host "  Commands Executed:  " -NoNewline -ForegroundColor Gray
    Write-Host "$($coverage.NumberOfCommandsExecuted)" -ForegroundColor White
    
    Write-Host "  Coverage:           " -NoNewline -ForegroundColor Gray
    
    $coverageColor = if ($coveragePercent -ge 80) { 'Green' } 
    elseif ($coveragePercent -ge 60) { 'Yellow' } 
    else { 'Red' }
    
    Write-Host "$coveragePercent%" -ForegroundColor $coverageColor
    
    # Show missed commands
    if ($coverage.MissedCommands.Count -gt 0 -and $coverage.MissedCommands.Count -le 10) {
        Write-Host "`n  Missed Commands:" -ForegroundColor Gray
        $coverage.MissedCommands | Select-Object -First 10 | ForEach-Object {
            Write-Host "    - $($_.File):$($_.Line)" -ForegroundColor Yellow
        }
    }
}

# Report location
if ($ReportPath -and (Test-Path $ReportPath)) {
    Write-Host "`n📄 Test report saved to: $ReportPath" -ForegroundColor Gray
}

Write-Host ""

# Exit code
if ($result.FailedCount -gt 0) {
    Write-Host "❌ Integration tests failed" -ForegroundColor Red
    exit 1
}
else {
    Write-Host "✅ All integration tests passed!" -ForegroundColor Green
    exit 0
}
