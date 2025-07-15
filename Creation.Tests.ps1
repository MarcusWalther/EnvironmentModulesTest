. "$PSScriptRoot/TestCommon.ps1"

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
        $moduleInfo.ModuleType | Should -BeExactly "Default"
    }

    It 'Module Creation Multiple Dependencies' {
        New-EnvironmentModule -Name "TestModule" -Author "Max Mustermann" -Description "My Test Module" -Version "4.5" -Architecture "x86" -Path "$global:tempDirectory" -Dependencies "ModuleDependency","ModuleDependency2" -Force
        $moduleInfo = New-EnvironmentModuleInfo -ModuleFile "$moduleDirectory/TestModule-4.5-x86.psd1"
        $moduleInfo.Dependencies[0].ModuleFullName | Should -BeExactly "ModuleDependency"
        $moduleInfo.Dependencies[1].ModuleFullName | Should -BeExactly "ModuleDependency2"
    }

    It 'Module Creation Meta' {
        New-EnvironmentModule -Name "TestModule" -Author "Max Mustermann" -Description "My Test Module" -Version "4.5" -Architecture "x86" -RequiredFiles "temp.exe" -SearchPaths "C:\temp" -Path "$global:tempDirectory" -ModuleType "Meta" -Force
        $moduleInfo = New-EnvironmentModuleInfo -ModuleFile "$moduleDirectory/TestModule-4.5-x86.psd1"
        $moduleInfo.ModuleType | Should -BeExactly "Meta"
    }
}