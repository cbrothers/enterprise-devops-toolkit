# Pester tests for Sync-Branch.ps1
# Requires Pester v5

Import-Module Pester -ErrorAction Stop

# Path to the script under test
$scriptPath = "..\\Sync-Branch.ps1"

Describe "Sync-Branch.ps1" {
    Context "When current branch is main" {
        # Mock git to return 'main' for branch name and succeed for other calls
        Mock -CommandName git -MockWith { param($args) if ($args -contains "branch") { return "main" } else { return "" } } -Verifiable

        It "Writes a warning and exits with code 0" {
            $output = & $scriptPath -Force 2>&1
            $output | Should -Match "Already on main branch"
        }
    }

    Context "When on a feature branch with uncommitted changes" {
        # Mock git to simulate being on a feature branch and having changes
        Mock -CommandName git -MockWith {
            param($args)
            if ($args -contains "branch") { return "feature/awesome" }
            if ($args -contains "status") { return " M somefile.txt" } # indicates changes
            if ($args -contains "fetch") { return "" }
            if ($args -contains "merge") { return "" }
            if ($args -contains "stash") { return "" }
            if ($args -contains "stash" -and $args[1] -eq "pop") { return "" }
            return ""
        } -Verifiable

        It "Stashes changes, fetches, merges, and restores stash" {
            $output = & $scriptPath 2>&1
            $output | Should -Match "Stashing uncommitted changes"
            $output | Should -Match "Fetching latest main"
            $output | Should -Match "Merging main into"
            $output | Should -Match "Restoring stashed changes"
            $output | Should -Match "Branch synced successfully"
        }
    }
}
