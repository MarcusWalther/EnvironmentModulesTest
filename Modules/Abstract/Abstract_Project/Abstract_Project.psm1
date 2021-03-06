param(
    [parameter(Position=0, Mandatory=$true)]
	[EnvironmentModuleCore.EnvironmentModule]
	$Module
)

$Module.AddFunction("Get-ProjectRoot", {
	return $env:PROJECT_ROOT
})

$Module.AddFunction("Get-SourceModule", {
	return $Module.SourceModule
})