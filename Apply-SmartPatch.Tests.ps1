BeforeAll {
    $scriptPath = "$PSScriptRoot/Apply-SmartPatch.ps1"
    
    # Create test directory
    $testDir = "$PSScriptRoot/../tmp/test-patches"
    if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force }
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
}

Describe "Apply-SmartPatch.ps1" {
    Context "Single Patch Object" {
        It "Should apply exact match patch successfully" {
            # Arrange
            $testFile = "$testDir/test1.txt"
            "Hello World" | Set-Content $testFile
            
            $patchFile = "$testDir/patch1.json"
            @{
                file    = $testFile
                search  = "Hello World"
                replace = "Goodbye World"
            } | ConvertTo-Json | Set-Content $patchFile
            
            # Act
            & $scriptPath -PatchFile $patchFile
            
            # Assert
            $content = Get-Content $testFile -Raw
            $content.Trim() | Should -Be "Goodbye World"
        }
        
        It "Should handle flexible whitespace matching" {
            # Arrange
            $testFile = "$testDir/test2.txt"
            "Hello    World" | Set-Content $testFile
            
            $patchFile = "$testDir/patch2.json"
            @{
                file    = $testFile
                search  = "Hello World"
                replace = "Goodbye World"
            } | ConvertTo-Json | Set-Content $patchFile
            
            # Act
            & $scriptPath -PatchFile $patchFile
            
            # Assert
            $content = Get-Content $testFile -Raw
            $content.Trim() | Should -Be "Goodbye World"
        }
        
        It "Should normalize line endings (CRLF to LF)" {
            # Arrange
            $testFile = "$testDir/test3.txt"
            "Line1`r`nLine2" | Set-Content $testFile -NoNewline
            
            $patchFile = "$testDir/patch3.json"
            @{
                file    = $testFile
                search  = "Line1`nLine2"
                replace = "NewLine1`nNewLine2"
            } | ConvertTo-Json | Set-Content $patchFile
            
            # Act
            & $scriptPath -PatchFile $patchFile
            
            # Assert
            $content = Get-Content $testFile -Raw
            $content | Should -Match "NewLine1"
            $content | Should -Match "NewLine2"
        }
        
        It "Should reject binary files" {
            # Arrange
            $testFile = "$testDir/test.png"
            "fake binary" | Set-Content $testFile
            
            $patchFile = "$testDir/patch-binary.json"
            @{
                file    = $testFile
                search  = "fake"
                replace = "real"
            } | ConvertTo-Json | Set-Content $patchFile
            
            # Act & Assert
            { & $scriptPath -PatchFile $patchFile } | Should -Throw "*binary*"
        }
    }
    
    Context "Multi-File Patch Array" {
        It "Should apply patches to multiple files" {
            # Arrange
            $testFile1 = "$testDir/multi1.txt"
            $testFile2 = "$testDir/multi2.txt"
            "File One" | Set-Content $testFile1
            "File Two" | Set-Content $testFile2
            
            $patchFile = "$testDir/patch-multi.json"
            @(
                @{
                    file    = $testFile1
                    search  = "File One"
                    replace = "Updated One"
                },
                @{
                    file    = $testFile2
                    search  = "File Two"
                    replace = "Updated Two"
                }
            ) | ConvertTo-Json | Set-Content $patchFile
            
            # Act
            & $scriptPath -PatchFile $patchFile
            
            # Assert
            (Get-Content $testFile1 -Raw).Trim() | Should -Be "Updated One"
            (Get-Content $testFile2 -Raw).Trim() | Should -Be "Updated Two"
        }
    }
    
    Context "Error Handling" {
        It "Should error if target file not found" {
            # Arrange
            $patchFile = "$testDir/patch-missing.json"
            @{
                file    = "$testDir/nonexistent.txt"
                search  = "test"
                replace = "fail"
            } | ConvertTo-Json | Set-Content $patchFile
            
            # Act & Assert
            { & $scriptPath -PatchFile $patchFile } | Should -Throw "*not found*"
        }
        
        It "Should error if search text not found" {
            # Arrange
            $testFile = "$testDir/test-nomatch.txt"
            "Hello World" | Set-Content $testFile
            
            $patchFile = "$testDir/patch-nomatch.json"
            @{
                file    = $testFile
                search  = "Nonexistent Text"
                replace = "Replacement"
            } | ConvertTo-Json | Set-Content $patchFile
            
            # Act & Assert
            { & $scriptPath -PatchFile $patchFile } | Should -Throw "*not found*"
        }
    }
}

AfterAll {
    # Cleanup
    if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force }
}
