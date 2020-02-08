param(
    [parameter(Position=0, Mandatory=$true)]
	[EnvironmentModuleCore.EnvironmentModule]
	$Module
)

Set-EnvironmentModuleParameter "ProgramE.Parameter3" "MyValue"