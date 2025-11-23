# Profile-Performance.ps1
# Performance profiling and benchmarking tool

param(
    [Parameter(Mandatory = $true)]
    [string]$TestScript,
    
    [int]$Iterations = 10,
    [switch]$MeasureMemory,
    [string]$Arguments = ""
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $TestScript)) {
    Write-Error "Test script not found: $TestScript"
}

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                  PERFORMANCE PROFILE                          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n📊 Script: " -NoNewline -ForegroundColor Yellow
Write-Host "$TestScript" -ForegroundColor White
Write-Host "🔄 Iterations: " -NoNewline -ForegroundColor Yellow
Write-Host "$Iterations`n" -ForegroundColor White

Write-Host "Running benchmark..." -ForegroundColor Gray

$times = @()
$memoryUsage = @()

for ($i = 1; $i -le $Iterations; $i++) {
    Write-Progress -Activity "Profiling" -Status "Iteration $i of $Iterations" -PercentComplete (($i / $Iterations) * 100)
    
    # Measure execution time
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    
    if ($MeasureMemory) {
        $beforeMemory = [System.GC]::GetTotalMemory($true)
    }
    
    # Execute the script
    if ($Arguments) {
        & $TestScript $Arguments | Out-Null
    }
    else {
        & $TestScript | Out-Null
    }
    
    $sw.Stop()
    $times += $sw.ElapsedMilliseconds
    
    if ($MeasureMemory) {
        $afterMemory = [System.GC]::GetTotalMemory($false)
        $memoryUsage += ($afterMemory - $beforeMemory) / 1MB
    }
    
    # Small delay between iterations
    Start-Sleep -Milliseconds 100
}

Write-Progress -Activity "Profiling" -Completed

# Calculate statistics
$avg = ($times | Measure-Object -Average).Average
$min = ($times | Measure-Object -Minimum).Minimum
$max = ($times | Measure-Object -Maximum).Maximum
$stdDev = [Math]::Sqrt(($times | ForEach-Object { [Math]::Pow($_ - $avg, 2) } | Measure-Object -Average).Average)
$median = ($times | Sort-Object)[[Math]::Floor($times.Count / 2)]

# Display results
Write-Host "`n" + "─" * 64 -ForegroundColor Gray
Write-Host "`n⚡ TIMING RESULTS`n" -ForegroundColor Cyan

Write-Host "  Average:    " -NoNewline -ForegroundColor Gray
Write-Host "$([Math]::Round($avg, 2))ms" -ForegroundColor White

Write-Host "  Median:     " -NoNewline -ForegroundColor Gray
Write-Host "$([Math]::Round($median, 2))ms" -ForegroundColor White

Write-Host "  Min:        " -NoNewline -ForegroundColor Gray
Write-Host "$([Math]::Round($min, 2))ms" -ForegroundColor Green

Write-Host "  Max:        " -NoNewline -ForegroundColor Gray
Write-Host "$([Math]::Round($max, 2))ms" -ForegroundColor Yellow

Write-Host "  Std Dev:    " -NoNewline -ForegroundColor Gray
Write-Host "$([Math]::Round($stdDev, 2))ms" -ForegroundColor White

# Performance consistency assessment
$coefficientOfVariation = ($stdDev / $avg) * 100
Write-Host "`n  Variance:   " -NoNewline -ForegroundColor Gray

if ($coefficientOfVariation -lt 5) {
    Write-Host "$([Math]::Round($coefficientOfVariation, 1))% (Excellent consistency)" -ForegroundColor Green
}
elseif ($coefficientOfVariation -lt 15) {
    Write-Host "$([Math]::Round($coefficientOfVariation, 1))% (Good consistency)" -ForegroundColor Yellow
}
else {
    Write-Host "$([Math]::Round($coefficientOfVariation, 1))% (High variance - investigate)" -ForegroundColor Red
}

# Memory results
if ($MeasureMemory) {
    Write-Host "`n💾 MEMORY USAGE`n" -ForegroundColor Cyan
    
    $avgMemory = ($memoryUsage | Measure-Object -Average).Average
    $maxMemory = ($memoryUsage | Measure-Object -Maximum).Maximum
    
    Write-Host "  Average:    " -NoNewline -ForegroundColor Gray
    Write-Host "$([Math]::Round($avgMemory, 2)) MB" -ForegroundColor White
    
    Write-Host "  Peak:       " -NoNewline -ForegroundColor Gray
    Write-Host "$([Math]::Round($maxMemory, 2)) MB" -ForegroundColor Yellow
}

# Performance rating
Write-Host "`n📈 PERFORMANCE RATING`n" -ForegroundColor Cyan

if ($avg -lt 100) {
    Write-Host "  ⚡ Excellent (< 100ms)" -ForegroundColor Green
}
elseif ($avg -lt 500) {
    Write-Host "  ✅ Good (< 500ms)" -ForegroundColor Green
}
elseif ($avg -lt 1000) {
    Write-Host "  ⚠️  Acceptable (< 1s)" -ForegroundColor Yellow
}
else {
    Write-Host "  ❌ Slow (> 1s) - Consider optimization" -ForegroundColor Red
}

Write-Host ""
