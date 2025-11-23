# Deploy-Site.ps1
# Automates the deployment pipeline:
# 1. Stage: Commit -> Push Main -> Sync Stage -> Push Stage
# 2. Production: Sync Stage -> Production -> Push Production

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Stage", "Production")]
    [string]$Target,

    [Parameter(Mandatory = $false)]
    [string]$Message
)

$ErrorActionPreference = "Stop"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host $Message -ForegroundColor $Color
}

try {
    # Ensure we start on main
    $currentBranch = git branch --show-current
    if ($currentBranch -ne "main") {
        Write-ColorOutput "⚠️  Not on main branch. Switching to main..." "Yellow"
        git checkout main
    }

    if ($Target -eq "Stage") {
        if ([string]::IsNullOrWhiteSpace($Message)) {
            Write-Error "Message is required for Stage deployment."
        }

        # 1. Inject Version Info
        Write-ColorOutput "`n🔖 Injecting version info..."
        & "$PSScriptRoot/Inject-Version.ps1"
        
        # 2. Add and Commit to Main
        Write-ColorOutput "`n📦 Staging and Committing changes to MAIN..."
        git add .
        git commit -m "$Message"
        
        # 2. Push to Main
        Write-ColorOutput "`n🚀 Pushing to origin/main..."
        git push origin main

        # 3. Sync Stage
        Write-ColorOutput "`n🔄 Syncing STAGE branch..."
        git checkout stage
        git merge main
        
        # 4. Push Stage
        Write-ColorOutput "`n🚀 Pushing to origin/stage..."
        git push origin stage
        
        Write-ColorOutput "`n✅ Deployed to STAGE! (stage.thesilentwhistleband.com)" "Green"
    }
    elseif ($Target -eq "Production") {
        # 1. Ensure Stage is up to date locally
        Write-ColorOutput "`n🔄 Fetching latest..."
        git fetch origin

        # 2. Sync Production from Stage
        Write-ColorOutput "`n🔄 Syncing PRODUCTION from STAGE..."
        git checkout production
        git merge stage

        # 3. Push Production
        Write-ColorOutput "`n🚀 Pushing to origin/production..."
        git push origin production
        
        Write-ColorOutput "`n✅ Deployed to PRODUCTION! (www.thesilentwhistleband.com)" "Green"
    }

    # Return to Main
    git checkout main

}
catch {
    Write-ColorOutput "`n❌ Error occurred: $_" "Red"
    git checkout main 2>$null
    exit 1
}
