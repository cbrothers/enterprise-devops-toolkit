# Repository Migration Guide

## Renaming: `antigravity-safe-git-workflow` → `enterprise-devops-toolkit`

This guide walks you through renaming and restructuring the repository to reflect its expanded scope.

---

## 📋 Pre-Migration Checklist

- [ ] Backup current repository
- [ ] Notify all users/contributors
- [ ] Update documentation references
- [ ] Plan communication strategy
- [ ] Schedule migration window

---

## 🔄 Migration Steps

### **Step 1: Backup Everything**

```bash
# Create a complete backup
cd /path/to/antigravity-safe-git-workflow
git bundle create ../antigravity-backup.bundle --all

# Verify backup
git bundle verify ../antigravity-backup.bundle
```

### **Step 2: Rename on GitHub**

1. Go to repository **Settings**
2. Scroll to **Repository name**
3. Change to: `enterprise-devops-toolkit`
4. Click **Rename**

✅ GitHub automatically redirects old URLs for a period

### **Step 3: Update Local Repository**

```bash
# Update remote URL
git remote set-url origin https://github.com/USERNAME/enterprise-devops-toolkit.git

# Verify
git remote -v

# Pull to confirm
git pull
```

### **Step 4: Update README**

```bash
# Replace old README with new one
mv README.md README-OLD.md
mv README-NEW.md README.md

# Commit the change
git add README.md README-OLD.md
git commit -m "docs: update README to reflect enterprise scope"
git push
```

### **Step 5: Restructure Directories** (Optional but Recommended)

```bash
# Create new structure
mkdir -p workflows/{development,architecture,operations,infrastructure}
mkdir -p scripts/{development,architecture,operations,infrastructure}

# Move workflows
mv workflows/smart-edit.md workflows/development/
mv workflows/git-workflow.md workflows/development/
mv workflows/code-review.md workflows/development/
mv workflows/security-audit.md workflows/development/
mv workflows/performance-profiling.md workflows/development/
mv workflows/integration-testing.md workflows/development/

mv workflows/tech-stack-advisor.md workflows/architecture/
mv workflows/documentation-generation.md workflows/architecture/

mv workflows/system-operations.md workflows/operations/
mv workflows/monitoring-advisor.md workflows/operations/
mv workflows/logging-setup.md workflows/operations/
mv workflows/dependency-management.md workflows/operations/
mv workflows/developer-onboarding.md workflows/operations/

mv workflows/build-dependency-tracking.md workflows/infrastructure/

# Move scripts (similar pattern)
# ... (repeat for scripts directory)

# Commit restructure
git add .
git commit -m "refactor: reorganize workflows and scripts by category"
git push
```

### **Step 6: Update Documentation Links**

Update all internal links in:
- [ ] README.md
- [ ] WORKFLOW_SUITE.md
- [ ] CHANGELOG.md
- [ ] All workflow .md files
- [ ] All script files

```bash
# Find all markdown files with old references
grep -r "antigravity-safe-git-workflow" . --include="*.md"

# Update them (example)
find . -name "*.md" -exec sed -i 's/antigravity-safe-git-workflow/enterprise-devops-toolkit/g' {} +

# Commit
git add .
git commit -m "docs: update all references to new repository name"
git push
```

### **Step 7: Update Package/Config Files**

If you have any:
- [ ] package.json
- [ ] .csproj files
- [ ] pyproject.toml
- [ ] go.mod
- [ ] Any other config files

```bash
# Example for package.json
# Update "name", "repository", "homepage" fields

git add .
git commit -m "chore: update package configs with new name"
git push
```

---

## 📢 Communication Plan

### **Announcement Template**

```markdown
# 🎉 Repository Renamed: enterprise-devops-toolkit

We've renamed this repository to better reflect its expanded scope!

**Old Name:** antigravity-safe-git-workflow
**New Name:** enterprise-devops-toolkit

## What Changed?
- Repository name and URL
- Broader scope (16 workflows, not just Git)
- Updated documentation
- Better organization

## What Stayed the Same?
- All functionality
- Git history
- Core features
- Your favorite workflows

## Action Required

Update your local repository:
```bash
git remote set-url origin https://github.com/USERNAME/enterprise-devops-toolkit.git
```

## Why the Change?

This toolkit has grown from a single-purpose Git workflow tool into a comprehensive enterprise DevOps platform with:
- 16 professional workflows
- 18 automation scripts
- Support for 5 different roles
- Coverage of development, architecture, and operations

The new name better represents what we've built together!

Questions? Open an issue or discussion.
```

