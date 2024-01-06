param(
    [parameter(Position=0, Mandatory=$true)]
	[EnvironmentModuleCore.EnvironmentModule]
	$Module
)

$Module.AddPrependPath("ENV_TEST_PATH", [String]::Join([IO.Path]::PathSeparator, @("C", "D", "E", "F")))
$Module.AddAppendPath("ENV_TEST_PATH2", [String]::Join([IO.Path]::PathSeparator, @("A", "B")))
$Module.AddAppendPath("ENV_TEST_PATH3", "XX")
$Module.AddSetPath("ENV_TEST_PATH4", "YY")
$Module.AddSetPath("ENV_TEST_PATH5", "ZZ" + [IO.Path]::PathSeparator + "RR")
$Module.AddAppendPath("ENV_TEST_PATH6", "BasePathA" + [IO.Path]::PathSeparator + "BasePathB", "Base")
$Module.AddAppendPath("ENV_TEST_PATH6", "MiddlePathA" + [IO.Path]::PathSeparator + "MiddlePathB", "ExtensionMiddle")
$Module.AddAppendPath("ENV_TEST_PATH6", "", "ExtensionMiddle2")
$Module.AddAppendPath("ENV_TEST_PATH6", "EndPathA" + [IO.Path]::PathSeparator + "EndPathB", "ExtensionEnd")
