. "$PSScriptRoot/TestCommon.ps1"

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
        $modules.Length | Should -Be 5
        $modules = Compare-EnvironmentModulesByVersion $modules
        $modules.Length | Should -Be 5
        $modules[0].Version | Should -Be "3_11"
        $modules[3].Version | Should -Be "3_6"
        $modules[4].Version | Should -Be "DEV"
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