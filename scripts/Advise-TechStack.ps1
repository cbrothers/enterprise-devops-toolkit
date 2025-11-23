# Advise-TechStack.ps1
# Technology recommendation and architecture decision support

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("analyze", "recommend", "compare", "adr", "audit")]
    [string]$Action,
    
    [string]$Requirements,
    [string]$Technologies,
    [string]$Decision,
    [string]$OutputDir = "docs/architecture"
)

$ErrorActionPreference = "Continue"

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║            TECHNOLOGY STACK ADVISOR                           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Technology database
$techDatabase = @{
    Frontend = @{
        React   = @{
            Maturity      = "High"
            LearningCurve = "Medium"
            Performance   = "High"
            Ecosystem     = "Excellent"
            UseCases      = @("SPA", "Dashboard", "Mobile")
        }
        Vue     = @{
            Maturity      = "High"
            LearningCurve = "Low"
            Performance   = "High"
            Ecosystem     = "Good"
            UseCases      = @("SPA", "Progressive Enhancement")
        }
        Angular = @{
            Maturity      = "High"
            LearningCurve = "High"
            Performance   = "Good"
            Ecosystem     = "Excellent"
            UseCases      = @("Enterprise", "Large Teams")
        }
    }
    Backend  = @{
        "Node.js" = @{
            Maturity      = "High"
            LearningCurve = "Low"
            Performance   = "Good"
            Ecosystem     = "Excellent"
            UseCases      = @("API", "Microservices", "Real-time")
        }
        Python    = @{
            Maturity      = "High"
            LearningCurve = "Low"
            Performance   = "Medium"
            Ecosystem     = "Excellent"
            UseCases      = @("API", "ML", "Data Processing")
        }
        Go        = @{
            Maturity      = "Medium"
            LearningCurve = "Medium"
            Performance   = "Excellent"
            Ecosystem     = "Good"
            UseCases      = @("Microservices", "CLI", "High Performance")
        }
    }
    Database = @{
        PostgreSQL = @{
            Maturity      = "High"
            LearningCurve = "Medium"
            Performance   = "High"
            Ecosystem     = "Excellent"
            UseCases      = @("Relational", "JSON", "Full-text Search")
        }
        MongoDB    = @{
            Maturity      = "High"
            LearningCurve = "Low"
            Performance   = "High"
            Ecosystem     = "Good"
            UseCases      = @("Document Store", "Flexible Schema")
        }
        Redis      = @{
            Maturity      = "High"
            LearningCurve = "Low"
            Performance   = "Excellent"
            Ecosystem     = "Good"
            UseCases      = @("Cache", "Session Store", "Pub/Sub")
        }
    }
}

# ---------------------------------------------------------
# Analyze Current Stack
# ---------------------------------------------------------

if ($Action -eq "analyze") {
    Write-Host "`n🔍 Analyzing current technology stack...`n" -ForegroundColor Cyan
    
    $findings = @{
        Technologies    = @()
        Warnings        = @()
        Recommendations = @()
    }
    
    # Detect package.json (Node.js)
    if (Test-Path "package.json") {
        $packageJson = Get-Content "package.json" | ConvertFrom-Json
        Write-Host "  📦 Node.js project detected" -ForegroundColor Green
        
        if ($packageJson.dependencies) {
            Write-Host "`n  Dependencies:" -ForegroundColor Gray
            $packageJson.dependencies.PSObject.Properties | ForEach-Object {
                Write-Host "    - $($_.Name): $($_.Value)" -ForegroundColor White
                $findings.Technologies += @{
                    Name    = $_.Name
                    Version = $_.Value
                    Type    = "npm package"
                }
            }
        }
    }
    
    # Detect requirements.txt (Python)
    if (Test-Path "requirements.txt") {
        Write-Host "`n  🐍 Python project detected" -ForegroundColor Green
        $requirements = Get-Content "requirements.txt"
        Write-Host "`n  Dependencies:" -ForegroundColor Gray
        $requirements | ForEach-Object {
            if ($_ -match '^([^=<>]+)') {
                Write-Host "    - $_" -ForegroundColor White
            }
        }
    }
    
    # Detect .csproj (C#)
    $csprojFiles = Get-ChildItem -Filter "*.csproj" -File
    if ($csprojFiles) {
        Write-Host "`n  💻 .NET project detected" -ForegroundColor Green
        Write-Host "    Project: $($csprojFiles[0].Name)" -ForegroundColor White
    }
    
    # Recommendations
    Write-Host "`n💡 Recommendations:" -ForegroundColor Cyan
    Write-Host "  - Keep dependencies up to date" -ForegroundColor Gray
    Write-Host "  - Document technology decisions in ADRs" -ForegroundColor Gray
    Write-Host "  - Regular security audits" -ForegroundColor Gray
}

# ---------------------------------------------------------
# Generate Recommendations
# ---------------------------------------------------------

