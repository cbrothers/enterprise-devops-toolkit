BeforeAll {
    $scriptPath = "$PSScriptRoot/Bootstrap-AIWorkflow.ps1"
    $testProjectDir = "$PSScriptRoot/../tmp/test-bootstrap-project"
}

Describe "Bootstrap-AIWorkflow.ps1" {
    BeforeEach {
        # Create fresh test project directory
        if (Test-Path $testProjectDir) { Remove-Item $testProjectDir -Recurse -Force }
        New-Item -ItemType Directory -Path $testProjectDir -Force | Out-Null
        Push-Location $testProjectDir
        git init | Out-Null
    }
    
    AfterEach {
        Pop-Location
        if (Test-Path $testProjectDir) { Remove-Item $testProjectDir -Recurse -Force }
    }
    
    Context "Directory Structure Creation" {
        It "Should create .agent directory structure" {
            # Act
            & $scriptPath
            
            # Assert
            Test-Path "$testProjectDir/.agent" | Should -Be $true
            Test-Path "$testProjectDir/.agent/scripts" | Should -Be $true
            Test-Path "$testProjectDir/.agent/workflows" | Should -Be $true
            Test-Path "$testProjectDir/.agent/tmp" | Should -Be $true
        }
        
        It "Should copy Apply-SmartPatch.ps1" {
            # Act
            & $scriptPath
            
            # Assert
            Test-Path "$testProjectDir/.agent/scripts/Apply-SmartPatch.ps1" | Should -Be $true
        }
        
        It "Should create .gitattributes if not exists" {
            # Act
            & $scriptPath
            
            # Assert
            Test-Path "$testProjectDir/.gitattributes" | Should -Be $true
            $content = Get-Content "$testProjectDir/.gitattributes" -Raw
            $content | Should -Match "text eol=lf"
        }
    }
    
    Context "Git Configuration" {
        It "Should update .gitignore with .agent/tmp" {
            # Arrange
            ".agent/tmp" | Set-Content "$testProjectDir/.gitignore"
            
            # Act
            & $scriptPath
            
            # Assert
            $content = Get-Content "$testProjectDir/.gitignore" -Raw
            $content | Should -Match ".agent/tmp"
        }
    }
}
