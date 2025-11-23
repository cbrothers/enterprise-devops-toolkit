# Verify-Migration.ps1
# Verification script to run after repository migration

param(
    [string]$OldName = "antigravity-safe-git-workflow",
    [string]$NewName = "enterprise-devops-toolkit"
)

$ErrorActionPreference = "Continue"

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              MIGRATION VERIFICATION                           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n🔍 Verifying migration from '$OldName' to '$NewName'...`n" -ForegroundColor Yellow

$issues = @()
$warnings = @()
$success = @()

# ---------------------------------------------------------
# Check Git Remote URL
# ---------------------------------------------------------

Write-Host "📡 Checking Git remote URL..." -ForegroundColor Cyan

try {
    $remote = git remote get-url origin 2>$null
    if ($remote -like "*$NewName*") {
        Write-Host "  ✅ Remote URL updated correctly" -ForegroundColor Green
        Write-Host "     $remote" -ForegroundColor Gray
        $success += "Remote URL"
    }
    elseif ($remote -like "*$OldName*") {
        Write-Host "  ❌ Remote URL still uses old name" -ForegroundColor Red
        Write-Host "     $remote" -ForegroundColor Gray
        $issues += "Remote URL needs updating"
        Write-Host "`n  Fix with:" -ForegroundColor Yellow
        Write-Host "  git remote set-url origin https://github.com/USERNAME/$NewName.git" -ForegroundColor White
    }
    else {
        Write-Host "  ⚠️  Remote URL doesn't match expected pattern" -ForegroundColor Yellow
        Write-Host "     $remote" -ForegroundColor Gray
        $warnings += "Remote URL unexpected"
    }
}
catch {
    Write-Host "  ❌ Could not get remote URL" -ForegroundColor Red
    $issues += "Git remote not configured"
}

# ---------------------------------------------------------
# Check README
# ---------------------------------------------------------

Write-Host "`n📄 Checking README.md..." -ForegroundColor Cyan

if (Test-Path "README.md") {
    $readme = Get-Content "README.md" -Raw
    
    # Check for new name
    if ($readme -like "*$NewName*" -or $readme -like "*Enterprise DevOps Toolkit*") {
        Write-Host "  ✅ README contains new name" -ForegroundColor Green
        $success += "README updated"
    }
    else {
        Write-Host "  ⚠️  README may not be updated" -ForegroundColor Yellow
        $warnings += "README needs review"
    }
    
    # Check for old name
    if ($readme -like "*$OldName*") {
        Write-Host "  ⚠️  README still contains old name references" -ForegroundColor Yellow
        $warnings += "README has old references"
    }
}
else {
    Write-Host "  ❌ README.md not found" -ForegroundColor Red
    $issues += "README.md missing"
}

# ---------------------------------------------------------
# Check for Old References
# ---------------------------------------------------------

Write-Host "`n🔍 Scanning for old references..." -ForegroundColor Cyan

$oldRefs = Get-ChildItem -Recurse -Include "*.md", "*.ps1", "*.json", "*.yml", "*.yaml" -File -ErrorAction SilentlyContinue | 
Select-String $OldName -List

if ($oldRefs) {
    $refCount = $oldRefs.Count
    Write-Host "  ⚠️  Found $refCount file(s) with old references:" -ForegroundColor Yellow
    
    $oldRefs | Select-Object -First 10 | ForEach-Object {
        Write-Host "     - $($_.Path)" -ForegroundColor Gray
    }
    
    if ($refCount -gt 10) {
        Write-Host "     ... and $($refCount - 10) more" -ForegroundColor Gray
    }
    
    $warnings += "$refCount files with old references"
}
else {
    Write-Host "  ✅ No old references found" -ForegroundColor Green
    $success += "No old references"
}

# ---------------------------------------------------------
# Check Directory Structure
# ---------------------------------------------------------

Write-Host "`n📁 Checking directory structure..." -ForegroundColor Cyan

$expectedDirs = @(".agent", "scripts", "workflows")
$missingDirs = @()

foreach ($dir in $expectedDirs) {
    if (Test-Path $dir) {
        Write-Host "  ✅ $dir exists" -ForegroundColor Green
    }
    else {
        Write-Host "  ❌ $dir missing" -ForegroundColor Red
        $missingDirs += $dir
    }
}

if ($missingDirs.Count -eq 0) {
    $success += "Directory structure intact"
}
else {
    $issues += "Missing directories: $($missingDirs -join ', ')"
}

# ---------------------------------------------------------
# Check Scripts Accessibility
# ---------------------------------------------------------

Write-Host "`n🔧 Checking scripts..." -ForegroundColor Cyan

$criticalScripts = @(
    "scripts\Review-Code.ps1",
    "scripts\Audit-Security.ps1",
    "scripts\Setup-Monitoring.ps1"
)

$missingScripts = @()

foreach ($script in $criticalScripts) {
    if (Test-Path $script) {
        Write-Host "  ✅ $(Split-Path $script -Leaf)" -ForegroundColor Green
    }
    else {
        Write-Host "  ❌ $(Split-Path $script -Leaf) not found" -ForegroundColor Red
        $missingScripts += $script
    }
}

if ($missingScripts.Count -eq 0) {
    $success += "All critical scripts present"
}
else {
    $issues += "Missing scripts: $($missingScripts.Count)"
}

# ---------------------------------------------------------
# Check Workflows
# ---------------------------------------------------------

Write-Host "`n📋 Checking workflows..." -ForegroundColor Cyan

$workflowCount = (Get-ChildItem -Path "workflows" -Filter "*.md" -File -ErrorAction SilentlyContinue).Count

if ($workflowCount -gt 0) {
    Write-Host "  ✅ Found $workflowCount workflow(s)" -ForegroundColor Green
    $success += "$workflowCount workflows"
}
else {
    Write-Host "  ⚠️  No workflows found" -ForegroundColor Yellow
    $warnings += "No workflows found"
}

# ---------------------------------------------------------
# Summary
# ---------------------------------------------------------

Write-Host "`n" + "─" * 64 -ForegroundColor Gray
Write-Host "`n📊 MIGRATION VERIFICATION SUMMARY`n" -ForegroundColor Cyan

if ($success.Count -gt 0) {
    Write-Host "✅ SUCCESS ($($success.Count)):" -ForegroundColor Green
    $success | ForEach-Object { Write-Host "   - $_" -ForegroundColor Green }
    Write-Host ""
}

if ($warnings.Count -gt 0) {
    Write-Host "⚠️  WARNINGS ($($warnings.Count)):" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host "   - $_" -ForegroundColor Yellow }
    Write-Host ""
}

if ($issues.Count -gt 0) {
    Write-Host "❌ ISSUES ($($issues.Count)):" -ForegroundColor Red
    $issues | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
    Write-Host ""
}

# Final verdict
Write-Host "═" * 64 -ForegroundColor Gray
if ($issues.Count -eq 0) {
    Write-Host "`n🎉 Migration verification PASSED!" -ForegroundColor Green
    Write-Host "   Your repository is ready to use.`n" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`n⚠️  Migration verification found issues" -ForegroundColor Yellow
    Write-Host "   Please address the issues above.`n" -ForegroundColor Yellow
    exit 1
}
