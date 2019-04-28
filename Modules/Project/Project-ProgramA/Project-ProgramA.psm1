param(
    [parameter(Position=0, Mandatory=$true)]
	[EnvironmentModuleCore.EnvironmentModule]
	$Module
)

$Module.AddSetPath("PROJECT_ROOT", "C:\Temp")

$Module.AddFunction("Start-Cmd", {
	return $args
})

$Module.AddFunction("Get-ProjectValue", {
	return (Get-EnvironmentModuleParameter "ProgramD.Parameter1").Value
})

$Module.AddFunction("Render-TemplateFile", {
	$definition = New-Object "System.Collections.Generic.Dictionary[string, object]"
	$definition["Key"] = "Hello"
	$definition["Value"] = "World"

	$targetFile = (Join-Path $Module.TmpDirectory "RenderedFile.txt")
	$templateFile = (Join-Path $Module.ModuleBase "TemplateFile.template")
	[EnvironmentModuleCore.TemplateRenderer]::CreateConcreteFileFromTemplate($definition, $templateFile, $targetFile)

	return $targetFile
})