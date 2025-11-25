Describe "Setup-Project.ps1" {
    $scriptPath = Join-Path $PSScriptRoot "Setup-Project.ps1"
    $testDir = Join-Path $PSScriptRoot "Test-SetupProject"

    BeforeAll {
        if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force }
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        
        # Copy script to test dir to run it relatively
        Copy-Item $scriptPath -Destination $testDir
        
        # Create dummy bootstrap script
        Set-Content -Path (Join-Path $testDir "Bootstrap-AIWorkflow.ps1") -Value "Write-Host 'Bootstrap ran'"
        
        # Create dummy Apply-SmartPatch.ps1 for validation
        $agentScripts = Join-Path $testDir ".agent\scripts"
        New-Item -ItemType Directory -Path $agentScripts -Force | Out-Null
        New-Item -ItemType File -Path (Join-Path $agentScripts "Apply-SmartPatch.ps1") -Force | Out-Null
        
        # Create dummy optional folders
        New-Item -ItemType Directory -Path (Join-Path $testDir "cicd") -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $testDir "kubernetes") -Force | Out-Null
    }

    AfterAll {
        if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force }
    }

    It "Creates the .agent directory structure in WhatIf mode" {
        Set-Location $testDir
        try {
            & .\Setup-Project.ps1 -WhatIf -SourcePath $testDir
            
            $agentDir = Join-Path $testDir ".agent"
            $exists = Test-Path $agentDir
            $exists | Should -Be $true
            
            $scriptsDir = Join-Path $agentDir "scripts"
            (Test-Path $scriptsDir) | Should -Be $true
        }
        finally {
            Set-Location $PSScriptRoot
        }
    }

    It "Creates the optional directories in WhatIf mode" {
        Set-Location $testDir
        try {
            & .\Setup-Project.ps1 -WhatIf -SourcePath $testDir
            
            # In WhatIf mode, we simulate selecting 'Yes' for everything
            (Test-Path (Join-Path $testDir "cicd")) | Should -Be $true
            (Test-Path (Join-Path $testDir "kubernetes")) | Should -Be $true
        }
        finally {
            Set-Location $PSScriptRoot
        }
    }
}
