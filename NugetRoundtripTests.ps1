if($null -eq (Get-Module -Name "Pester")) {
    Import-Module Pester
}

# The directories and scripts to use
$modulesRootFolder = Join-Path $PSScriptRoot "Modules"
$downloadedModulesRootFolder = Join-Path $PSScriptRoot "DownloadedModules"
mkdir -Force $downloadedModulesRootFolder

$tempDirectory = Join-Path $PSScriptRoot "Tmp"
$configDirectory = Join-Path $PSScriptRoot "Config"
$startEnvironmentScript = Join-Path $env:ENVIRONMENT_MODULE_ROOT (Join-Path "Samples" "StartSampleEnvironment.ps1")

Describe 'TestRoundtrip' {

    BeforeEach {
        $additionalModulePaths = [string]::Join([IO.Path]::PathSeparator, (Get-ChildItem -Directory $modulesRootFolder))

        # Prepare the environment
        . $startEnvironmentScript -AdditionalModulePaths $additionalModulePaths -TempDirectory $tempDirectory -ConfigDirectory $configDirectory -IgnoreSamplesFolder
        Set-EnvironmentModuleConfigurationValue -ParameterName "DefaultModuleStoragePath" -Value $modulesRootFolder

        # Push all modules
        Get-NonTempEnvironmentModules | ForEach-Object { Publish-EnvironmentModuleNuget -ModuleFullName $_.FullName -SkipDependencyCheck}
    }
    AfterEach {
        Find-EnvironmentModuleNuget "*" | ForEach-Object { Remove-EnvironmentModuleNuget -ModuleFullName $_.Name -Version $_.Version -Force}
    }

    # It 'All modules were pushed successfully' {
    #     $allInstalledModules = New-Object "System.Collections.Generic.HashSet[string]"
    #     foreach($name in (Get-NonTempEnvironmentModules | Select-Object -ExpandProperty "FullName")) {
    #         $allInstalledModules.Add($name)
    #     }

    #     $allAvailableModules = New-Object "System.Collections.Generic.HashSet[string]"
    #     foreach($name in (Find-EnvironmentModuleNuget "*" | Select-Object -ExpandProperty "Name")) {
    #         $allAvailableModules.Add($name)
    #     }

    #     $allInstalledModules.SetEquals($allAvailableModules) | Should -Be $true
    # }

    It 'All modules were pulled successfully' {
        $additionalModulePaths = ""

        # Prepare the environment
        . $startEnvironmentScript -AdditionalModulePaths $additionalModulePaths -TempDirectory $tempDirectory -ConfigDirectory $configDirectory -IgnoreSamplesFolder
        Set-EnvironmentModuleConfigurationValue -ParameterName "DefaultModuleStoragePath" -Value $downloadedModulesRootFolder

        # Pull all modules
        Find-EnvironmentModuleNuget "*" | ForEach-Object { Install-EnvironmentModuleNuget -ModuleFullName $_.Name -IgnoreDependencies }
    }
}