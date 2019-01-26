if($null -eq (Get-Module -Name "Pester")) {
    Import-Module Pester
}

# The directories and scripts to use
$modulesRootFolder = Join-Path $PSScriptRoot "Modules"

$additionalModulePaths = [string]::Join([IO.Path]::PathSeparator, (Get-ChildItem -Directory $modulesRootFolder))

$tempDirectory = Join-Path $PSScriptRoot "Tmp"
$configDirectory = Join-Path $PSScriptRoot "Config"
$startEnvironmentScript = Join-Path $env:ENVIRONMENT_MODULE_ROOT (Join-Path "Samples" "StartSampleEnvironment.ps1")

# Prepare the environment
. $startEnvironmentScript -AdditionalModulePaths $additionalModulePaths -TempDirectory $tempDirectory -ConfigDirectory $configDirectory -IgnoreSamplesFolder
Set-EnvironmentModuleConfigurationValue -ParameterName "DefaultModuleStoragePath" -Value $modulesRootFolder

Describe 'TestLoading' {

    BeforeEach {
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Main module was loaded' {
        $loadedModules = Get-Module | Select-Object -Expand Name
        'EnvironmentModules' | Should -BeIn $loadedModules
    }

    It 'Default Modules were created' {
        $availableModules = Get-EnvironmentModule -ListAvailable -ModuleFullName "ProgramD"
        $availableModules.Length | Should -Be 1
    }

    It 'Abstract Default Module was not created' {
        $availableModules = Get-EnvironmentModule -ListAvailable -ModuleFullName "Abstract"
        $availableModules | Should -Be $null
    }

    It 'Meta Default Module was not created' {
        $availableModules = Get-EnvironmentModule -ListAvailable | Select-Object -Expand FullName
        'Project' | Should -Not -BeIn $availableModules
    }

    It 'Module should not exist twice' {
        $availableModules = Get-EnvironmentModule -ListAvailable -ModuleFullName "ProgramD-x64"
        $availableModules.Length | Should -Be 1
    }

    It 'Meta-Module is unloaded directly' {
        Import-EnvironmentModule 'ProgramD'
        $metaModule = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "ProgramD"
        $metaModule | Should -BeNullOrEmpty
    }

    It 'Module is loaded correctly' {
        Import-EnvironmentModule 'ProgramD'
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "ProgramD-x64"
        $module | Should -Not -BeNullOrEmpty
    }

    It 'Dependency was loaded correctly' {
        Import-EnvironmentModule 'ProgramE'
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "ProgramD-x64"
        $module | Should -Not -BeNullOrEmpty
    }

    It 'Module can be removed with dependencies' {
        Import-EnvironmentModule 'ProgramD'
        Remove-EnvironmentModule 'ProgramD-x64'
        $module = Get-EnvironmentModule
        $module | Should -BeNullOrEmpty
    }

    It 'Project Module can be removed with dependencies' {
        Import-EnvironmentModule 'ProgramE'
        Remove-EnvironmentModule 'ProgramE-x64'
        $module = Get-EnvironmentModule
        $module | Should -BeNullOrEmpty
    }
}

Describe 'TestLoading_CustomPath_Directory' {

    BeforeEach {
        Clear-EnvironmentModuleSearchPaths -Force
        $customDirectory = Join-Path $modulesRootFolder (Join-Path "Project" "Project-ProgramB")
        Add-EnvironmentModuleSearchPath "Project-ProgramB" "Directory" $customDirectory
        Import-EnvironmentModule "Project-ProgramB"
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Module is loaded correctly' {
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "Project-ProgramB"
        $module | Should -Not -BeNullOrEmpty
    }
}

