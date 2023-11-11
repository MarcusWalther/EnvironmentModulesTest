. "$PSScriptRoot/TestCommon.ps1"

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

    It 'Parameter placeholders are replaced correctly' {
        Import-EnvironmentModule 'Project-ProgramD' -Silent
        $moduleRoot = (Get-EnvironmentModule "Project-ProgramD").ModuleRoot
        $moduleRoot | Should -Not -BeNullOrEmpty
        (Get-EnvironmentModuleParameter "ProgramD.Parameter3").Value | Should -BeExactly (Resolve-NotExistingPath "$moduleRoot/MySolution.sln")
        (Get-EnvironmentModuleParameter "ProgramD.Parameter3").IsUserDefined | Should -BeExactly $false
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

Describe 'TestPathManipulationPsm1' {
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

Describe 'TestPathManipulationPse1' {
    BeforeEach {
        Import-EnvironmentModule "Project-ProgramD" -Silent
    }
    AfterEach {
        Remove-EnvironmentModule "Project-ProgramD"
        $env:PROGRAM_D_ENV_VARIABLE = $null
        $env:PROGRAM_D_ENV_VARIABLE_2 = "MyTestValue"
    }

    It 'Simple Set Path is working correctly' {
        $moduleRoot = (Get-EnvironmentModule "Project-ProgramD").ModuleRoot
        $env:PROGRAM_D_ENV_VARIABLE | Should -BeExactly ([System.IO.Path]::Join($moduleRoot, "Subfolder"))
        Remove-EnvironmentModule "Project-ProgramD"
        $env:PROGRAM_D_ENV_VARIABLE | Should -BeExactly $null
    }

    It 'Append Path is working correctly' {
        $moduleRoot = (Get-EnvironmentModule "Project-ProgramD").ModuleRoot
        $env:PROGRAM_D_ENV_VARIABLE_2 | Should -BeExactly ([String]::Join([IO.Path]::PathSeparator, @("MyTestValue", [System.IO.Path]::Join($moduleRoot, "Subfolder"), [System.IO.Path]::Join($moduleRoot, "Subfolder2"), "StaticContent")))
        Remove-EnvironmentModule "Project-ProgramD"
        $env:PROGRAM_D_ENV_VARIABLE | Should -BeExactly $null
    }
}

Describe 'TestDynamicParameterManipulation' {
    BeforeEach {
        $env:ENV_TEST_PATH6 = ""
        Import-EnvironmentModule "ProgramH" -Silent
    }
    AfterEach {
        Remove-EnvironmentModule "ProgramH"
    }

    It 'Middle Part of Path can be changed' {
        $pathInfo = Get-EnvironmentModulePath -Key "ExtensionMiddle"
        $pathInfo.Key | Should -BeExactly "ExtensionMiddle"
        $env:ENV_TEST_PATH6 | Should -BeExactly ([String]::Join([IO.Path]::PathSeparator, @("BasePathA", "BasePathB", "MiddlePathA", "MiddlePathB", "EndPathA", "EndPathB")))
        $pathInfo.Variable | Should -BeExactly "ENV_TEST_PATH6"
        $pathInfo.ChangeValues("NewMiddlePathA")
        Wait-Event -SourceIdentifier "OnPathChanged" -Timeout 1
        $env:ENV_TEST_PATH6 | Should -BeExactly ([String]::Join([IO.Path]::PathSeparator, @("BasePathA", "BasePathB", "NewMiddlePathA", "EndPathA", "EndPathB")))
    }

    It 'Final Part of Path can be changed' {
        $pathInfo = Get-EnvironmentModulePath -Key "ExtensionEnd"
        $pathInfo.Key | Should -BeExactly "ExtensionEnd"
        $env:ENV_TEST_PATH6 | Should -BeExactly ([String]::Join([IO.Path]::PathSeparator, @("BasePathA", "BasePathB", "MiddlePathA", "MiddlePathB", "EndPathA", "EndPathB")))
        $pathInfo.Variable | Should -BeExactly "ENV_TEST_PATH6"
        $pathInfo.ChangeValues("NewEndPathA")
        Wait-Event -SourceIdentifier "OnPathChanged" -Timeout 1
        $env:ENV_TEST_PATH6 | Should -BeExactly ([String]::Join([IO.Path]::PathSeparator, @("BasePathA", "BasePathB", "MiddlePathA", "MiddlePathB", "NewEndPathA")))
    }

    It 'Trailing Part of Path can be changed' {
        $pathInfo = Get-EnvironmentModulePath -Key "Base"
        $pathInfo.Key | Should -BeExactly "Base"
        $env:ENV_TEST_PATH6 | Should -BeExactly ([String]::Join([IO.Path]::PathSeparator, @("BasePathA", "BasePathB", "MiddlePathA", "MiddlePathB", "EndPathA", "EndPathB")))
        $pathInfo.Variable | Should -BeExactly "ENV_TEST_PATH6"
        $pathInfo.ChangeValues("NewStartPathA")
        Wait-Event -SourceIdentifier "OnPathChanged" -Timeout 1
        $env:ENV_TEST_PATH6 | Should -BeExactly ([String]::Join([IO.Path]::PathSeparator, @("NewStartPathA", "MiddlePathA", "MiddlePathB", "EndPathA", "EndPathB")))
    }

    It 'Path can be added dynamically' {
        $module = Get-EnvironmentModule "ProgramH"
        $module.AddPrependPath("ENV_TEST_PATH6", "NewPrependPath")
        Wait-Event -SourceIdentifier "OnPathAdded" -Timeout 1
        $env:ENV_TEST_PATH6 | Should -BeExactly ([String]::Join([IO.Path]::PathSeparator, @("NewPrependPath", "BasePathA", "BasePathB", "MiddlePathA", "MiddlePathB", "EndPathA", "EndPathB")))
        Remove-EnvironmentModule "ProgramH"
        $env:ENV_TEST_PATH6 | Should -BeNullOrEmpty
    }

    It 'Function and alias can be added dynamically' {
        $module = Get-EnvironmentModule "ProgramH"
        $module.AddFunction("TestFunction", {return 42})
        Wait-Event -SourceIdentifier "OnFunctionAdded" -Timeout 1
        $result = TestFunction
        $result | Should -BeExactly 42

        $module.AddAlias("TestAlias", "TestFunction")
        Wait-Event -SourceIdentifier "OnAliasAdded" -Timeout 1
        $result = TestAlias
        $result | Should -BeExactly 42

        Remove-EnvironmentModule "ProgramH"
        {TestFunction} | Should -Throw
    }
}

Describe 'TestPathManipulationEnvironmentDescription' {
    BeforeEach {
        $env:ENV_TEST_PATH = [String]::Join([IO.Path]::PathSeparator, @("A", "B", "C"))
        $env:ENV_TEST_PATH2 = $env:ENV_TEST_PATH
        $env:ENV_TEST_PATH3 = $env:ENV_TEST_PATH
        $env:ENV_TEST_PATH4 = $env:ENV_TEST_PATH
        Import-EnvironmentModule "ProgramH" -Silent
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }
}