# ======================================================================
# Update-ProjectStatus.ps1
#   Moves a GitHub Issue to a specific status column on a GitHub Project.
#   Now supports looking up the project by *name* (title) via the GH GraphQL API.
# ======================================================================

param(
    [Parameter(Mandatory = $true)][int]$IssueNumber,
    [Parameter(Mandatory = $true)]
    [ValidateSet('Backlog', 'Ready', 'Todo', 'In Progress', 'Testing', 'In Review', 'Done')]
    [string]$Status,

    # New optional parameters -------------------------------------------------
    [string]$Owner = 'cbrothers',
    [string]$Repo = 'PresenseManager',
    [string]$ProjectName,          # e.g. "PresenseManager Development"
    [int]   $ProjectNumber = $null # fallback if you already know the number
)

$ErrorActionPreference = 'Stop'

# ----------------------------------------------------------------------
# Helper: Get project number & ID by name (GraphQL)
# ----------------------------------------------------------------------
function Get-ProjectInfo {
    param(
        [string]$Owner,
        [string]$Repo,
        [string]$Name   # project title (partial match allowed)
    )

    # GraphQL query – fetch the first 100 projects for the owner (try user first)
    $query = @"
{
  user(login: "$Owner") {
    projectsV2(first: 100) {
      nodes {
        id
        number
        title
      }
    }
  }
}
"@

    $response = gh api graphql -f query="$query" --jq '.data.user.projectsV2.nodes' 2>$null
    
    # If user query fails, try organization
    if (-not $response) {
        $query = @"
{
  organization(login: "$Owner") {
    projectsV2(first: 100) {
      nodes {
        id
        number
        title
      }
    }
  }
}
"@
        $response = gh api graphql -f query="$query" --jq '.data.organization.projectsV2.nodes'
    }
    
    if (-not $response) {
        Write-Error "Failed to query GitHub GraphQL API for projects."
        exit 1
    }

    # Find the first project whose title contains the supplied name (case‑insensitive)
    $project = $response | ConvertFrom-Json |
    Where-Object { $_.title -like "*$Name*" } |
    Select-Object -First 1

    if (-not $project) {
        Write-Error "No project found whose title matches '$Name' under $Owner."
        exit 1
    }

    return $project   # object with .id, .number, .title
}

# ----------------------------------------------------------------------
# Resolve the project (number & ID)
# ----------------------------------------------------------------------
if ($ProjectName) {
    Write-Host "🔎 Looking up project by name '$ProjectName'…" -ForegroundColor Cyan
    $projInfo = Get-ProjectInfo -Owner $Owner -Repo $Repo -Name $ProjectName
    $projectNumber = $projInfo.number
    $projectId = $projInfo.id
}
elseif ($ProjectNumber) {
    Write-Host "🔢 Using supplied project number $ProjectNumber…" -ForegroundColor Cyan
    $projectId = (gh project view $ProjectNumber --owner $Owner --format json | ConvertFrom-Json).id
}
else {
    # Fallback to the repo‑name heuristic (old behaviour)
    $repoName = $Repo
    $projectList = gh project list --owner $Owner --format json | ConvertFrom-Json
    $proj = $projectList | Where-Object { $_.title -like "*$repoName*" } | Select-Object -First 1
    if (-not $proj) {
        Write-Error "Could not find a project matching repository '$repoName' for owner $Owner"
        exit 1
    }
    $projectNumber = $proj.number
    $projectId = $proj.id
}

Write-Host "✅ Project resolved: #$projectNumber (ID $projectId)" -ForegroundColor Green

# ----------------------------------------------------------------------
# Find the issue item inside the project
# ----------------------------------------------------------------------
Write-Host "🔎 Finding issue #$IssueNumber in project…" -ForegroundColor Gray
$itemsData = gh project item-list $projectNumber --owner $Owner --format json --limit 200 | ConvertFrom-Json
$item = $itemsData.items | Where-Object { $_.content.number -eq $IssueNumber } | Select-Object -First 1
if (-not $item) {
    Write-Error "Issue #$IssueNumber not found in project #$projectNumber"
    exit 1
}
$itemId = $item.id
Write-Host "Item ID: $itemId" -ForegroundColor Gray

# ----------------------------------------------------------------------
# Resolve the Status field & option ID
# ----------------------------------------------------------------------
Write-Host "🔧 Getting Status field…" -ForegroundColor Gray
$fieldsData = gh project field-list $projectNumber --owner $Owner --format json | ConvertFrom-Json
$statusField = $fieldsData.fields | Where-Object { $_.name -eq 'Status' }
if (-not $statusField) {
    Write-Error "Status field not found in project."
    exit 1
}
$fieldId = $statusField.id
Write-Host "Status Field ID: $fieldId" -ForegroundColor Gray

$statusOption = $statusField.options | Where-Object { $_.name -eq $Status }
if (-not $statusOption) {
    Write-Error "Status option '$Status' not found. Available: $($statusField.options.name -join ', ')"
    exit 1
}
$optionId = $statusOption.id
Write-Host "Status Option ID: $optionId" -ForegroundColor Gray

# ----------------------------------------------------------------------
# Perform the update
# ----------------------------------------------------------------------
Write-Host "🚀 Updating status…" -ForegroundColor Yellow
gh project item-edit `
    --id $itemId `
    --field-id $fieldId `
    --project-id $projectId `
    --single-select-option-id $optionId

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Successfully updated issue #$IssueNumber to '$Status'" -ForegroundColor Green
}
else {
    Write-Error "Failed to update issue status"
    exit 1
}
