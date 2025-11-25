# 🧠 Antigravity Memory & Shorthand

This file serves as a self-managed dictionary for the AI agent.
It maps shorthand commands (macros) to complex instructions or workflows.

## 📝 How to Use
- **User**: Type the shorthand (e.g., "run-check").
- **AI**: Look up the shorthand here and execute the defined steps.
- **AI**: If you notice a repetitive pattern, propose adding a new shorthand here.

---

## ⚡ Shorthand Dictionary

| Shorthand | Definition / Action |
| :--- | :--- |
| **`@status`** | **Full Status Report**: Run `git status`, list active branches, show last 3 commits, and check for any unapplied patches or temp files. |
| **`@test-all`** | **Run All Tests**: Execute `Invoke-Pester` on all `*.Tests.ps1` files in the repository and summarize the results. |
| **`@clean`** | **Project Cleanup**: Remove `patch.json`, clear `.agent/tmp/`, and run `git clean -fdX` (dry-run first) to identify ignored garbage. |
| **`@scaffold [name]`** | **New Script Scaffold**: Create a new `.ps1` file in `/scripts` with standard boilerplate (CmdletBinding, help block, error handling) and a matching `.Tests.ps1`. |
| **`@log [msg]`** | **Dev Log**: Append the timestamped message to `DEVLOG.md` (create if missing) to keep a running journal of decisions. |

---

## 🔄 Auto-Update Policy
1. The AI is authorized to update this file when a new pattern is identified.
2. Notify the user: *"I've added `@new-command` to your memory."*
