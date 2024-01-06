if($null -eq (Get-Module -Name "Pester")) {
    Import-Module Pester
}

if($null -eq (Get-Module -Name "PSScriptAnalyzer")) {
    Import-Module PSScriptAnalyzer
}

# The directories and scripts to use
$global:modulesRootFolder = Join-Path $PSScriptRoot "Modules"
Write-Verbose "Using root folder $global:modulesRootFolder"

$additionalModulePaths = [string]::Join([IO.Path]::PathSeparator, (Get-ChildItem -Directory $global:modulesRootFolder | Select-Object -ExpandProperty "FullName"))

$global:tempDirectory = Join-Path $PSScriptRoot "Tmp"
$configDirectory = Join-Path $PSScriptRoot "Config"
$startEnvironmentScript = Join-Path ((Get-Module "EnvironmentModuleCore").ModuleBase) (Join-Path "Samples" "StartSampleEnvironment.ps1")

if(-not (Test-Path "$startEnvironmentScript")) {
    # Fallback directory, if the samples cannot be found in the active EnvironmentModuleCore module
    $startEnvironmentScript = Join-Path "$PSScriptRoot/.." (Join-Path "Samples" "StartSampleEnvironment.ps1")
}

# Prepare the environment
. $startEnvironmentScript -AdditionalModulePaths $additionalModulePaths -TempDirectory $global:tempDirectory -ConfigDirectory $configDirectory -IgnoreSamplesFolder
Set-EnvironmentModuleConfigurationValue -ParameterName "DefaultModuleStoragePath" -Value $global:modulesRootFolder

Update-EnvironmentModuleCache
