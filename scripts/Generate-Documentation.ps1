# Generate-Documentation.ps1
# Automated code documentation generator

param(
    [string]$Path = ".",
    [ValidateSet("markdown", "html", "json")]
    [string]$Format = "markdown",
    [ValidateSet("all", "api", "guides", "examples")]
    [string]$Type = "all",
    [switch]$IncludeExamples,
    [switch]$IncludePrivate,
    [string]$OutputDir = "docs"
)

$ErrorActionPreference = "Continue"

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║            CODE DOCUMENTATION GENERATOR                       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n📚 Generating documentation...`n" -ForegroundColor Yellow

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$documentation = @{
    Functions = @()
    Classes   = @()
    Modules   = @()
}

# ---------------------------------------------------------
# Scan PowerShell Files
# ---------------------------------------------------------

Write-Host "🔍 Scanning PowerShell files...`n" -ForegroundColor Cyan

$psFiles = Get-ChildItem -Path $Path -Recurse -Filter "*.ps1" -File

foreach ($file in $psFiles) {
    Write-Host "  Processing $($file.Name)..." -ForegroundColor Gray
    
    $content = Get-Content $file.FullName -Raw
    
    # Extract comment-based help
    $helpPattern = '(?s)<#(.*?)#>'
    $helpMatches = [regex]::Matches($content, $helpPattern)
    
    foreach ($helpBlock in $helpMatches) {
        $helpText = $helpBlock.Groups[1].Value
        
        # Parse help sections
        $synopsis = if ($helpText -match '\.SYNOPSIS\s+(.*?)(?=\.|$)') { $matches[1].Trim() } else { "" }
        $description = if ($helpText -match '\.DESCRIPTION\s+(.*?)(?=\.|$)') { $matches[1].Trim() } else { "" }
        
        # Extract function name (look for function definition after help block)
        $functionPattern = 'function\s+([A-Za-z0-9\-]+)'
        if ($content -match "$($helpBlock.Value)\s*$functionPattern") {
            $functionName = $matches[1]
            
            $documentation.Functions += @{
                Name        = $functionName
                Synopsis    = $synopsis
                Description = $description
                File        = $file.Name
                Path        = $file.FullName
            }
        }
    }
}

Write-Host "  ✅ Found $($documentation.Functions.Count) documented functions" -ForegroundColor Green

# ---------------------------------------------------------
# Scan JavaScript/TypeScript Files
# ---------------------------------------------------------

$jsFiles = Get-ChildItem -Path $Path -Recurse -Include "*.js", "*.ts" -File

if ($jsFiles.Count -gt 0) {
    Write-Host "`n🔍 Scanning JavaScript/TypeScript files...`n" -ForegroundColor Cyan
    
    foreach ($file in $jsFiles) {
        Write-Host "  Processing $($file.Name)..." -ForegroundColor Gray
        
        $content = Get-Content $file.FullName -Raw
        
        # Extract JSDoc comments
        $jsdocPattern = '(?s)/\*\*(.*?)\*/\s*(?:export\s+)?(?:async\s+)?function\s+([A-Za-z0-9_]+)'
        $jsdocMatches = [regex]::Matches($content, $jsdocPattern)
        
        foreach ($match in $jsdocMatches) {
            $comment = $match.Groups[1].Value
            $functionName = $match.Groups[2].Value
            
            # Extract description (first line)
            $description = ($comment -split "`n" | Where-Object { $_ -match '\S' } | Select-Object -First 1).Trim(' *')
            
            $documentation.Functions += @{
                Name        = $functionName
                Synopsis    = $description
                Description = $description
                File        = $file.Name
                Path        = $file.FullName
                Language    = "JavaScript"
            }
        }
    }
    
    Write-Host "  ✅ Found JavaScript/TypeScript functions" -ForegroundColor Green
}

# ---------------------------------------------------------
# Generate Markdown Documentation
# ---------------------------------------------------------

if ($Format -eq "markdown") {
    Write-Host "`n📝 Generating Markdown documentation...`n" -ForegroundColor Cyan
    
    # Create API directory
    $apiDir = Join-Path $OutputDir "api"
    if (-not (Test-Path $apiDir)) {
        New-Item -ItemType Directory -Path $apiDir -Force | Out-Null
    }
    
    # Generate functions documentation
    if ($documentation.Functions.Count -gt 0) {
        $functionsDoc = @"
# Function Reference

This document provides a reference for all documented functions in the project.

## Functions

"@
        
        foreach ($func in ($documentation.Functions | Sort-Object Name)) {
            $functionsDoc += @"

### $($func.Name)

**File:** ``$($func.File)``

$($func.Synopsis)

"@
            
            if ($func.Description -and $func.Description -ne $func.Synopsis) {
                $functionsDoc += @"

**Description:**

$($func.Description)

"@
            }
        }
        
        $functionsPath = Join-Path $apiDir "functions.md"
        $functionsDoc | Set-Content $functionsPath
        Write-Host "  ✅ Created $functionsPath" -ForegroundColor Green
    }
    
    # Generate main README
    $readmePath = Join-Path $OutputDir "README.md"
    $readme = @"
# Project Documentation

Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Overview

This documentation was automatically generated from the codebase.

## Contents

- [Function Reference](api/functions.md) - $($documentation.Functions.Count) functions documented

## Quick Links

- [Getting Started](getting-started.md)
- [API Reference](api/)
- [Examples](examples/)

## Statistics

- **Functions Documented:** $($documentation.Functions.Count)
- **Files Scanned:** $($psFiles.Count + $jsFiles.Count)
- **Last Updated:** $(Get-Date -Format 'yyyy-MM-dd')

"@
    
    $readme | Set-Content $readmePath
    Write-Host "  ✅ Created $readmePath" -ForegroundColor Green
}

# ---------------------------------------------------------
# Generate JSON Documentation
# ---------------------------------------------------------

if ($Format -eq "json") {
    Write-Host "`n📝 Generating JSON documentation...`n" -ForegroundColor Cyan
    
    $jsonPath = Join-Path $OutputDir "documentation.json"
    $documentation | ConvertTo-Json -Depth 10 | Set-Content $jsonPath
    Write-Host "  ✅ Created $jsonPath" -ForegroundColor Green
}

# ---------------------------------------------------------
# Summary
# ---------------------------------------------------------

Write-Host "`n" + "─" * 64 -ForegroundColor Gray
Write-Host "`n📋 DOCUMENTATION SUMMARY`n" -ForegroundColor Cyan

Write-Host "  Format:     " -NoNewline -ForegroundColor Gray
Write-Host "$Format" -ForegroundColor White

Write-Host "  Output:     " -NoNewline -ForegroundColor Gray
Write-Host "$OutputDir" -ForegroundColor White

Write-Host "  Functions:  " -NoNewline -ForegroundColor Gray
Write-Host "$($documentation.Functions.Count)" -ForegroundColor White

Write-Host "  Files:      " -NoNewline -ForegroundColor Gray
Write-Host "$($psFiles.Count + $jsFiles.Count)" -ForegroundColor White

Write-Host "`n✅ Documentation generated successfully!" -ForegroundColor Green
Write-Host "📂 View documentation in: $OutputDir`n" -ForegroundColor Cyan