### **Where to Announce**
- [ ] GitHub Discussions
- [ ] README.md (add banner)
- [ ] Release notes
- [ ] Social media (if applicable)
- [ ] Email to contributors
- [ ] Slack/Discord (if applicable)

---

## 🔗 Update External References

### **GitHub**
- [ ] Update repository description
- [ ] Update topics/tags
- [ ] Update website URL (if set)
- [ ] Update social preview image

### **Documentation Sites**
- [ ] GitHub Pages (if using)
- [ ] ReadTheDocs (if using)
- [ ] Any external wikis

### **Package Registries**
- [ ] npm (if published)
- [ ] PowerShell Gallery (if published)
- [ ] PyPI (if published)

### **Other Platforms**
- [ ] Stack Overflow references
- [ ] Blog posts
- [ ] Tutorial videos
- [ ] External documentation

---

## ✅ Post-Migration Checklist

### **Immediate (Day 1)**
- [ ] Verify all links work
- [ ] Test clone from new URL
- [ ] Verify CI/CD pipelines
- [ ] Check GitHub Actions
- [ ] Test all scripts still work

### **Week 1**
- [ ] Monitor for broken links
- [ ] Respond to user questions
- [ ] Update any missed references
- [ ] Verify search engines updated

### **Month 1**
- [ ] Remove old README backup
- [ ] Archive old documentation
- [ ] Update any external integrations
- [ ] Review analytics/traffic

---

## 🆘 Troubleshooting

### **Users Can't Find Repository**

GitHub redirects work, but:
```bash
# They can update manually
git remote set-url origin https://github.com/USERNAME/enterprise-devops-toolkit.git
```

### **Broken CI/CD**

Update pipeline configs:
```yaml
# .github/workflows/*.yml
# Update any hardcoded repository names
```

### **Broken Badges**

Update README badges:
```markdown
# Old
[![Build](https://github.com/USER/antigravity-safe-git-workflow/...)]

# New
[![Build](https://github.com/USER/enterprise-devops-toolkit/...)]
```

### **Lost Stars/Forks**

Don't worry! GitHub preserves:
- ⭐ Stars
- 🍴 Forks
- 👁️ Watchers
- 📊 Insights

---

## 📊 Verification Script

```powershell
# Verify-Migration.ps1
# Run this after migration to verify everything works

Write-Host "🔍 Verifying Migration..." -ForegroundColor Cyan

# Check remote URL
$remote = git remote get-url origin
if ($remote -like "*enterprise-devops-toolkit*") {
    Write-Host "✅ Remote URL updated" -ForegroundColor Green
} else {
    Write-Host "❌ Remote URL not updated: $remote" -ForegroundColor Red
}

# Check README
if (Test-Path "README.md") {
    $readme = Get-Content "README.md" -Raw
    if ($readme -like "*Enterprise DevOps Toolkit*") {
        Write-Host "✅ README updated" -ForegroundColor Green
    } else {
        Write-Host "⚠️  README may need updating" -ForegroundColor Yellow
    }
}

# Check for old references
$oldRefs = Get-ChildItem -Recurse -Include "*.md","*.ps1" | 
    Select-String "antigravity-safe-git-workflow" -List

if ($oldRefs) {
    Write-Host "⚠️  Found old references in:" -ForegroundColor Yellow
    $oldRefs | ForEach-Object { Write-Host "   - $($_.Path)" -ForegroundColor Gray }
} else {
    Write-Host "✅ No old references found" -ForegroundColor Green
}

# Test scripts
Write-Host "`n🧪 Testing scripts..." -ForegroundColor Cyan
$testScript = ".agent\scripts\Review-Code.ps1"
if (Test-Path $testScript) {
    Write-Host "✅ Scripts accessible" -ForegroundColor Green
} else {
    Write-Host "❌ Scripts not found" -ForegroundColor Red
}

Write-Host "`n✅ Migration verification complete!" -ForegroundColor Green
```

---

## 🎯 Timeline

**Recommended Migration Timeline:**

- **Week -1**: Announce upcoming change
- **Day 0**: Perform migration (30 minutes)
- **Day 1-7**: Monitor and fix issues
- **Week 2-4**: Update external references
- **Month 2**: Remove old documentation

---

## 📝 Notes

- GitHub maintains redirects from old URL indefinitely
- Git history is fully preserved
- All issues, PRs, and discussions remain intact
- Stars, forks, and watchers are preserved
- No data loss occurs during rename

---

**Ready to migrate? Follow the steps above and you'll have a professionally renamed repository in under an hour!** 🚀
