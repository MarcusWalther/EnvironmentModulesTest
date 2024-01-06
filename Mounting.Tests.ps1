. "$PSScriptRoot/TestCommon.ps1"

Describe 'TestLoading' {

    BeforeEach {
        $env:PROGRAM_D_LOADED = $null
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Main module was loaded' {
        $loadedModules = Get-Module | Select-Object -Expand Name
        'EnvironmentModuleCore' | Should -BeIn $loadedModules
    }

    It 'Module should not exist twice' {
        $availableModules = Get-EnvironmentModule -ListAvailable -ModuleFullName "ProgramD-x64"
        $availableModules.Length | Should -Be 1
    }

    It 'Meta-Module is unloaded directly' {
        Import-EnvironmentModule 'ProgramD' -Silent
        $metaModule = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "ProgramD"
        $metaModule | Should -BeNullOrEmpty
    }

    It 'Module is loaded correctly' {
        Import-EnvironmentModule 'ProgramD' -Silent
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "ProgramD-x64"
        $module | Should -Not -BeNullOrEmpty
        $env:PROJECT_ROOT | Should -Be "C:\Temp"
    }

    It 'Dependency was loaded correctly' {
        Import-EnvironmentModule 'ProgramE' -Silent
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "ProgramD-x86"
        $module | Should -Not -BeNullOrEmpty
    }

    It 'Module can be removed with dependencies' {
        Import-EnvironmentModule 'ProgramD' -Silent
        Remove-EnvironmentModule 'ProgramD-x64'
        $module = Get-EnvironmentModule
        $module | Should -BeNullOrEmpty
    }

    It 'Project Module can be removed with dependencies' {
        Import-EnvironmentModule 'ProgramE' -Silent
        Remove-EnvironmentModule 'ProgramE-x64'
        $module = Get-EnvironmentModule
        $module | Should -BeNullOrEmpty
    }

    It 'Clear does work correctly' {
        Import-EnvironmentModule 'Project-ProgramA' -Silent
        Clear-EnvironmentModules -Force | Should -Be $null
    }

    It 'Module loaded events are triggered' {
        $env:PROGRAM_D_LOADED | Should -Be $null
        Import-EnvironmentModule 'ProgramD-x64' -Silent
        Wait-Event "OnLoaded" -Timeout 1
        $env:PROGRAM_D_LOADED | Should -Be "true"
        Remove-EnvironmentModule 'ProgramD-x64'
        Wait-Event "OnUnloaded" -Timeout 1
        $env:PROGRAM_D_LOADED | Should -Be "false"
    }
}

Describe 'Test_DefaultModuleCreation' {

    BeforeEach {
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Default Modules were created' {
        $availableModules = Get-EnvironmentModule -ListAvailable -ModuleFullName "ProgramD"
        $availableModules.Length | Should -Be 1
        $availableModules = Get-EnvironmentModule -ListAvailable -ModuleFullName "ProgramF-1"
        $availableModules.Length | Should -Be 1
        $availableModules = Get-EnvironmentModule -ListAvailable -ModuleFullName "ProgramF"
        $availableModules.Length | Should -Be 1
        $availableModules = Get-EnvironmentModule -ListAvailable -ModuleFullName "ProgramG"
        $availableModules.Length | Should -Be 1
        $availableModules = Get-EnvironmentModule -ListAvailable -ModuleFullName "ProgramG-1-x86"
        $availableModules.Length | Should -Be 1
        $availableModules = Get-EnvironmentModule -ListAvailable -ModuleFullName "ProgramG-1-x64"
        $availableModules.Length | Should -Be 1
    }

    It 'Default Modules loads the correct module' {
        Import-EnvironmentModule "ProgramG-1-x86" -Silent
        $loadedModules = Get-EnvironmentModule | Select-Object -Expand FullName
        "ProgramG-1.3_beta-x86" | Should -BeIn $loadedModules
    }

    It 'Default Modules loads the latest module' {
        Import-EnvironmentModule "ProgramZ" -Silent
        $loadedModules = Get-EnvironmentModule | Select-Object -Expand FullName
        "ProgramZ-3_10-x64" | Should -BeIn $loadedModules
    }

    It 'Abstract Default Module was not created' {
        $availableModules = Get-EnvironmentModule -ListAvailable -ModuleFullName "Abstract"
        $availableModules | Should -Be $null
    }

    It 'Meta Default Module was not created' {
        $availableModules = Get-EnvironmentModule -ListAvailable | Select-Object -Expand FullName
        'Project' | Should -Not -BeIn $availableModules
    }
}

Describe 'TestLoadingDescriptionFile' {
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Dependencies are loaded correctly' {
        Import-EnvironmentModuleDescriptionFile (Join-Path $PSScriptRoot (Join-Path "Descriptions" "Sample.pse1")) -Silent

        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "ProgramD-x64"
        $module | Should -Not -BeNullOrEmpty
    }

    It 'Parameters are set correctly' {
        Import-EnvironmentModuleDescriptionFile (Join-Path $PSScriptRoot (Join-Path "Descriptions" "Sample.pse1")) -Silent

        $paramter = (Get-EnvironmentModuleParameter "ProgramD.Parameter1").Value
        $paramter | Should -Be "SamplePse1Value"
    }
}


