<#
.SYNOPSIS
    Injects version information into build files.

.DESCRIPTION
    This script generates version strings from Git information and injects them
    into build configuration files. Supports multiple build tools including Vite,
    webpack, and direct HTML injection.

.PARAMETER BuildTool
    The build tool being used. Valid values: 'vite', 'webpack', 'html', 'auto'
    Default: 'auto' (attempts to detect)

.PARAMETER ConfigFile
    Path to the build configuration file. If not specified, will use defaults
    based on the build tool.

.PARAMETER Format
    Version string format. Available placeholders:
    - {hash}: Short Git commit hash
    - {date}: Build date (YYYYMMDDHHmmss format)
    - {branch}: Current Git branch
    - {tag}: Latest Git tag (if any)
    Default: 'Version: {hash}-{date}-{branch}'

.PARAMETER OutputVariable
    The variable name to use in the build configuration.
    Default: '__APP_VERSION__'

.PARAMETER HtmlFiles
    Array of HTML files to inject version into (for HTML mode)

.EXAMPLE
    .\Inject-Version.ps1
    Auto-detects build tool and injects version

.EXAMPLE
    .\Inject-Version.ps1 -BuildTool vite
    Injects version into Vite configuration

.EXAMPLE
    .\Inject-Version.ps1 -BuildTool html -HtmlFiles @("index.html", "about.html")
    Injects version directly into HTML files

.EXAMPLE
    .\Inject-Version.ps1 -Format "{hash}-{branch}"
    Uses custom version format

.NOTES
    Requires Git to be installed and accessible in PATH
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('vite', 'webpack', 'html', 'auto')]
    [string]$BuildTool = 'auto',

    [Parameter(Mandatory = $false)]
    [string]$ConfigFile,

    [Parameter(Mandatory = $false)]
    [string]$Format = 'Version: {hash}-{date}-{branch}',

    [Parameter(Mandatory = $false)]
    [string]$OutputVariable = '__APP_VERSION__',

    [Parameter(Mandatory = $false)]
    [string[]]$HtmlFiles = @()
)

# Color output functions
function Write-Success { param([string]$Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Warning { param([string]$Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-Host "❌ $Message" -ForegroundColor Red }

# Get Git information
function Get-GitInfo {
    try {
        $hash = git rev-parse --short HEAD 2>$null
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        $tag = git describe --tags --abbrev=0 2>$null
        $date = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")

        return @{
            Hash   = $hash
            Branch = $branch
            Tag    = $tag
            Date   = $date
        }
    }
    catch {
        Write-Error "Failed to get Git information. Is Git installed and is this a Git repository?"
        exit 1
    }
}

# Generate version string
function New-VersionString {
    param([hashtable]$GitInfo, [string]$Format)

    $version = $Format
    $version = $version -replace '\{hash\}', $GitInfo.Hash
    $version = $version -replace '\{date\}', $GitInfo.Date
    $version = $version -replace '\{branch\}', $GitInfo.Branch
    $version = $version -replace '\{tag\}', $(if ($GitInfo.Tag) { $GitInfo.Tag } else { 'untagged' })

    return $version
}

# Detect build tool
function Get-BuildTool {
    if (Test-Path "vite.config.js" -or Test-Path "vite.config.ts") {
        return 'vite'
    }
    if (Test-Path "webpack.config.js" -or Test-Path "webpack.config.ts") {
        return 'webpack'
    }
    return 'html'
}

# Inject into Vite config
function Set-ViteVersion {
    param([string]$VersionString, [string]$ConfigPath)

    if (-not $ConfigPath) {
        $ConfigPath = if (Test-Path "vite.config.js") { "vite.config.js" } else { "vite.config.ts" }
    }

    if (-not (Test-Path $ConfigPath)) {
        Write-Error "Vite config file not found: $ConfigPath"
        return $false
    }

    Write-Info "Injecting version into Vite config: $ConfigPath"

    $content = Get-Content $ConfigPath -Raw

    # Check if version injection already exists
    if ($content -match "define:\s*\{[^}]*$OutputVariable") {
        Write-Info "Version injection already exists, updating..."
        $content = $content -replace "('$OutputVariable':\s*JSON\.stringify\()'[^']*'", "`$1'$VersionString'"
        $content = $content -replace "(""$OutputVariable"":\s*JSON\.stringify\()""[^""]*""", "`$1""$VersionString"""
    }
    else {
        # Add version injection
        $injection = @"

// Version injection
const __VERSION__ = '$VersionString';

export default defineConfig({
  define: {
    '$OutputVariable': JSON.stringify(__VERSION__)
  },
"@
        $content = $content -replace "(export default defineConfig\(\{)", $injection
    }

    $content | Set-Content $ConfigPath -NoNewline
    Write-Success "Version injected into Vite config"
    return $true
}

# Inject into HTML files
function Set-HtmlVersion {
    param([string]$VersionString, [string[]]$Files)

    if ($Files.Count -eq 0) {
        Write-Warning "No HTML files specified"
        return $false
    }

    $success = $true
    foreach ($file in $Files) {
        if (Test-Path $file) {
            $content = Get-Content $file -Raw
            $content = $content -replace '{{VERSION}}', $VersionString
            $content = $content -replace '{{GIT_COMMIT_HASH}}', $GitInfo.Hash
            $content = $content -replace '{{BUILD_DATE}}', $GitInfo.Date
            $content | Set-Content $file -NoNewline

            Write-Success "Version injected into $file"
        }
        else {
            Write-Warning "File not found: $file"
            $success = $false
        }
    }

    return $success
}

# Main execution
function Main {
    Write-Info "=== Version Injection Tool ==="
    Write-Info ""

    # Get Git information
    $gitInfo = Get-GitInfo
    Write-Info "Git Hash: $($gitInfo.Hash)"
    Write-Info "Branch: $($gitInfo.Branch)"
    Write-Info "Tag: $(if ($gitInfo.Tag) { $gitInfo.Tag } else { 'none' })"
    Write-Info "Build Date: $($gitInfo.Date)"
    Write-Info ""

    # Generate version string
    $versionString = New-VersionString -GitInfo $gitInfo -Format $Format
    Write-Info "Version String: $versionString"
    Write-Info ""

    # Detect or use specified build tool
    $tool = if ($BuildTool -eq 'auto') { Get-BuildTool } else { $BuildTool }
    Write-Info "Build Tool: $tool"
    Write-Info ""

    # Inject version based on build tool
    $success = switch ($tool) {
        'vite' {
            Set-ViteVersion -VersionString $versionString -ConfigPath $ConfigFile
        }
        'webpack' {
            Write-Warning "Webpack support not yet implemented"
            $false
        }
        'html' {
            Set-HtmlVersion -VersionString $versionString -Files $HtmlFiles
        }
        default {
            Write-Error "Unknown build tool: $tool"
            $false
        }
    }

    if ($success) {
        Write-Success "=== Version Injection Complete ==="
    }
    else {
        Write-Error "=== Version Injection Failed ==="
        exit 1
    }
}

# Run main function
Main
