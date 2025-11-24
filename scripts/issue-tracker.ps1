# GitHub Issue Tracker for Antigravity AI Agent
# Automates issue status updates and comments

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("start", "update", "complete", "block", "close")]
    [string]$Action,
    
    [Parameter(Mandatory = $true)]
    [int]$IssueNumber,
    
    [string]$Message = "",
    [string]$TimeSpent = "",
    [string]$Repo = "cbrothers/merchifai"
)

$agentSignature = "🤖 **Antigravity AI Agent** - Automated Development Assistant"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"

function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Error { param($msg) Write-Host $msg -ForegroundColor Red }

Write-Info "Processing issue #$IssueNumber - Action: $Action"

switch ($Action) {
    "start" {
        # Add in-progress label
        gh issue edit $IssueNumber --add-label "in-progress" --repo $Repo 2>&1 | Out-Null
        
        $body = @"
$agentSignature

**Status:** Started work
**Timestamp:** $timestamp

$Message

---
*This is an automated update. The AI agent is actively working on this issue.*
"@
        
        gh issue comment $IssueNumber --repo $Repo --body $body
        Write-Success "✓ Started work on issue #$IssueNumber"
    }
    
    "update" {
        $timeLog = if ($TimeSpent) { "`n**Time spent:** $TimeSpent" } else { "" }
        
        $body = @"
$agentSignature

**Status:** Progress Update
**Timestamp:** $timestamp$timeLog

$Message

---
*Automated progress update*
"@
        
        gh issue comment $IssueNumber --repo $Repo --body $body
        Write-Success "✓ Updated issue #$IssueNumber"
    }
    
    "complete" {
        # Remove in-progress, add ready-for-review
        gh issue edit $IssueNumber --remove-label "in-progress" --add-label "ready-for-review" --repo $Repo 2>&1 | Out-Null
        
        $timeLog = if ($TimeSpent) { "`n**Total time:** $TimeSpent" } else { "" }
        
        $body = @"
$agentSignature

**Status:** Work Complete ✅
**Timestamp:** $timestamp$timeLog

$Message

**Next steps:** Ready for user review and approval

---
*Automated completion notice*
"@
        
        gh issue comment $IssueNumber --repo $Repo --body $body
        Write-Success "✓ Completed work on issue #$IssueNumber"
    }
    
    "block" {
        # Add blocked label
        gh issue edit $IssueNumber --add-label "blocked" --repo $Repo 2>&1 | Out-Null
        
        $body = @"
$agentSignature

**Status:** BLOCKED 🚫
**Timestamp:** $timestamp

$Message

**Action required:** User input or decision needed to proceed

---
*Automated blocker notification*
"@
        
        gh issue comment $IssueNumber --repo $Repo --body $body
        Write-Error "⚠ Issue #$IssueNumber is now blocked"
    }
    
    "close" {
        $body = @"
$agentSignature

**Status:** Closing Issue
**Timestamp:** $timestamp

$Message

**Resolution:** Issue has been completed and verified

---
*Automated closure*
"@
        
        gh issue close $IssueNumber --repo $Repo --comment $body
        Write-Success "✓ Closed issue #$IssueNumber"
    }
}

Write-Info "View issue: https://github.com/$Repo/issues/$IssueNumber"