Describe 'TestLoading_ConflictingDependencies' {
    BeforeEach {
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Conflicting Dependencies are detected' {
        Import-EnvironmentModule 'ProgramD-x64' -Silent
        Import-EnvironmentModule 'ProgramE-x64' -Silent -ErrorAction SilentlyContinue

        $module = Get-EnvironmentModule 'ProgramE-x64'
        $module | Should -BeNullOrEmpty
    }
}

Describe 'TestLoading_CustomPath_Directory' {

    BeforeEach {
        Clear-EnvironmentModuleSearchPaths -Force
        $customDirectory = Join-Path $global:modulesRootFolder (Join-Path "Project" "Project-ProgramB")
        Add-EnvironmentModuleSearchPath "Project-ProgramB" "Directory" $customDirectory
        (Get-EnvironmentModuleSearchPath "Project-ProgramB" -Custom).Length | Should -BeExactly 1
        (Get-EnvironmentModuleSearchPath "Project-ProgramB").Length | Should -BeExactly 2
        Import-EnvironmentModule "Project-ProgramB" -Silent
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Module is loaded correctly' {
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "Project-ProgramB"
        $module | Should -Not -BeNullOrEmpty
        $module.ModuleRoot | Should -Not -BeNullOrEmpty
    }
}

Describe 'TestLoading_CustomPath_Directory_Temp' {

    BeforeEach {
        Clear-EnvironmentModuleSearchPaths -Force
        $customDirectory = Join-Path $global:modulesRootFolder (Join-Path "Project" "Project-ProgramB")
        Add-EnvironmentModuleSearchPath "Project-ProgramB" "Directory" $customDirectory -IsTemporary
        Add-EnvironmentModuleSearchPath "Project-ProgramB" "Directory" "SomeStupidLocation"
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Module is loaded correctly' {
        Import-EnvironmentModule "Project-ProgramB" -Silent
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "Project-ProgramB"
        $module | Should -Not -BeNullOrEmpty
        $module.ModuleRoot | Should -Not -BeNullOrEmpty
    }

    It 'Module could not be loaded' {
        Clear-EnvironmentModuleSearchPaths -Force -OnlyTemporary
        Import-EnvironmentModule "Project-ProgramB" -Silent
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "Project-ProgramB"
        $module | Should -BeNullOrEmpty
    }
}

Describe 'TestLoading_CustomPath_Directory_Global' {
    BeforeEach {
        $customDirectory = Join-Path $global:modulesRootFolder (Join-Path "Project" "Project-ProgramB")
        Clear-EnvironmentModuleSearchPaths -IncludeGlobal -Force
        Add-EnvironmentModuleSearchPath "Project-ProgramB" "Directory" $customDirectory -IsGlobal
        Add-EnvironmentModuleSearchPath "Project-ProgramB" "Directory" "SomeStupidLocation"
    }
    AfterEach {
        Clear-EnvironmentModuleSearchPaths -IncludeGlobal -Force
        Clear-EnvironmentModules -Force
    }

    It 'Module is loaded correctly' {
        Import-EnvironmentModule "Project-ProgramB" -Silent
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "Project-ProgramB"
        $module | Should -Not -BeNullOrEmpty
        $module.ModuleRoot | Should -Not -BeNullOrEmpty
    }

    It 'Module could not be loaded' {
        Clear-EnvironmentModuleSearchPaths -Force -IncludeGlobal
        Import-EnvironmentModule "Project-ProgramB" -Silent
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "Project-ProgramB"
        $module | Should -BeNullOrEmpty
    }
}

Describe 'TestLoading_CustomPath_Environment' {

    BeforeEach {
        Clear-EnvironmentModuleSearchPaths -Force
        $customDirectory = Join-Path $global:modulesRootFolder (Join-Path "Project" "Project-ProgramB")
        $env:TESTLOADING_PATH = "$customDirectory"
        Add-EnvironmentModuleSearchPath -ModuleFullName "Project-ProgramB" -Type "ENVIRONMENT_VARIABLE" -Key "TESTLOADING_PATH"
        Add-EnvironmentModuleSearchPath -ModuleFullName "Project-ProgramB" -Type "ENVIRONMENT_VARIABLE" -Key "UNDEFINED_VARIABLE"
        Import-EnvironmentModule "Project-ProgramB" -Silent
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Module is loaded correctly' {
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "Project-ProgramB"
        $module | Should -Not -BeNullOrEmpty
    }

    It 'SearchPath correctly returned' {
        $searchPaths = Get-EnvironmentModuleSearchPath "Project-ProgramB"
        $searchPaths.Count | Should -Be 3
        $searchPaths[0].Key | Should -Be "TESTLOADING_PATH"
    }

    It 'Remove Search Path works correctly' {
        Remove-EnvironmentModuleSearchPath -ModuleFullName "Project-ProgramB" -Key "UNDEFINED_VARIABLE" -Force
        $searchPaths = Get-EnvironmentModuleSearchPath "Project-ProgramB"
        $searchPaths.Count | Should -Be 2
    }
}

