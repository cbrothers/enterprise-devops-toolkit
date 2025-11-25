# issue-update-enhanced.ps1
# Enhanced helper to update GitHub issues AND move them on the project board
# Input: { "issue_number": 1, "action": "start|progress|complete|block", "comment": "..." }
# Output: { "success": true, "issue_url": "...", "project_status": "..." }

param(
    [Parameter(ValueFromPipeline = $true)]
    [string]$InputJson,
    
    [Parameter()]
    [string]$InputFile,
    
    [Parameter()]
    [string]$ProjectNumber = "4",
    
    [Parameter()]
    [string]$Owner = "cbrothers"
)

$ErrorActionPreference = "Stop"

# Read input
if ($InputFile) {
    $inputData = Get-Content $InputFile -Raw | ConvertFrom-Json
}
else {
    $inputData = $InputJson | ConvertFrom-Json
}

# Validate
if (-not $inputData.issue_number) {
    throw "Missing required param: issue_number"
}

$issueNum = $inputData.issue_number
$action = $inputData.action ?? "progress"
$comment = $inputData.comment ?? ""

# Build comment based on action
$emoji = switch ($action) {
    "start" { "🚀" }
    "progress" { "⚡" }
    "complete" { "✅" }
    "block" { "🚧" }
    default { "📝" }
}

# Map action to project status
$statusMap = @{
    "start"    = "In Progress"
    "progress" = "In Progress"
    "complete" = "In Review"
    "block"    = "In Progress"  # Keep in progress but add blocked label
}

# Map action to labels
$labelActions = @{
    "start"    = @{ add = @("in-progress"); remove = @() }
    "progress" = @{ add = @(); remove = @() }
    "complete" = @{ add = @("ready-for-review"); remove = @("in-progress", "blocked") }
    "block"    = @{ add = @("blocked"); remove = @() }
}

$targetStatus = $statusMap[$action]
$labelsToAdd = $labelActions[$action].add
$labelsToRemove = $labelActions[$action].remove

Write-Host "`n🔄 Updating issue #$issueNum - Action: $action" -ForegroundColor Cyan

# 1. Update labels
if ($labelsToAdd.Count -gt 0) {
    Write-Host "  📌 Adding labels: $($labelsToAdd -join ', ')" -ForegroundColor Yellow
    foreach ($label in $labelsToAdd) {
        gh issue edit $issueNum --add-label $label 2>&1 | Out-Null
    }
}

if ($labelsToRemove.Count -gt 0) {
    Write-Host "  📌 Removing labels: $($labelsToRemove -join ', ')" -ForegroundColor Yellow
    foreach ($label in $labelsToRemove) {
        gh issue edit $issueNum --remove-label $label 2>&1 | Out-Null
    }
}

# 2. Post comment
$fullComment = "$emoji $comment"
Write-Host "  💬 Adding comment..." -ForegroundColor Yellow
$result = gh issue comment $issueNum --body $fullComment 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "Failed to update issue: $result"
}

# 3. Move on project board
Write-Host "  📊 Moving to '$targetStatus' on project board..." -ForegroundColor Yellow

# Get the project item ID for this issue
$itemQuery = gh project item-list $ProjectNumber --owner $Owner --format json --limit 100 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ⚠️  Warning: Could not query project items" -ForegroundColor Yellow
    $projectUpdated = $false
}
else {
    $items = $itemQuery | ConvertFrom-Json
    $issueItem = $items.items | Where-Object { 
        $_.content.type -eq "Issue" -and $_.content.number -eq $issueNum 
    }
    
    if ($issueItem) {
        $itemId = $issueItem.id
        
        # Update the status field
        $updateResult = gh project item-edit --id $itemId --project-id "PVT_kwHOABIcL84BJAWk" --field-id "PVTSSF_lAHOABIcL84BJAWkzg5TBLo" --text $targetStatus 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Moved to '$targetStatus'" -ForegroundColor Green
            $projectUpdated = $true
        }
        else {
            Write-Host "  ⚠️  Warning: Could not update project status: $updateResult" -ForegroundColor Yellow
            $projectUpdated = $false
        }
    }
    else {
        Write-Host "  ⚠️  Warning: Issue not found on project board" -ForegroundColor Yellow
        $projectUpdated = $false
    }
}

# 4. Get issue URL
$issueUrl = gh issue view $issueNum --json url --jq '.url' 2>&1

Write-Host "  🔗 $issueUrl" -ForegroundColor Gray
Write-Host "✅ Issue #$issueNum updated successfully`n" -ForegroundColor Green

# Output
@{
    success         = $true
    issue_url       = $issueUrl
    action          = $action
    project_status  = $targetStatus
    project_updated = $projectUpdated
} | ConvertTo-Json -Compress