if ($Action -eq "recommend") {
    Write-Host "`n🎯 Generating technology recommendations...`n" -ForegroundColor Cyan
    
    $reqs = @{
        project_type = "web_application"
        scale        = "medium"
        team_size    = 5
    }
    
    if ($Requirements -and (Test-Path $Requirements)) {
        $reqs = Get-Content $Requirements | ConvertFrom-Json
    }
    
    Write-Host "  Project Type: $($reqs.project_type)" -ForegroundColor Gray
    Write-Host "  Scale: $($reqs.scale)" -ForegroundColor Gray
    Write-Host "  Team Size: $($reqs.team_size)`n" -ForegroundColor Gray
    
    # Generate recommendations based on requirements
    Write-Host "📋 Recommended Stack:`n" -ForegroundColor Cyan
    
    # Frontend recommendation
    $frontendRec = "React"
    if ($reqs.team_size -lt 3) {
        $frontendRec = "Vue"
    }
    elseif ($reqs.scale -eq "large") {
        $frontendRec = "Angular"
    }
    
    Write-Host "  Frontend:" -ForegroundColor Yellow
    Write-Host "    ✅ $frontendRec" -ForegroundColor Green
    Write-Host "       Reason: " -NoNewline -ForegroundColor Gray
    Write-Host "Best fit for your team size and scale" -ForegroundColor White
    
    # Backend recommendation
    Write-Host "`n  Backend:" -ForegroundColor Yellow
    $backendRec = "Node.js + Express"
    if ($reqs.project_type -eq "data_processing") {
        $backendRec = "Python + FastAPI"
    }
    elseif ($reqs.scale -eq "large") {
        $backendRec = "Go + Gin"
    }
    Write-Host "    ✅ $backendRec" -ForegroundColor Green
    Write-Host "       Reason: " -NoNewline -ForegroundColor Gray
    Write-Host "Optimal performance for your requirements" -ForegroundColor White
    
    # Database recommendation
    Write-Host "`n  Database:" -ForegroundColor Yellow
    Write-Host "    ✅ PostgreSQL" -ForegroundColor Green
    Write-Host "       Reason: " -NoNewline -ForegroundColor Gray
    Write-Host "Versatile, reliable, excellent for most use cases" -ForegroundColor White
    Write-Host "    ✅ Redis (caching)" -ForegroundColor Green
    Write-Host "       Reason: " -NoNewline -ForegroundColor Gray
    Write-Host "Performance boost for frequently accessed data" -ForegroundColor White
}

# ---------------------------------------------------------
# Compare Technologies
# ---------------------------------------------------------

if ($Action -eq "compare" -and $Technologies) {
    Write-Host "`n⚖️  Comparing technologies...`n" -ForegroundColor Cyan
    
    $techList = $Technologies -split ','
    
    foreach ($tech in $techList) {
        $tech = $tech.Trim()
        Write-Host "  $tech" -ForegroundColor Yellow
        
        # Find in database
        $found = $false
        foreach ($category in $techDatabase.Keys) {
            if ($techDatabase[$category].ContainsKey($tech)) {
                $info = $techDatabase[$category][$tech]
                Write-Host "    Maturity: $($info.Maturity)" -ForegroundColor Gray
                Write-Host "    Learning Curve: $($info.LearningCurve)" -ForegroundColor Gray
                Write-Host "    Performance: $($info.Performance)" -ForegroundColor Gray
                Write-Host "    Ecosystem: $($info.Ecosystem)" -ForegroundColor Gray
                Write-Host "    Best For: $($info.UseCases -join ', ')" -ForegroundColor Gray
                $found = $true
                break
            }
        }
        
        if (-not $found) {
            Write-Host "    (No data available)" -ForegroundColor Gray
        }
        Write-Host ""
    }
}

# ---------------------------------------------------------
# Generate Architecture Decision Record
# ---------------------------------------------------------

if ($Action -eq "adr" -and $Decision) {
    Write-Host "`n📝 Generating Architecture Decision Record...`n" -ForegroundColor Cyan
    
    # Get next ADR number
    $existingAdrs = Get-ChildItem -Path $OutputDir -Filter "ADR-*.md" -File -ErrorAction SilentlyContinue
    $nextNumber = ($existingAdrs.Count + 1).ToString("000")
    
    $adrContent = @"
# ADR-$nextNumber: $Decision

## Status
Proposed

## Context
<!-- Describe the context and problem statement -->

We need to make a decision about: $Decision

## Decision
<!-- Describe the decision and rationale -->

We will...

## Consequences

### Positive
<!-- List positive consequences -->
- 

### Negative
<!-- List negative consequences -->
- 

### Neutral
<!-- List neutral consequences -->
- 

## Alternatives Considered
<!-- List alternatives and why they were not chosen -->

### Alternative 1
- **Pros:** 
- **Cons:** 
- **Reason not chosen:** 

## References
<!-- Links to relevant documentation, discussions, etc. -->
- 

---
*Created: $(Get-Date -Format 'yyyy-MM-dd')*
*Author: [Your Name]*
"@
    
    $adrPath = Join-Path $OutputDir "ADR-$nextNumber-$($Decision -replace '[^a-zA-Z0-9]', '-').md"
    $adrContent | Set-Content $adrPath
    
    Write-Host "  ✅ Created: $adrPath" -ForegroundColor Green
    Write-Host "  💡 Edit the file to complete the ADR" -ForegroundColor Cyan
}

# ---------------------------------------------------------
# Technology Audit
# ---------------------------------------------------------

if ($Action -eq "audit") {
    Write-Host "`n🔍 Auditing technology choices...`n" -ForegroundColor Cyan
    
    Write-Host "  Checking for:" -ForegroundColor Gray
    Write-Host "    - Deprecated technologies" -ForegroundColor Gray
    Write-Host "    - Security vulnerabilities" -ForegroundColor Gray
    Write-Host "    - License compliance" -ForegroundColor Gray
    Write-Host "    - Version currency`n" -ForegroundColor Gray
    
    # Run dependency audit
    if (Test-Path "package.json") {
        Write-Host "  Running npm audit..." -ForegroundColor Gray
        npm audit --production 2>$null
    }
    
    Write-Host "`n  ✅ Audit complete" -ForegroundColor Green
}

Write-Host ""
