# Bootstrap.ps1
# Loads helper scripts and defines aliases for token-efficient usage.

$ScriptsRoot = "$PSScriptRoot\scripts"
$HelpersRoot = "$ScriptsRoot\helpers"

# Define aliases for common tasks
function Global:Start-Issue { & "$HelpersRoot\Start-Issue.ps1" @args }
function Global:Complete-Issue { & "$HelpersRoot\Complete-Issue.ps1" @args }
function Global:Get-ProjectStatus { & "$HelpersRoot\Get-ProjectStatus.ps1" @args }
function Global:Sync-Branch { & "$HelpersRoot\Sync-Branch.ps1" @args }
function Global:Quick-Commit { & "$HelpersRoot\Quick-Commit.ps1" @args }
function Global:Issue-Update { & "$HelpersRoot\issue-update-enhanced.ps1" @args }

# Project status update function
function Global:Set-InProgress {
    param(
        [Parameter(Mandatory = $true)][int]$Issue,
        [string]$ProjectName
    )
    $script = "$PSScriptRoot\..\..\from-merchify\scripts\Update-ProjectStatus.ps1"
    if ($ProjectName) {
        & $script -IssueNumber $Issue -Status "In Progress" -ProjectName $ProjectName
    }
    else {
        & $script -IssueNumber $Issue -Status "In Progress"
    }
}

# Short aliases
Set-Alias -Name "start" -Value Start-Issue -Scope Global -Force
Set-Alias -Name "done" -Value Complete-Issue -Scope Global -Force
Set-Alias -Name "status" -Value Get-ProjectStatus -Scope Global -Force
Set-Alias -Name "sync" -Value Sync-Branch -Scope Global -Force
Set-Alias -Name "qc" -Value Quick-Commit -Scope Global -Force
Set-Alias -Name "set-inprogress" -Value Set-InProgress -Scope Global -Force

Write-Host "`n🚀 Agent Bootstrap Loaded" -ForegroundColor Cyan
Write-Host "───────────────────────" -ForegroundColor Gray
Write-Host "  start   -> Start-Issue" -ForegroundColor White
Write-Host "  done    -> Complete-Issue" -ForegroundColor White
Write-Host "  status  -> Get-ProjectStatus" -ForegroundColor White
Write-Host "  sync    -> Sync-Branch" -ForegroundColor White
Write-Host "  qc      -> Quick-Commit" -ForegroundColor White
Write-Host "───────────────────────`n" -ForegroundColor Gray
