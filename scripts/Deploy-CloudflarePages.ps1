<#
.SYNOPSIS
    Deploys a web application to Cloudflare Pages.

.DESCRIPTION
    This script automates the deployment of web applications to Cloudflare Pages
    using the Wrangler CLI. It supports multiple environments (stage, production)
    and includes build verification, deployment, and rollback capabilities.

.PARAMETER Environment
    The target environment for deployment. Valid values: 'stage', 'production'

.PARAMETER ProjectName
    The Cloudflare Pages project name. If not specified, will attempt to read from package.json

.PARAMETER BuildCommand
    The command to build the project. Default: 'npm run build'

.PARAMETER OutputDirectory
    The directory containing the built files. Default: 'dist'

.PARAMETER SkipBuild
    Skip the build step and deploy existing files

.PARAMETER Force
    Force deployment without confirmation prompts

.PARAMETER DryRun
    Perform all checks but don't actually deploy

.EXAMPLE
    .\Deploy-CloudflarePages.ps1 -Environment production
    Builds and deploys to production environment

.EXAMPLE
    .\Deploy-CloudflarePages.ps1 -Environment stage -SkipBuild
    Deploys to stage without rebuilding

.EXAMPLE
    .\Deploy-CloudflarePages.ps1 -Environment production -DryRun
    Performs a dry run to verify configuration

.NOTES
    Requires:
    - Wrangler CLI installed (npm install -g wrangler)
    - Authenticated with Cloudflare (wrangler login)
    - Git repository with proper branch structure
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('stage', 'production')]
    [string]$Environment,

    [Parameter(Mandatory = $false)]
    [string]$ProjectName,

    [Parameter(Mandatory = $false)]
    [string]$BuildCommand = 'npm run build',

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = 'dist',

    [Parameter(Mandatory = $false)]
    [switch]$SkipBuild,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

# Color output functions
function Write-Success { param([string]$Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Warning { param([string]$Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-Host "❌ $Message" -ForegroundColor Red }

# Check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."

    # Check if wrangler is installed
    try {
        $wranglerVersion = wrangler --version 2>$null
        Write-Success "Wrangler CLI installed: $wranglerVersion"
    }
    catch {
        Write-Error "Wrangler CLI not found. Install with: npm install -g wrangler"
        exit 1
    }

    # Check if authenticated
    try {
        $null = wrangler whoami 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Not authenticated with Cloudflare. Run: wrangler login"
            exit 1
        }
        Write-Success "Authenticated with Cloudflare"
    }
    catch {
        Write-Error "Failed to check authentication status"
        exit 1
    }

    # Check if in a git repository
    if (-not (Test-Path ".git")) {
        Write-Error "Not in a git repository"
        exit 1
    }
    Write-Success "Git repository detected"
}

# Get project name from package.json if not specified
function Get-ProjectName {
    if ($ProjectName) {
        return $ProjectName
    }

    if (Test-Path "package.json") {
        try {
            $packageJson = Get-Content "package.json" -Raw | ConvertFrom-Json
            if ($packageJson.name) {
                Write-Info "Using project name from package.json: $($packageJson.name)"
                return $packageJson.name
            }
        }
        catch {
            Write-Warning "Could not read project name from package.json"
        }
    }

    Write-Error "Project name not specified and could not be determined from package.json"
    Write-Info "Use -ProjectName parameter to specify the project name"
    exit 1
}

# Build the project
function Invoke-Build {
    if ($SkipBuild) {
        Write-Info "Skipping build step"
        return
    }

    Write-Info "Building project with command: $BuildCommand"
    
    # Clean output directory
    if (Test-Path $OutputDirectory) {
        Write-Info "Cleaning output directory: $OutputDirectory"
        Remove-Item -Recurse -Force $OutputDirectory -ErrorAction SilentlyContinue
    }

    # Run build command
    try {
        Invoke-Expression $BuildCommand
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Build failed with exit code $LASTEXITCODE"
            exit 1
        }
        Write-Success "Build completed successfully"
    }
    catch {
        Write-Error "Build failed: $_"
        exit 1
    }

    # Verify output directory exists
    if (-not (Test-Path $OutputDirectory)) {
        Write-Error "Output directory not found: $OutputDirectory"
        exit 1
    }

    $fileCount = (Get-ChildItem -Path $OutputDirectory -Recurse -File).Count
    Write-Success "Output directory contains $fileCount files"
}

# Get current git information
function Get-GitInfo {
    $branch = git rev-parse --abbrev-ref HEAD
    $commit = git rev-parse --short HEAD
    $isDirty = git status --porcelain

    return @{
        Branch  = $branch
        Commit  = $commit
        IsDirty = $isDirty.Length -gt 0
    }
}

# Deploy to Cloudflare Pages
function Invoke-Deployment {
    param([string]$Project, [string]$Branch)

    Write-Info "Deploying to Cloudflare Pages..."
    Write-Info "Project: $Project"
    Write-Info "Environment: $Environment"
    Write-Info "Branch: $Branch"

    if ($DryRun) {
        Write-Warning "DRY RUN - Deployment skipped"
        return
    }

    # Confirm deployment
    if (-not $Force) {
        $confirmation = Read-Host "Deploy to $Environment? (y/N)"
        if ($confirmation -ne 'y') {
            Write-Warning "Deployment cancelled"
            exit 0
        }
    }

    # Deploy with wrangler
    try {
        $deployCmd = "wrangler pages deploy $OutputDirectory --project-name $Project --branch $Branch"
        Write-Info "Running: $deployCmd"
        
        Invoke-Expression $deployCmd
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Deployment failed with exit code $LASTEXITCODE"
            exit 1
        }
        
        Write-Success "Deployment completed successfully!"
    }
    catch {
        Write-Error "Deployment failed: $_"
        exit 1
    }
}

# Main execution
function Main {
    Write-Info "=== Cloudflare Pages Deployment ==="
    Write-Info "Environment: $Environment"
    Write-Info "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Info ""

    # Check prerequisites
    Test-Prerequisites

    # Get project name
    $project = Get-ProjectName

    # Get git info
    $gitInfo = Get-GitInfo
    Write-Info "Current branch: $($gitInfo.Branch)"
    Write-Info "Current commit: $($gitInfo.Commit)"
    
    if ($gitInfo.IsDirty) {
        Write-Warning "Working directory has uncommitted changes"
        if (-not $Force) {
            $continue = Read-Host "Continue anyway? (y/N)"
            if ($continue -ne 'y') {
                Write-Warning "Deployment cancelled"
                exit 0
            }
        }
    }

    # Build the project
    Invoke-Build

    # Deploy
    $branch = if ($Environment -eq 'production') { 'production' } else { 'stage' }
    Invoke-Deployment -Project $project -Branch $branch

    Write-Success "=== Deployment Complete ==="
}

# Run main function
Main