Describe 'TestLoading_CustomPath_Environment' {

    BeforeEach {
        Clear-EnvironmentModuleSearchPaths -Force
        $customDirectory = Join-Path $modulesRootFolder (Join-Path "Project" "Project-ProgramB")
        $env:TESTLADOING_PATH = "$customDirectory"
        Add-EnvironmentModuleSearchPath -ModuleFullName "Project-ProgramB" -Type "Environment" -Key "TESTLADOING_PATH"
        Add-EnvironmentModuleSearchPath -ModuleFullName "Project-ProgramB" -Type "Environment" -Key "UNDEFINED_VARIABLE"
        Import-EnvironmentModule "Project-ProgramB"
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
        $searchPaths.Count | Should -Be 2
        $searchPaths[0].Key | Should -Be "TESTLADOING_PATH"
    }

    It 'Remove Search Path works correctly' {
        Remove-EnvironmentModuleSearchPath -ModuleFullName "Project-ProgramB" -Key "UNDEFINED_VARIABLE"
        $searchPaths = Get-EnvironmentModuleSearchPath "Project-ProgramB"
        $searchPaths.Count | Should -Be 1
    }
}

Describe 'TestLoading_Environment_Subpath' {
    BeforeEach {
        Clear-EnvironmentModuleSearchPaths -Force
        $customDirectory = Join-Path $modulesRootFolder (Join-Path "Project" "Project-ProgramC")
        $env:PROJECT_PROGRAM_C_ROOT = "$customDirectory"
        Import-EnvironmentModule "Project-ProgramC"
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
        $customDirectory = Join-Path $modulesRootFolder (Join-Path "Project" "Project-ProgramB_")
        Add-EnvironmentModuleSearchPath -ModuleFullName "Project-ProgramB" -Type "Directory" -Key $customDirectory
        Import-EnvironmentModule "Project-ProgramB"
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
        Import-EnvironmentModule "Project-ProgramA"
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Modules was not loaded' {
        Clear-EnvironmentModules -Force
        try {
            Import-EnvironmentModule 'Abstract-Project'
        }
        catch {
        }
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -like "Abstract-Project"
        $module | Should -BeNullOrEmpty
    }

    It 'Module is loaded correctly' {
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "Project-ProgramA"
        $module | Should -Not -BeNullOrEmpty
    }

    It 'Abstract Module is loaded correctly' {
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "Abstract-Project"
        $module | Should -Not -BeNullOrEmpty
    }

    It 'Abstract Module Functions are available' {
        $result = Get-ProjectRoot  # Call function of abstract module
        $result | Should -BeExactly "C:\Temp"
    }
}

Describe 'TestCopy' {
    BeforeEach {
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Modules was correctly copied and deleted afterwards' {
        $module = Get-EnvironmentModule -ListAvailable "Project-ProgramA"
        $module | Should -Not -BeNullOrEmpty
        Copy-EnvironmentModule Project-ProgramA "Project-ProgramACopy"
        $newModule = Get-EnvironmentModule -ListAvailable "Project-ProgramACopy"
        $newModule | Should -Not -BeNullOrEmpty

        $files = Get-ChildItem "$($newModule.ModuleBase)" | Select-Object -ExpandProperty "Name"
        $files | Should -Contain "ProjectRelevantFile.txt"

        Remove-EnvironmentModule -Delete -Force "Project-ProgramACopy"

        $newModule = Get-EnvironmentModule -ListAvailable "Project-ProgramACopy"
        $newModule | Should -BeNullOrEmpty
    }
}

