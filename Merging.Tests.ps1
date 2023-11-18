. "$PSScriptRoot/TestCommon.ps1"

Describe 'TestMerge' {
    BeforeEach {
        $rootPath = (Get-Module "EnvironmentModuleCore")[0].ModuleBase
        . "$rootPath/ModuleMerging.ps1"
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Dependencies are merged correctly' {
        $moduleA = New-EnvironmentModuleInfoFromDescriptionFile -Path "$PSScriptRoot/Descriptions/ModuleA.pse1"
        $moduleB = New-EnvironmentModuleInfoFromDescriptionFile -Path "$PSScriptRoot/Descriptions/ModuleB.pse1"

        $result = Join-EnvironmentModuleInfos -Base $moduleA -Other $moduleB
        $result.Dependencies.Length | Should -Be 3
    }

    It 'Parameters are merged correctly' {
        $moduleA = New-EnvironmentModuleInfoFromDescriptionFile -Path "$PSScriptRoot/Descriptions/ModuleA.pse1"
        $moduleB = New-EnvironmentModuleInfoFromDescriptionFile -Path "$PSScriptRoot/Descriptions/ModuleB.pse1"

        $result = Join-EnvironmentModuleInfos -Base $moduleA -Other $moduleB
        $result.Parameters.Count | Should -Be 3

        $key = $result.Parameters.Keys | Where-Object { $_.Item1 -eq "ProgramD.Parameter1" }
        $result.Parameters[$key].Value | Should -Be "SamplePse1Value"
    }

    It 'Path manipulations are merged correctly' {
        $moduleA = New-EnvironmentModuleInfoFromDescriptionFile -Path "$PSScriptRoot/Descriptions/ModuleA.pse1"
        $moduleB = New-EnvironmentModuleInfoFromDescriptionFile -Path "$PSScriptRoot/Descriptions/ModuleB.pse1"

        $result = Join-EnvironmentModuleInfos -Base $moduleA -Other $moduleB
        $result.Paths.Count | Should -Be 3

        $path = $result.Paths | Where-Object { $_.Variable -eq "MODULE_A_VAR" }
        $path.Values.Count | Should -Be 2

        $path = $result.Paths | Where-Object { $_.Variable -eq "MODULE_A_VAR2" }
        $path.Values.Count | Should -Be 1

        $path = $result.Paths | Where-Object { $_.Variable -eq "MODULE_B_VAR" }
        $path.Values.Count | Should -Be 1
    }
}
