# Manage-Dependencies.ps1
# Dependency management and update automation

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("check", "update", "audit")]
    [string]$Action,
    
    [string]$Package,
    [switch]$IncludeMajor,
    [switch]$DryRun
)

$ErrorActionPreference = "Continue"

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              DEPENDENCY MANAGEMENT                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n📦 Action: " -NoNewline -ForegroundColor Yellow
Write-Host "$Action`n" -ForegroundColor White

$findings = @{
    PowerShell = @()
    Node       = @()
    Python     = @()
    NuGet      = @()
}

# ---------------------------------------------------------
# PowerShell Modules
# ---------------------------------------------------------

Write-Host "🔍 Checking PowerShell modules...`n" -ForegroundColor Cyan

# Get installed modules
$installedModules = Get-Module -ListAvailable | 
Group-Object Name | 
ForEach-Object { $_.Group | Sort-Object Version -Descending | Select-Object -First 1 }

foreach ($module in $installedModules) {
    try {
        # Check for updates
        $online = Find-Module -Name $module.Name -ErrorAction SilentlyContinue
        
        if ($online -and $online.Version -gt $module.Version) {
            $versionDiff = "$($module.Version) → $($online.Version)"
            
            $findings.PowerShell += @{
                Name      = $module.Name
                Current   = $module.Version
                Available = $online.Version
                Type      = "PowerShell Module"
            }
            
            Write-Host "  📦 $($module.Name): " -NoNewline -ForegroundColor Gray
            Write-Host "$versionDiff" -ForegroundColor Yellow
            
            if ($Action -eq "update" -and (-not $DryRun)) {
                if ([string]::IsNullOrWhiteSpace($Package) -or $Package -eq $module.Name) {
                    Write-Host "     Updating..." -ForegroundColor Gray
                    Update-Module -Name $module.Name -Force
                    Write-Host "     ✅ Updated" -ForegroundColor Green
                }
            }
        }
    }
    catch {
        # Module not in gallery or error checking
    }
}

if ($findings.PowerShell.Count -eq 0) {
    Write-Host "  ✅ All PowerShell modules up-to-date" -ForegroundColor Green
}

# ---------------------------------------------------------
# Node.js (npm)
# ---------------------------------------------------------

if (Test-Path "package.json") {
    Write-Host "`n🔍 Checking Node.js packages...`n" -ForegroundColor Cyan
    
    try {
        $npmCheck = npm outdated --json 2>$null | ConvertFrom-Json
        
        if ($npmCheck) {
            $npmCheck.PSObject.Properties | ForEach-Object {
                $pkg = $_.Value
                $findings.Node += @{
                    Name      = $_.Name
                    Current   = $pkg.current
                    Available = $pkg.latest
                    Type      = "npm package"
                }
                
                Write-Host "  📦 $($_.Name): " -NoNewline -ForegroundColor Gray
                Write-Host "$($pkg.current) → $($pkg.latest)" -ForegroundColor Yellow
            }
            
            if ($Action -eq "update" -and (-not $DryRun)) {
                Write-Host "`n  Updating npm packages..." -ForegroundColor Gray
                if ($IncludeMajor) {
                    npm update
                }
                else {
                    npm update --save
                }
                Write-Host "  ✅ Updated" -ForegroundColor Green
            }
        }
        else {
            Write-Host "  ✅ All npm packages up-to-date" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  ⚠️  npm not available or error checking" -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------
# Python (pip)
# ---------------------------------------------------------

if (Test-Path "requirements.txt") {
    Write-Host "`n🔍 Checking Python packages...`n" -ForegroundColor Cyan
    
    try {
        $pipList = pip list --outdated --format=json 2>$null | ConvertFrom-Json
        
        if ($pipList -and $pipList.Count -gt 0) {
            foreach ($pkg in $pipList) {
                $findings.Python += @{
                    Name      = $pkg.name
                    Current   = $pkg.version
                    Available = $pkg.latest_version
                    Type      = "pip package"
                }
                
                Write-Host "  📦 $($pkg.name): " -NoNewline -ForegroundColor Gray
                Write-Host "$($pkg.version) → $($pkg.latest_version)" -ForegroundColor Yellow
            }
            
            if ($Action -eq "update" -and (-not $DryRun)) {
                Write-Host "`n  Updating pip packages..." -ForegroundColor Gray
                pip install --upgrade -r requirements.txt
                Write-Host "  ✅ Updated" -ForegroundColor Green
            }
        }
        else {
            Write-Host "  ✅ All pip packages up-to-date" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  ⚠️  pip not available or error checking" -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------
# Security Audit
# ---------------------------------------------------------

if ($Action -eq "audit") {
    Write-Host "`n🔒 Running security audit...`n" -ForegroundColor Cyan
    
    # npm audit
    if (Test-Path "package.json") {
        Write-Host "  Auditing npm packages..." -ForegroundColor Gray
        npm audit
    }
    
    # pip audit (if available)
    if (Test-Path "requirements.txt") {
        Write-Host "`n  Auditing Python packages..." -ForegroundColor Gray
        try {
            pip-audit 2>$null
        }
        catch {
            Write-Host "  💡 Install pip-audit for security scanning: pip install pip-audit" -ForegroundColor Gray
        }
    }
}

# ---------------------------------------------------------
# Summary
# ---------------------------------------------------------

Write-Host "`n" + "─" * 64 -ForegroundColor Gray
Write-Host "`n📋 SUMMARY`n" -ForegroundColor Cyan

$totalUpdates = $findings.PowerShell.Count + $findings.Node.Count + $findings.Python.Count + $findings.NuGet.Count

if ($totalUpdates -eq 0) {
    Write-Host "✅ All dependencies are up-to-date!" -ForegroundColor Green
}
else {
    Write-Host "📦 Updates available: $totalUpdates`n" -ForegroundColor Yellow
    
    if ($findings.PowerShell.Count -gt 0) {
        Write-Host "  PowerShell Modules: $($findings.PowerShell.Count)" -ForegroundColor Gray
    }
    if ($findings.Node.Count -gt 0) {
        Write-Host "  npm Packages: $($findings.Node.Count)" -ForegroundColor Gray
    }
    if ($findings.Python.Count -gt 0) {
        Write-Host "  pip Packages: $($findings.Python.Count)" -ForegroundColor Gray
    }
    
    if ($Action -eq "check") {
        Write-Host "`n💡 Run with -Action 'update' to update dependencies" -ForegroundColor Cyan
    }
}

if ($DryRun) {
    Write-Host "`n💡 Dry run mode - no changes were made" -ForegroundColor Cyan
}

Write-Host ""
