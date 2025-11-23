# Build-Project.ps1
# Build automation with dependency tracking

param(
    [switch]$Clean,
    [switch]$TrackOnly,
    [switch]$GenerateGraph,
    [switch]$Watch,
    [string]$ConfigFile = ".agent/build-config.json",
    [string]$OutputDir = "build"
)

$ErrorActionPreference = "Stop"

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              BUILD & DEPENDENCY TRACKER                       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# Load configuration
$config = @{
    entry_points     = @("*.ps1")
    output_dir       = $OutputDir
    cache_dir        = ".build-cache"
    exclude_patterns = @("*.Tests.ps1", "test/**")
    parallel_builds  = $true
    max_parallel     = 4
}

if (Test-Path $ConfigFile) {
    $customConfig = Get-Content $ConfigFile | ConvertFrom-Json
    $customConfig.PSObject.Properties | ForEach-Object {
        $config[$_.Name] = $_.Value
    }
    Write-Host "`n✅ Loaded configuration from $ConfigFile" -ForegroundColor Green
}

# Ensure directories exist
@($config.output_dir, $config.cache_dir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
}

# ---------------------------------------------------------
# Dependency Analysis
# ---------------------------------------------------------

Write-Host "`n🔍 Analyzing dependencies...`n" -ForegroundColor Cyan

$dependencyGraph = @{}
$allFiles = Get-ChildItem -Path "." -Recurse -Include "*.ps1", "*.psm1" -File |
Where-Object { 
    $exclude = $false
    foreach ($pattern in $config.exclude_patterns) {
        if ($_.FullName -like "*$pattern*") {
            $exclude = $true
            break
        }
    }
    -not $exclude
}

Write-Host "  Found $($allFiles.Count) files to analyze" -ForegroundColor Gray

