param(
    [parameter(Position=0, Mandatory=$true)]
	[EnvironmentModuleCore.EnvironmentModule]
	$Module
)

$Module.AddAlias("ppp", "Start-ProgramD", "Use 'ppp' to start ProgramD")
$Module.AddSetPath("PROJECT_ROOT", "C:\Temp\Something")
$Module.AddSetPath("PROJECT_ROOT", "C:\Temp")

$Module.AddFunction("Start-Cmd", {
	return $args + @("something")
})