# Quick-Commit.ps1
# Helper for quick conventional commits

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('feat', 'fix', 'docs', 'style', 'refactor', 'test', 'chore')]
    [string]$Type,
    
    [Parameter(Mandatory = $true)]
    [string]$Message,
    
    [Parameter(Mandatory = $false)]
    [int]$IssueNumber,
    
    [Parameter(Mandatory = $false)]
    [string[]]$Files
)

$ErrorActionPreference = "Stop"

# Stage files
if ($Files -and $Files.Count -gt 0) {
    foreach ($file in $Files) {
        git add $file
    }
}
else {
    git add -A
}

# Build commit params
$commitParams = @{
    type    = $Type
    message = $Message
}

if ($IssueNumber) {
    $commitParams.issue = $IssueNumber
}

# Commit using helper
& "$PSScriptRoot\Invoke-Helper.ps1" -HelperName "git-commit" -Params $commitParams

Write-Host "✅ Committed: $Type`: $Message" -ForegroundColor Green
