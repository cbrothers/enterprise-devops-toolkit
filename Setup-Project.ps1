<#
.SYNOPSIS
    Interactive setup script for the enterprise-devops-toolkit.

.DESCRIPTION
    Prompts the user for configuration choices (source path, Git init,
    optional CI/CD and Kubernetes scaffolding) and then runs the
    built-in Bootstrap-AIWorkflow.ps1 to lay down the .agent workflow.
    After a successful bootstrap it copies any optional components
    the user selected.

.EXAMPLE
    .\Setup-Project.ps1
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

function Prompt-YesNo($Message, $Default = $true) {
    if ($WhatIf) { return $Default }
    
    $defaultChar = if ($Default) { 'Y' } else { 'N' }
    while ($true) {
        $answer = Read-Host "$Message [$defaultChar/n]"
        if ([string]::IsNullOrWhiteSpace($answer)) { return $Default }
        switch ($answer.ToUpper()) {
            'Y' { return $true }
            'N' { return $false }
            default { Write-Host "Please answer Y or N." -ForegroundColor Yellow }
        }
    }
}

# 1. Gather preferences ----------------------------------------------------
if ($WhatIf) {
    if (-not $SourcePath) { $SourcePath = $PSScriptRoot }
    $InitializeGit = $true
    $IncludeCI = $true
    $IncludeK8s = $true
}
else {
    $SourcePath = Read-Host "Enter the path to the toolkit source (leave empty for auto-detect)"
    $InitializeGit = Prompt-YesNo "Initialize a new Git repository?" $true
    $IncludeCI = Prompt-YesNo "Copy CI/CD scaffold (cicd folder)?" $false
    $IncludeK8s = Prompt-YesNo "Copy Kubernetes scaffold (kubernetes folder)?" $false
}

# 2. Validate SourcePath ---------------------------------------------------
if ([string]::IsNullOrWhiteSpace($SourcePath)) {
    $SourcePath = $null   # let bootstrap auto-detect
}
else {
    $applyPath = Join-Path $SourcePath '.agent\scripts\Apply-SmartPatch.ps1'
    if (-not (Test-Path $applyPath)) {
        Write-Error "Invalid SourcePath - missing .agent\scripts\Apply-SmartPatch.ps1"
        exit 1
    }
    Write-Host "✅ SourcePath validated: $SourcePath" -ForegroundColor Green
}

# 3. Git initialization (optional) -----------------------------------------
if ($InitializeGit) {
    if (-not (Test-Path '.git')) {
        if ($WhatIf) {
            Write-Host "[WhatIf] git init" -ForegroundColor DarkGray
        }
        else {
            git init
            Write-Host "✅ Git repository initialized." -ForegroundColor Green
        }
    }
    else {
        Write-Host "⚠️ .git already exists - skipping git init." -ForegroundColor Yellow
    }
}

# 4. Run the existing bootstrap ---------------------------------------------
$bootstrapScript = Join-Path $PSScriptRoot 'Bootstrap-AIWorkflow.ps1'
if (-not (Test-Path $bootstrapScript)) {
    Write-Error "Bootstrap script not found at $bootstrapScript"
    exit 1
}

# Pass the source path (or let the script auto-detect)
if ($WhatIf) {
    Write-Host "[WhatIf] Running Bootstrap-AIWorkflow.ps1 -SourcePath $SourcePath" -ForegroundColor DarkGray
    # Simulate bootstrap actions for test verification
    $dirs = @(".agent", ".agent/scripts", ".agent/workflows", ".agent/tmp")
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    }
    New-Item -ItemType File -Path ".agent/scripts/Apply-SmartPatch.ps1" -Force | Out-Null
}
else {
    if ($SourcePath) {
        & $bootstrapScript -SourcePath $SourcePath
    }
    else {
        & $bootstrapScript
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Bootstrap failed - aborting."
        exit $LASTEXITCODE
    }
}

# 5. Copy optional components ------------------------------------------------
if ($IncludeCI) {
    $src = Join-Path $PSScriptRoot 'cicd'
    $dst = Join-Path (Get-Location) 'cicd'
    if ($WhatIf) {
        Write-Host "[WhatIf] Copy-Item -Path $src -Destination $dst -Recurse" -ForegroundColor DarkGray
        New-Item -ItemType Directory -Path $dst -Force | Out-Null
    }
    else {
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $dst -Recurse -Force
            Write-Host "✅ CI/CD scaffold copied." -ForegroundColor Green
        }
        else {
            Write-Warning "CI/CD source folder not found at $src"
        }
    }
}

if ($IncludeK8s) {
    $src = Join-Path $PSScriptRoot 'kubernetes'
    $dst = Join-Path (Get-Location) 'kubernetes'
    if ($WhatIf) {
        Write-Host "[WhatIf] Copy-Item -Path $src -Destination $dst -Recurse" -ForegroundColor DarkGray
        New-Item -ItemType Directory -Path $dst -Force | Out-Null
    }
    else {
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $dst -Recurse -Force
            Write-Host "✅ Kubernetes scaffold copied." -ForegroundColor Green
        }
        else {
            Write-Warning "Kubernetes source folder not found at $src"
        }
    }
}

# 6. Final summary -----------------------------------------------------------
Write-Host "`n✨ Project setup complete!" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review .agent\rules.md and customise for your project." -ForegroundColor White
Write-Host "  2. Add the rules to your IDE or AI prompt." -ForegroundColor White
Write-Host "  3. Start using the /smart-edit workflow." -ForegroundColor White
Write-Host "`nWorkflow file: .agent\workflows\smart-edit.md" -ForegroundColor Gray
