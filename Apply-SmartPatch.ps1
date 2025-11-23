<#
.SYNOPSIS
    Apply-SmartPatch.ps1 (Multi-File Support)
    
.DESCRIPTION
    Applies JSON patches with flexible whitespace matching.
    Supports both single patch objects and arrays of patch objects.
    Leverages GIT for safety, rollbacks, and diff generation.
    PREVENTS accidental patching of binary files.

.EXAMPLE
    ./Apply-SmartPatch.ps1 -PatchFile "patch.json"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$PatchFile,

    [Parameter(Mandatory = $false)]
    [string]$BranchName
)

$ErrorActionPreference = "Stop"
$pathIsGitTracked = Test-Path ".git"

# ---------------------------------------------------------
# 1. Parse Patch Data
# ---------------------------------------------------------

try {
    $jsonContent = Get-Content -Path $PatchFile -Raw
    $patchData = $jsonContent | ConvertFrom-Json
}
catch {
    Write-Error "Failed to parse JSON patch file."
}

# Normalize to array
if ($patchData -isnot [System.Array]) {
    $patchData = @($patchData)
}

# ---------------------------------------------------------
# 2. Process Patches
# ---------------------------------------------------------

foreach ($patch in $patchData) {
    $targetPath = $patch.file
    $searchText = $patch.search
    $replaceText = $patch.replace

    Write-Host "`nProcessing: $targetPath" -ForegroundColor Cyan

    if (-not (Test-Path $targetPath)) { 
        Write-Error "Target file not found: $targetPath" 
    }

    # BINARY GUARD
    $binaryExtensions = @(".png", ".jpg", ".jpeg", ".gif", ".bmp", ".ico", ".pdf", ".exe", ".dll", ".bin", ".zip", ".tar", ".gz", ".7z")
    $extension = [System.IO.Path]::GetExtension($targetPath).ToLower()
    if ($binaryExtensions -contains $extension) {
        Write-Error "ABORTED :: Target '$targetPath' appears to be a binary file."
    }

    # GIT Branching (Only once per run ideally, but safe to repeat)
    if ($pathIsGitTracked -and -not [string]::IsNullOrWhiteSpace($BranchName)) {
        $currentBranch = git branch --show-current
        if ($currentBranch -ne $BranchName) {
            git checkout $BranchName 2>$null
            if ($LASTEXITCODE -ne 0) { git checkout -b $BranchName }
        }
    }

    # Apply Patch Logic
    $originalContent = Get-Content -Path $targetPath -Raw -Encoding UTF8
    
    # Normalize line endings
    $normalizedContent = $originalContent -replace "`r`n", "`n"
    $normalizedSearch = $searchText -replace "`r`n", "`n"

    if ($normalizedContent.Contains($normalizedSearch)) {
        Write-Host "MATCH :: Exact match." -ForegroundColor Green
        $newContent = $normalizedContent.Replace($normalizedSearch, $replaceText)
    }
    else {
        Write-Host "RETRY :: Attempting flexible whitespace match..." -ForegroundColor Yellow
        $tokens = $normalizedSearch -split '\s+' | Where-Object { $_ -ne "" }
        if ($tokens.Count -eq 0) { Write-Error "FAILURE :: Search text contains only whitespace." }
        
        $escapedTokens = $tokens | ForEach-Object { [regex]::Escape($_) }
        $flexiblePattern = $escapedTokens -join '\s+'
        $regex = [regex]::new($flexiblePattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
        
        if ($regex.Matches($normalizedContent).Count -eq 0) {
            Write-Error "FAILURE :: Content not found in $targetPath"
        }
        
        Write-Host "MATCH :: Flexible whitespace match found." -ForegroundColor Green
        $newContent = $regex.Replace($normalizedContent, $replaceText, 1)
    }

    # Write to disk
    $newContent | Set-Content -Path $targetPath -NoNewline -Encoding UTF8

    # Verification
    if ($pathIsGitTracked) {
        $diff = git diff --no-color --unified=0 $targetPath
        if (-not [string]::IsNullOrWhiteSpace($diff)) {
            Write-Host "SUCCESS :: File patched." -ForegroundColor Green
            Write-Host "--- GIT DIFF START ---" -ForegroundColor Gray
            Write-Host $diff
            Write-Host "--- GIT DIFF END ---" -ForegroundColor Gray
            
            if (-not [string]::IsNullOrWhiteSpace($BranchName)) {
                git add $targetPath
                git commit -m "AI Patch: Update $targetPath"
            }
        }
        else {
            Write-Warning "NO CHANGE :: Content matched but result identical."
        }
    }
}