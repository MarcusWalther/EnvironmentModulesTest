param(
    [parameter(Position=0, Mandatory=$true)]
    [EnvironmentModuleCore.EnvironmentModule]
    $Module
)

$env:PROGRAM_D_LOADED = "false"
$Module.AddAlias("ppp", "Start-ProgramD", "Use 'ppp' to start ProgramD")
$Module.AddSetPath("PROJECT_ROOT", "C:\Temp\Something")
$Module.AddSetPath("PROJECT_ROOT", "C:\Temp")

$Module.AddFunction("Start-Cmd", {
    return $args + @("something")
})

Register-ObjectEvent -InputObject $Module -EventName "OnLoaded" -Action {
    $env:PROGRAM_D_LOADED = "true"
    Start-Cmd | Out-Null  # The function should be available here
}

Register-ObjectEvent -InputObject $Module -EventName "OnUnloaded" -Action {
    $env:PROGRAM_D_LOADED = "false"
}