Describe 'TestSwitch' {
    BeforeEach {
        Import-EnvironmentModule 'Project-ProgramA'
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

    It 'Meta function works' {
        $result = Start-Cmd 42
        $result | Should -BeExactly 42
    }
}

Describe 'TestGet' {
    BeforeEach {
        Import-EnvironmentModule 'Project-ProgramA'
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Correct style version is returned' {
        $module = Get-EnvironmentModule -ModuleFullName "Project-ProgramA"
        ($module.StyleVersion) | Should -Be 2.1
    }
}

Describe 'TestCircularDependencies' {
    BeforeEach {
        Import-EnvironmentModule 'DependencyBase'
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Module was not loaded' {
        try {
            $modules = Get-EnvironmentModule -ModuleFullName "Dependency*"
        }
        catch {
        }

        $modules | Should -BeNullOrEmpty
    }
}

Describe 'TestAlias' {
    BeforeEach {
        Import-EnvironmentModule 'ProgramD-x64'
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Alias ppp is loaded correctly' {
        $aliasInfos = Get-EnvironmentModuleAlias -ModuleFullName "ProgramD*"
        $aliasInfos.Length | Should -Be 1
        $aliasInfos[0].Name | Should -Be "ppp"
    }
}

Describe 'TestFunctionStack' {
    BeforeEach {
        Import-EnvironmentModule 'Project-ProgramA'
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Function Stack has correct structure' {
        $knownFunctions = Get-EnvironmentModuleFunction -FunctionName "Start-Cmd"
        $knownFunctions | Should -HaveCount 2

        $knownFunctions[0].ModuleFullName | Should -Be "ProgramD-x64"
        $knownFunctions[1].ModuleFullName | Should -Be "Project-ProgramA"
    }

    It 'Function Stack invoke does work correctly' {
        $result = Invoke-EnvironmentModuleFunction "Start-Cmd" "Project-ProgramA" -ArgumentList "42"
        $result | Should -Be 42

        $result = Start-Cmd "42"
        $result | Should -Be 42

        $result = Invoke-EnvironmentModuleFunction "Start-Cmd" "ProgramD-x64" -ArgumentList '/C "echo 45"'
        $result | Should -Be @('/C "echo 45"', "something")
    }

    It 'Function Stack cleaned correctly' {
        Remove-EnvironmentModule 'Project-ProgramA'
        $knownFunctions = Get-EnvironmentModuleFunction -FunctionName "Start-Cmd"
        $knownFunctions | Should -HaveCount 0
    }
}

Describe 'TestNuget' {
    BeforeEach {
        Publish-EnvironmentModuleNuget -ModuleFullName 'Abstract-Project'
    }
    AfterEach {
        Clear-EnvironmentModules -Force
        $modulesToClear = @('Project-ProgramA', 'ProgramD-x64', 'ProgramD', 'Abstract-Project')

        foreach($module in $modulesToClear) {
            $moduleBase = (Get-EnvironmentModule -ListAvailable -ModuleFullName $module).ModuleBase.FullName
            Remove-Item (Join-Path $moduleBase "*.nuspec")
            Remove-Item -Recurse (Join-Path $moduleBase "package") -ErrorAction SilentlyContinue
            Remove-EnvironmentModuleNuget $module -Force
        }
    }

    It 'Nuget push does work' {
        $moduleBase = (Get-EnvironmentModule -ListAvailable -ModuleFullName "Abstract-Project").ModuleBase.FullName
        $nuspecItems = Get-ChildItem (Join-Path $moduleBase "*.nuspec")
        $nuspecItems.Count | Should -Be 1
        $packageFile = Get-ChildItem (Join-Path $moduleBase (Join-Path "package" "*.nupkg"))
        $packageFile.Count | Should -Be 1
        (Find-EnvironmentModuleNuget "*") | Select-Object -ExpandProperty "Name" | Should -Contain "Abstract-Project"
    }

    It 'Nuget push with unresolved dependencies should fail' {
        Publish-EnvironmentModuleNuget -ModuleFullName 'Project-ProgramA'
        (Find-EnvironmentModuleNuget "*") | Select-Object -ExpandProperty "Name" | Should -Not -Contain "Project-ProgramA"
    }

    It 'Nuget push with resolved dependencies should work' {
        Publish-EnvironmentModuleNuget -ModuleFullName 'ProgramD-x64'
        (Find-EnvironmentModuleNuget "*") | Select-Object -ExpandProperty "Name" | Should -Contain "ProgramD-x64"
        Publish-EnvironmentModuleNuget -ModuleFullName 'Project-ProgramA'
        (Find-EnvironmentModuleNuget "*") | Select-Object -ExpandProperty "Name" | Should -Contain "Project-ProgramA"
    }

    It 'Nuget push with tmp module should fail' {
        Publish-EnvironmentModuleNuget -ModuleFullName 'ProgramD'
        (Find-EnvironmentModuleNuget "*") | Select-Object -ExpandProperty "Name" | Should -Not -Contain "ProgramD"
    }
}