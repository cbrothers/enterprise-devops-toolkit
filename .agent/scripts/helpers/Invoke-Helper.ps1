# .agent\scripts\helpers\Invoke-Helper.ps1
# Thin wrapper that forwards to the actual helper implementation located one level up.
param(
    [Parameter(Mandatory = $true)][string]$HelperName,
    [Parameter(Mandatory = $true)][hashtable]$Params
)

# Resolve the real helper script path (parent directory of this file)
$realHelper = Join-Path $PSScriptRoot "..\Invoke-Helper.ps1"

if (-not (Test-Path $realHelper)) {
    Write-Error "Real helper script not found at $realHelper"
    exit 1
}

# Invoke the real helper with the supplied arguments
& $realHelper -HelperName $HelperName -Params $Params