Describe 'TestLoading_Environment_Subpath' {
    BeforeEach {
        Clear-EnvironmentModuleSearchPaths -Force
        $customDirectory = Join-Path $global:modulesRootFolder (Join-Path "Project" "Project-ProgramC")
        $env:PROJECT_PROGRAM_C_ROOT = "$customDirectory"
        Import-EnvironmentModule "Project-ProgramC" -Silent
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Module is loaded correctly with sub-path' {
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "Project-ProgramC"
        $module | Should -Not -BeNullOrEmpty
    }
}

Describe 'TestLoading_InvalidCustomPath' {
    BeforeEach {
        Clear-EnvironmentModuleSearchPaths -Force
        $customDirectory = Join-Path $global:modulesRootFolder (Join-Path "Project" "Project-ProgramB_")
        Add-EnvironmentModuleSearchPath -ModuleFullName "Project-ProgramB" -Type "Directory" -Key $customDirectory
        Import-EnvironmentModule "Project-ProgramB" -Silent
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Module should not be loaded because of invalid root path' {
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "Project-ProgramB"
        $module | Should -BeNullOrEmpty
    }
}

Describe 'TestLoading_AbstractModule' {
    BeforeEach {
        Import-EnvironmentModule "Project-ProgramA" -Silent
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Modules was not loaded' {
        Clear-EnvironmentModules -Force
        try {
            Import-EnvironmentModule 'Abstract_Project' -Silent
        }
        catch {
        }
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -like "Abstract_Project"
        $module | Should -BeNullOrEmpty
    }

    It 'Module is loaded correctly' {
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "Project-ProgramA"
        $module | Should -Not -BeNullOrEmpty
    }

    It 'Abstract Module is loaded correctly' {
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "Abstract_Project"
        $module | Should -Not -BeNullOrEmpty
    }

    It 'Abstract Module Functions are available' {
        $result = Get-ProjectRoot  # Call function of abstract module
        $result | Should -BeExactly "C:\Temp"
    }

    It 'Abstract Module has correct source module' {
        $result = Get-SourceModule
        $result.FullName | Should -BeExactly "Project-ProgramA"
    }
}

Describe 'TestSwitch' {
    BeforeEach {
        Import-EnvironmentModule 'Project-ProgramA' -Silent
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Modules were loaded correctly' {
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -like "ProgramD-x64"
        $module | Should -Not -BeNullOrEmpty
    }

    It 'Switch module works' {
        Switch-EnvironmentModule 'ProgramD-x64' 'ProgramD-x86'
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -like "ProgramD-x64"
        $module | Should -BeNullOrEmpty

        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -like "ProgramD-x86"
        $module | Should -Not -BeNullOrEmpty
    }

    It 'Switch module works keeps user defined parameters' {
        Set-EnvironmentModuleParameter "ProgramD.Parameter1" "NewValue1"
        Set-EnvironmentModuleParameter "ProgramD.Parameter2" "NewValue2"
        Switch-EnvironmentModule 'ProgramD-x64' 'ProgramD-x86'
        Get-EnvironmentModuleParameter "ProgramD.Parameter1" | Should -BeNullOrEmpty
        (Get-EnvironmentModuleParameter "ProgramD.Parameter2").Value | Should -BeExactly "NewValue2"
    }

    It 'Meta function works' {
        $result = Start-Cmd 42
        $result | Should -BeExactly 42
    }
}

Describe 'TestMergeModules' {
    BeforeEach {
        Push-Location
        $customDirectory = Join-Path $global:modulesRootFolder (Join-Path "Program" "ProgramMerge")
        $env:PROGRAM_MERGE_ROOT = "$customDirectory"

        Import-EnvironmentModule 'ProgramMerge' -Silent
    }
    AfterEach {
        Clear-EnvironmentModules -Force
        Pop-Location
    }

    It 'Module merge works correctly' {
        $modules = Get-EnvironmentModule
        $modules.Count | Should -BeExactly 4
    }
}

Describe 'TestSwitchDirectoryToModuleRoot' {
    $rootDirectory = $null
    BeforeEach {
        Push-Location
        $rootDirectory = Join-Path $global:modulesRootFolder (Join-Path "Program" "ProgramMerge")
        $env:PROGRAM_MERGE_ROOT = "$rootDirectory"

        Import-EnvironmentModule 'ProgramMerge' -Silent
    }
    AfterEach {
        Clear-EnvironmentModules -Force
        Pop-Location
    }

    It 'Directory was switched correctly' {
        Get-Location | Should -Be (Join-Path "$rootDirectory" "TestData")
    }
}