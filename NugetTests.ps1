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