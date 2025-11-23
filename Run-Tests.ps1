# Run-Tests.ps1
# Executes all Pester tests in the .agent/scripts directory

Write-Host "`n🧪 Running AI Workflow Script Tests...`n" -ForegroundColor Cyan

# Simple test execution compatible with Pester 4.x and 5.x
$testFiles = Get-ChildItem "$PSScriptRoot\*.Tests.ps1"

if ($testFiles.Count -eq 0) {
    Write-Host "No test files found." -ForegroundColor Yellow
    exit 0
}

# Try to import Pester
try {
    Import-Module Pester -ErrorAction Stop
    $pesterVersion = (Get-Module Pester).Version.Major
    
    Write-Host "Using Pester v$pesterVersion" -ForegroundColor Gray
    
    # Run tests
    $result = Invoke-Pester -Path $testFiles.FullName -PassThru
    
    # Summary
    Write-Host "`n📊 Test Summary:" -ForegroundColor Cyan
    Write-Host "  Passed: $($result.PassedCount)" -ForegroundColor Green
    Write-Host "  Failed: $($result.FailedCount)" -ForegroundColor $(if ($result.FailedCount -gt 0) { 'Red' } else { 'Green' })
    
    if ($result.FailedCount -gt 0) {
        exit 1
    }
}
catch {
    Write-Host "❌ Pester is not installed." -ForegroundColor Red
    Write-Host "Install with: Install-Module -Name Pester -Force -SkipPublisherCheck" -ForegroundColor Yellow
    exit 1
}
