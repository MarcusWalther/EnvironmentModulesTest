if($null -eq (Get-Module -Name "Pester")) {
    Import-Module Pester
}

# The directories and scripts to use
$global:modulesRootFolder = Join-Path $PSScriptRoot "Modules"
Write-Host "Using root folder $global:modulesRootFolder"

$additionalModulePaths = [string]::Join([IO.Path]::PathSeparator, (Get-ChildItem -Directory $global:modulesRootFolder | Select-Object -ExpandProperty "FullName"))

$global:tempDirectory = Join-Path $PSScriptRoot "Tmp"
$configDirectory = Join-Path $PSScriptRoot "Config"
$startEnvironmentScript = Join-Path ((Get-Module "EnvironmentModuleCore").ModuleBase) (Join-Path "Samples" "StartSampleEnvironment.ps1")

# Prepare the environment
. $startEnvironmentScript -AdditionalModulePaths $additionalModulePaths -TempDirectory $global:tempDirectory -ConfigDirectory $configDirectory -IgnoreSamplesFolder
Set-EnvironmentModuleConfigurationValue -ParameterName "DefaultModuleStoragePath" -Value $global:modulesRootFolder

Update-EnvironmentModuleCache

Describe 'TestLoading' {

    BeforeEach {
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

    It 'Default Modules loads the lates module' {
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

Describe 'Test_SplitEnvironmentModuleName' {
    It 'Simple names correct detected' {
        $result = Split-EnvironmentModuleName "ProgramXYZ" -Silent
        $result.Name | Should -Be "ProgramXYZ"
        $result.Version | Should -BeNullOrEmpty
        $result.Architecture | Should -BeNullOrEmpty
        $result.AdditionalOptions | Should -BeNullOrEmpty
    }

    It 'Invalid names correct detected' {
        $result = Split-EnvironmentModuleName "Program.Abstract" -Silent
        $result | Should -BeNullOrEmpty
        $result = Split-EnvironmentModuleName "Program Abstract" -Silent
        $result | Should -BeNullOrEmpty
    }

    It 'Version correct detected' {
        $result = Split-EnvironmentModuleName "ProgramXYZ-1.0.2.4" -Silent
        $result.Name | Should -Be "ProgramXYZ"
        $result.Version | Should -Be "1.0.2.4"
        $result.Architecture | Should -BeNullOrEmpty
        $result.AdditionalOptions | Should -BeNullOrEmpty
    }

    It 'Invalid version correct detected' {
        $result = Split-EnvironmentModuleName "ProgramXYZ-1.0-2.4-x64" -Silent
        $result | Should -BeNullOrEmpty
        $result = Split-EnvironmentModuleName "ProgramXYZ-1Beta0-2.4-x86" -Silent
        $result | Should -BeNullOrEmpty
    }

    It 'Architecture correct detected' {
        $result = Split-EnvironmentModuleName "ProgramXYZ-x64" -Silent
        $result.Architecture | Should -Be "x64"
        $result = Split-EnvironmentModuleName "ProgramXYZ-1.0.dev-x86" -Silent
        $result.Version | Should -Be "1.0.dev"
        $result.Architecture | Should -Be "x86"
    }

    It 'Additional options correct detected' {
        $result = Split-EnvironmentModuleName "ProgramXYZ-x64-ForTesting" -Silent
        $result.Architecture | Should -Be "x64"
        $result.AdditionalOptions | Should -Be "ForTesting"
        $result = Split-EnvironmentModuleName "ProgramXYZ-1.0.dev-x86-ForTesting" -Silent
        $result.Version | Should -Be "1.0.dev"
        $result.Architecture | Should -Be "x86"
        $result.AdditionalOptions | Should -Be "ForTesting"
    }
}

Describe 'Test_SortEnvironmentModules' {
    It 'Sort Modules By Version' {
        $modules = Get-EnvironmentModule -ListAvailable "ProgramZ*" -SkipMetaModules
        $modules.Length | Should -Be 4
        $modules = Compare-EnvironmentModulesByVersion $modules
        $modules.Length | Should -Be 4
        $modules[0].Version | Should -Be "3_11"
        $modules[3].Version | Should -Be "3_6"
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

Describe 'TestGet' {
    BeforeEach {
        Import-EnvironmentModule 'Project-ProgramA' -Silent
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Correct style version is returned' {
        $module = Get-EnvironmentModule -ModuleFullName "Project-ProgramA"
        ($module.StyleVersion) | Should -Be 3.0
    }
}

Describe 'TestCircularDependencies' {
    BeforeEach {
        Import-EnvironmentModule 'DependencyBase' -Silent -ErrorAction SilentlyContinue
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
        Import-EnvironmentModule 'ProgramD-x64' -Silent
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Alias ppp is loaded correctly' {
        $aliasInfos = Get-EnvironmentModuleAlias -ModuleFullName "ProgramD*"
        $aliasInfos.Length | Should -Be 1
        $aliasInfos[0].Name | Should -Be "ppp"
        $aliasInfos[0].Description | Should -Be "Use 'ppp' to start ProgramD"
    }
}

Describe 'TestFunctionStack' {
    BeforeEach {
        Import-EnvironmentModule 'Project-ProgramA' -Silent
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Function Stack has correct structure' {
        $knownFunctions = Get-EnvironmentModuleFunction -FunctionName "Start-Cmd"
        $knownFunctions | Should -HaveCount 2

        $knownFunctions[0].ModuleFullName | Should -Be "Project-ProgramA"
        $knownFunctions[1].ModuleFullName | Should -Be "ProgramD-x64"
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

Describe 'TestParameters' {
    BeforeEach {
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Default Parameters are loaded correctly' {
        Import-EnvironmentModule 'ProgramE-x64' -Silent
        (Get-EnvironmentModuleParameter "ProgramE.Parameter1").Value | Should -Be "Default"
        (Get-EnvironmentModuleParameter "ProgramE.Parameter2").Value | Should -Be "Default"
        (Get-EnvironmentModuleParameter "ProgramE.Parameter3").Value | Should -Be "MyValue"
        (Get-EnvironmentModuleParameter "*" -UserDefined) | Should -Be $null
    }

    It 'User defined attributes are detected correctly' {
        Import-EnvironmentModule 'ProgramE-x64' -Silent
        (Set-EnvironmentModuleParameter "ProgramE.Parameter3" "CustomValue")
        (Get-EnvironmentModuleParameter "ProgramE.Parameter3" -UserDefined).Value | Should -Be "CustomValue"
    }

    It 'Komplex parameter syntax is handled correctly' {
        Import-EnvironmentModule "ProgramF-1.0.3" -Silent
        (Get-EnvironmentModuleParameter "ProgramF.Parameter1" -UserDefined).Value | Should -BeExactly "NewValue"
        (Get-EnvironmentModuleParameter "ProgramF.Parameter1").IsUserDefined | Should -BeExactly $true
        (Get-EnvironmentModuleParameter "ProgramF.Parameter2").Value | Should -BeExactly "Blubb"
        (Get-EnvironmentModuleParameter "ProgramF.Parameter2").IsUserDefined | Should -BeExactly $false
    }

    It 'Parameter can be accessed correctly' {
        Import-EnvironmentModule 'ProgramE-x64' -Silent
        Get-EnvironmentModuleParameter "*" | Select-Object -ExpandProperty "Name" | Should -Contain "ProgramE.Parameter1"
    }

    It 'Parameters are overwritten correctly' {
        Import-EnvironmentModule 'Project-ProgramA' -Silent
        (Get-EnvironmentModuleParameter "ProgramD.Parameter1").Value | Should -Be "ProjectValue"
    }

    It 'Modules can access the Parameters' {
        Import-EnvironmentModule 'Project-ProgramA' -Silent
        Get-ProjectValue | Should -Be "ProjectValue"
    }

    It 'Module has a valid temp directory' {
        Import-EnvironmentModule 'Project-ProgramA' -Silent
        $loadedModules = Get-EnvironmentModule
        $loadedModules | ForEach-Object { (Test-Path $_.TmpDirectory) | Should -Be $True }
    }
}

Describe 'TestParameterEnvironments' {
    BeforeEach {
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Default Parameters are loaded correctly' {
        Import-EnvironmentModule 'ProgramE-x64' -Silent
        (Get-EnvironmentModuleParameter "ProgramE.Parameter1").Value | Should -Be "Default"
        Get-VirtualParameterEnvironments | Should -Be @("Default", "V2")
        Enable-VirtualParameterEnvironment "V2"
        (Get-EnvironmentModuleParameter "ProgramE.Parameter1").Value | Should -Be "DefaultV2"
    }

    It 'Virtual Environment Parameters are set correctly' {
        Import-EnvironmentModule 'ProgramE-x64' -Silent
        Enable-VirtualParameterEnvironment "V2"
        Set-EnvironmentModuleParameter "ProgramE.Parameter1" "NewValueV2"
        (Get-EnvironmentModuleParameter "ProgramE.Parameter1").Value | Should -Be "NewValueV2"
    }

    It 'Parameters are removed correctly' {
        Import-EnvironmentModule 'ProgramE-x64' -Silent
        Enable-VirtualParameterEnvironment "V2"
        Set-EnvironmentModuleParameter "ProgramE.Parameter1" "NewValueV2"
        Remove-EnvironmentModule 'ProgramE-x64'
        (Get-EnvironmentModuleParameter "ProgramE.*") | Should -BeNullOrEmpty
    }
}

Describe 'TestTemplateRenderer' {
    BeforeEach {
        Import-EnvironmentModule "Project-ProgramA" -Silent
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Template Rendering Works' {
        $fileContent = Get-Content (Render-TemplateFile)
        $fileContent | Should -Be "Hello=World"
    }
}

Describe 'TestModuleCreation' {    
    BeforeEach {
        $moduleDirectory = "$global:tempDirectory/TestModule-4.5-x86"
        if(Test-Path $moduleDirectory) {
            Remove-Item -Recurse $moduleDirectory
        }
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Module Creation in tmp fails' {
        {New-EnvironmentModule -Name "TestModule" -Author "Max Mustermann" -Description "My Test Module" -Version "4.5" -Architecture "x86" -RequiredFiles "temp.exe" -SearchPaths "C:\temp" -Path "$global:tempDirectory"} | Should -Throw
    }

    It 'Module Creation' {
        New-EnvironmentModule -Name "TestModule" -Author "Max Mustermann" -Description "My Test Module" -Version "4.5" -Architecture "x86" -RequiredFiles "temp.exe" -SearchPaths "C:\temp" -Path "$global:tempDirectory" -Dependencies "ModuleDependency" -Parameters @{"Param1"="Param1Value"} -Force
        $moduleInfo = New-EnvironmentModuleInfo -ModuleFile "$moduleDirectory/TestModule-4.5-x86.psd1"
        $moduleInfo.Dependencies[0].ModuleFullName | Should -BeExactly "ModuleDependency"
        $moduleInfo.Dependencies.Length | Should -BeExactly 1
        $moduleInfo.Architecture | Should -BeExactly "x86"
        $moduleInfo.Parameters[[System.Tuple[string, string]]::new("Param1", "Default")].Value | Should -BeExactly "Param1Value"
        $moduleInfo.Parameters.Length | Should -BeExactly 1
    }
}

Describe 'TestPathManipulation' {
    BeforeEach {
        $env:ENV_TEST_PATH = [String]::Join([IO.Path]::PathSeparator, @("A", "B", "C"))
        $env:ENV_TEST_PATH2 = $env:ENV_TEST_PATH
        $env:ENV_TEST_PATH3 = $env:ENV_TEST_PATH
        $env:ENV_TEST_PATH4 = $env:ENV_TEST_PATH
        Import-EnvironmentModule "ProgramH" -Silent
    }
    AfterEach {
        Remove-EnvironmentModule "ProgramH"
        $env:ENV_TEST_PATH = ""
        $env:ENV_TEST_PATH2 = $env:ENV_TEST_PATH
        $env:ENV_TEST_PATH3 = $env:ENV_TEST_PATH
        $env:ENV_TEST_PATH4 = $env:ENV_TEST_PATH
        $env:ENV_TEST_PATH5 = $env:ENV_TEST_PATH
    }

    It 'Simple Path Append is removed correctly' {
        Remove-EnvironmentModule "ProgramH"
        $env:ENV_TEST_PATH3 | Should -BeExactly ([String]::Join([IO.Path]::PathSeparator, @("A", "B", "C")))
    }

    It 'Complex Path Append is removed correctly' {
        Remove-EnvironmentModule "ProgramH"
        $env:ENV_TEST_PATH2 | Should -BeExactly ([String]::Join([IO.Path]::PathSeparator, @("A", "B", "C")))
    }

    It 'Complex Path Prepend is removed correctly' {
        Remove-EnvironmentModule "ProgramH"
        $env:ENV_TEST_PATH | Should -BeExactly ([String]::Join([IO.Path]::PathSeparator, @("A", "B", "C")))
    }

    It 'Set Path is restored correctly' {
        Remove-EnvironmentModule "ProgramH"
        $env:ENV_TEST_PATH4 | Should -BeExactly ([String]::Join([IO.Path]::PathSeparator, @("A", "B", "C")))
        $env:ENV_TEST_PATH5 | Should -BeExactly $null
    }

    It 'Custom Set Path is restored correctly' {
        $env:ENV_TEST_PATH4 = "MyValue"
        Remove-EnvironmentModule "ProgramH"
        $env:ENV_TEST_PATH4 | Should -BeExactly "MyValue"
    }
}