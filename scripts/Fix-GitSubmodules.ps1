<#
.SYNOPSIS
    Fixes Git submodule issues by converting submodules to regular directories.

.DESCRIPTION
    This script detects and fixes accidentally added Git submodules by:
    1. Removing the submodule reference from Git's index
    2. Removing the .git directory inside the submodule
    3. Re-adding the directory as regular files
    
    This is useful when a directory with a .git folder is accidentally added
    as a submodule instead of regular files.

.PARAMETER Path
    The path to the directory that was accidentally added as a submodule.
    If not specified, the script will scan for submodules.

.PARAMETER AutoFix
    Automatically fix all detected submodules without prompting

.PARAMETER DryRun
    Show what would be fixed without making changes

.EXAMPLE
    .\Fix-GitSubmodules.ps1
    Scans for submodules and prompts for each one

.EXAMPLE
    .\Fix-GitSubmodules.ps1 -Path public
    Fixes the 'public' directory submodule

.EXAMPLE
    .\Fix-GitSubmodules.ps1 -AutoFix
    Automatically fixes all detected submodules

.NOTES
    This script should be run from the root of your Git repository.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path,

    [Parameter(Mandatory = $false)]
    [switch]$AutoFix,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

# Color output functions
function Write-Success { param([string]$Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Warning { param([string]$Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-Host "❌ $Message" -ForegroundColor Red }

# Check if we're in a Git repository
function Test-GitRepository {
    if (-not (Test-Path ".git")) {
        Write-Error "Not in a Git repository"
        exit 1
    }
}

# Detect submodules in the repository
function Get-Submodules {
    Write-Info "Scanning for submodules..."
    
    $submodules = @()
    
    # Check git ls-files for mode 160000 (submodule)
    $gitFiles = git ls-files --stage
    foreach ($line in $gitFiles) {
        if ($line -match '^160000\s+\w+\s+\d+\s+(.+)$') {
            $submodulePath = $matches[1]
            $submodules += $submodulePath
        }
    }
    
    return $submodules
}

# Fix a single submodule
function Repair-Submodule {
    param([string]$SubmodulePath)
    
    Write-Info "Fixing submodule: $SubmodulePath"
    
    # Check if path exists
    if (-not (Test-Path $SubmodulePath)) {
        Write-Warning "Path does not exist: $SubmodulePath"
        return $false
    }
    
    if ($DryRun) {
        Write-Info "[DRY RUN] Would remove submodule reference: $SubmodulePath"
        Write-Info "[DRY RUN] Would remove .git directory: $SubmodulePath\.git"
        Write-Info "[DRY RUN] Would re-add as regular directory"
        return $true
    }
    
    try {
        # Step 1: Remove from Git index
        Write-Info "Removing submodule reference from Git index..."
        git rm --cached $SubmodulePath 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to remove from Git index (may not be fatal)"
        }
        
        # Step 2: Remove .git directory inside the submodule
        $gitDir = Join-Path $SubmodulePath ".git"
        if (Test-Path $gitDir) {
            Write-Info "Removing .git directory: $gitDir"
            Remove-Item -Recurse -Force $gitDir -ErrorAction Stop
            Write-Success "Removed .git directory"
        }
        else {
            Write-Info "No .git directory found in $SubmodulePath"
        }
        
        # Step 3: Re-add as regular files
        Write-Info "Re-adding directory as regular files..."
        git add "$SubmodulePath/*" 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Successfully converted $SubmodulePath to regular directory"
            return $true
        }
        else {
            Write-Error "Failed to re-add files"
            return $false
        }
    }
    catch {
        Write-Error "Error fixing submodule: $_"
        return $false
    }
}

# Main execution
function Main {
    Write-Info "=== Git Submodule Repair Tool ==="
    Write-Info ""
    
    # Check if in Git repository
    Test-GitRepository
    
    # If specific path provided, fix that one
    if ($Path) {
        Write-Info "Fixing specified path: $Path"
        $success = Repair-Submodule -SubmodulePath $Path
        
        if ($success -and -not $DryRun) {
            Write-Info ""
            Write-Info "Next steps:"
            Write-Info "1. Review the changes: git status"
            Write-Info "2. Commit the fix: git commit -m 'fix: Convert $Path submodule to regular directory'"
            Write-Info "3. Push changes: git push"
        }
        
        exit $(if ($success) { 0 } else { 1 })
    }
    
    # Otherwise, scan for all submodules
    $submodules = Get-Submodules
    
    if ($submodules.Count -eq 0) {
        Write-Success "No submodules detected"
        exit 0
    }
    
    Write-Warning "Found $($submodules.Count) submodule(s):"
    foreach ($submodule in $submodules) {
        Write-Host "  - $submodule" -ForegroundColor Yellow
    }
    Write-Info ""
    
    # Fix each submodule
    $fixed = 0
    $failed = 0
    
    foreach ($submodule in $submodules) {
        if ($AutoFix) {
            $shouldFix = $true
        }
        else {
            $response = Read-Host "Fix submodule '$submodule'? (y/N)"
            $shouldFix = $response -eq 'y'
        }
        
        if ($shouldFix) {
            if (Repair-Submodule -SubmodulePath $submodule) {
                $fixed++
            }
            else {
                $failed++
            }
        }
        
        Write-Info ""
    }
    
    # Summary
    Write-Info "=== Summary ==="
    Write-Info "Fixed: $fixed"
    if ($failed -gt 0) {
        Write-Warning "Failed: $failed"
    }
    
    if ($fixed -gt 0 -and -not $DryRun) {
        Write-Info ""
        Write-Info "Next steps:"
        Write-Info "1. Review the changes: git status"
        Write-Info "2. Commit the fixes: git commit -m 'fix: Convert submodules to regular directories'"
        Write-Info "3. Push changes: git push"
    }
}

# Run main function
Main
