param(
    [parameter(Position=0, Mandatory=$true)]
	[EnvironmentModules.EnvironmentModule]
	$Module
)

$Module.AddSetPath("PROJECT_ROOT", "C:\Temp")

$Module.AddFunction("Start-Cmd", {
	return $args
})

$Module.AddFunction("Get-ProjectValue", {
	return (Get-EnvironmentModuleParameter "ProgramD.Parameter1").Value
})