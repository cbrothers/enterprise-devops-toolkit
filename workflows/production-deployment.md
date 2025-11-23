---
description: Automated workflow for deploying changes to Stage and Production
---

# Deployment Pipeline Workflow

This workflow automates the deployment pipeline: **Local -> Stage -> Production**.

## Pipeline Overview

1.  **Dev (Local)**: Run `python -m http.server` to test locally.
2.  **Stage**: Deploy to `stage` branch (auto-deploys to `stage.thesilentwhistleband.com`).
3.  **Production**: Promote Stage to `production` branch (auto-deploys to `www.thesilentwhistleband.com`).

## Steps

### 1. Deploy to Stage
Use this when you have new changes to commit and want to see them on the staging site.

```powershell
.\.agent\scripts\Deploy-Site.ps1 -Target Stage -Message "Your commit message"
```
*Action: Commits to `main`, pushes `main`, merges to `stage`, pushes `stage`.*

### 2. Promote to Production
Use this ONLY after verifying the Stage site works perfectly.

```powershell
.\.agent\scripts\Deploy-Site.ps1 -Target Production
```
*Action: Merges `stage` into `production`, pushes `production`.*

## Benefits
-   **Safety**: Enforces testing on Stage before touching Production.
-   **Consistency**: Production is always a direct merge from Stage.
-   **Automation**: Handles all git branching/merging logic automatically.