foreach ($file in $allFiles) {
    $relativePath = $file.FullName.Replace((Get-Location).Path, "").TrimStart('\', '/')
    $dependencyGraph[$relativePath] = @{
        Path         = $file.FullName
        Dependencies = @()
        LastModified = $file.LastWriteTime
        Hash         = (Get-FileHash $file.FullName -Algorithm MD5).Hash
    }
    
    # Parse file for dependencies
    $content = Get-Content $file.FullName -Raw
    
    # Find dot-sourcing
    $dotSourcePattern = '\.\s+([^\s]+\.ps1)'
    $dotSourceMatches = [regex]::Matches($content, $dotSourcePattern)
    foreach ($match in $dotSourceMatches) {
        $depPath = $match.Groups[1].Value
        $dependencyGraph[$relativePath].Dependencies += $depPath
    }
    
    # Find Import-Module
    $importPattern = 'Import-Module\s+["\']?([^"\'\s]+)'
    $importMatches = [regex]::Matches($content, $importPattern)
    foreach ($match in $importMatches) {
        $moduleName = $match.Groups[1].Value
        $dependencyGraph[$relativePath].Dependencies += "module:$moduleName"
    }
    
    # Find using module
    $usingPattern = 'using\s+module\s+([^\s]+)'
    $usingMatches = [regex]::Matches($content, $usingPattern)
    foreach ($match in $usingMatches) {
        $moduleName = $match.Groups[1].Value
        $dependencyGraph[$relativePath].Dependencies += "module:$moduleName"
    }
}

Write-Host "  ✅ Dependency graph built" -ForegroundColor Green

# ---------------------------------------------------------
# Detect Circular Dependencies
# ---------------------------------------------------------

Write-Host "`n🔄 Checking for circular dependencies...`n" -ForegroundColor Cyan

function Test-CircularDependency {
    param($file, $visited = @(), $stack = @())
    
    if ($stack -contains $file) {
        return $true, ($stack + $file)
    }
    
    if ($visited -contains $file) {
        return $false, @()
    }
    
    $visited += $file
    $stack += $file
    
    if ($dependencyGraph.ContainsKey($file)) {
        foreach ($dep in $dependencyGraph[$file].Dependencies) {
            if ($dep -notlike "module:*") {
                $hasCircular, $path = Test-CircularDependency $dep $visited $stack
                if ($hasCircular) {
                    return $true, $path
                }
            }
        }
    }
    
    return $false, @()
}

$circularFound = $false
foreach ($file in $dependencyGraph.Keys) {
    $hasCircular, $path = Test-CircularDependency $file
    if ($hasCircular) {
        Write-Host "  ⚠️  Circular dependency detected:" -ForegroundColor Yellow
        Write-Host "     $($path -join ' → ')" -ForegroundColor Yellow
        $circularFound = $true
    }
}

if (-not $circularFound) {
    Write-Host "  ✅ No circular dependencies found" -ForegroundColor Green
}

# ---------------------------------------------------------
# Generate Dependency Graph
# ---------------------------------------------------------

if ($GenerateGraph) {
    Write-Host "`n📊 Generating dependency graph...`n" -ForegroundColor Cyan
    
    # JSON format
    $graphPath = Join-Path $config.output_dir "dependencies.json"
    $dependencyGraph | ConvertTo-Json -Depth 10 | Set-Content $graphPath
    Write-Host "  ✅ Created $graphPath" -ForegroundColor Green
    
    # Markdown format
    $mdPath = Join-Path $config.output_dir "dependencies.md"
    $markdown = @"
        # Dependency Graph

        Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

        ## Files

        "@
    
    foreach ($file in ($dependencyGraph.Keys | Sort-Object)) {
        $markdown += "`n### $file`n`n"
        if ($dependencyGraph[$file].Dependencies.Count -gt 0) {
            $markdown += "**Dependencies:**`n"
            foreach ($dep in $dependencyGraph[$file].Dependencies) {
                $markdown += "- ``$dep```n"
            }
        } else {
            $markdown += "*No dependencies*`n"
        }
    }
    
    $markdown | Set-Content $mdPath
    Write-Host "  ✅ Created $mdPath" -ForegroundColor Green
}

# ---------------------------------------------------------
# Build Process
# ---------------------------------------------------------

if (-not $TrackOnly) {
    Write-Host "`n🔨 Building project...`n" -ForegroundColor Cyan
    
    # Calculate build order (topological sort)
    $buildOrder = @()
    $processed = @{}
    
    function Add-ToBuildOrder {
        param($file)
        
        if ($processed.ContainsKey($file)) {
            return
        }
        
        if ($dependencyGraph.ContainsKey($file)) {
            foreach ($dep in $dependencyGraph[$file].Dependencies) {
                if ($dep -notlike "module:*") {
                    Add-ToBuildOrder $dep
                }
            }
        }
        
        $buildOrder += $file
        $processed[$file] = $true
    }
    
    foreach ($file in $dependencyGraph.Keys) {
        Add-ToBuildOrder $file
    }
    
    Write-Host "  Build order calculated: $($buildOrder.Count) files" -ForegroundColor Gray
    
    # Execute build (copy to output for now)
    foreach ($file in $buildOrder) {
        $sourcePath = $dependencyGraph[$file].Path
        $destPath = Join-Path $config.output_dir $file
        $destDir = Split-Path $destPath -Parent
        
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        
        Copy-Item $sourcePath $destPath -Force
    }
    
    Write-Host "  ✅ Build completed" -ForegroundColor Green
}

# ---------------------------------------------------------
# Summary
# ---------------------------------------------------------

Write-Host "`n" + "─" * 64 -ForegroundColor Gray
Write-Host "`n📋 SUMMARY`n" -ForegroundColor Cyan

Write-Host "  Files Analyzed:  " -NoNewline -ForegroundColor Gray
Write-Host "$($dependencyGraph.Count)" -ForegroundColor White

$totalDeps = ($dependencyGraph.Values | ForEach-Object { $_.Dependencies.Count } | Measure-Object -Sum).Sum
Write-Host "  Dependencies:    " -NoNewline -ForegroundColor Gray
Write-Host "$totalDeps" -ForegroundColor White

if ($circularFound) {
    Write-Host "  Circular Deps:   " -NoNewline -ForegroundColor Gray
    Write-Host "Found (review output)" -ForegroundColor Yellow
}

Write-Host "`n✅ Process completed successfully!`n" -ForegroundColor Green
