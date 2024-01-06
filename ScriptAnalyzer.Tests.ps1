. "$PSScriptRoot/TestCommon.ps1"

Describe 'Testing against Script Analyzer rules' {
    Context 'Script Analyzer Standard Rules' {
        $folder = (Get-Module "EnvironmentModuleCore").ModuleBase
        $script:analysis = Invoke-ScriptAnalyzer -Path "$folder" -Severity Warning -Recurse
        $scriptAnalyzerRules = Get-ScriptAnalyzerRule
        #forEach ($rule in $script:scriptAnalyzerRules) {
            It "Should pass $rule" -TestCases ($scriptAnalyzerRules | Foreach-Object {@{rule = $_}}) {
                param ($rule)
                If ($script:analysis.RuleName -contains $rule) {
                    $failures = $script:analysis | Where-Object RuleName -EQ $rule
                    if($failures.Length -gt 0) {
                        $failures | Out-Default
                    }
                    $failures.Length | Should -Be 0
                }
            }
        #}
    }
}