param(
    [parameter(Position=0, Mandatory=$true)]
	[EnvironmentModules.EnvironmentModule]
	$Module
)

$Module.AddAlias("ppp", "Start-ProgramD", "Use 'ppp' to start ProgramD")
$Module.AddSetPath("PROJECT_ROOT", "C:\Temp")

$Module.AddFunction("Start-Cmd", {
	return $args + @("something")
})