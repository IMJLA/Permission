$Scripts = Get-ChildItem -Path "$($PSScriptRoot -replace 'tests','src')\functions" -Include *.ps1 -Recurse
ForEach ($ThisScript in $Scripts) {
    $ScriptName = $ThisScript.Name
    $ScriptPath = $ThisScript.FullName
    Describe "function '$ScriptName'" {
        # TestCases are splatted to the script so we need hashtables
        $validPowerShellTestCase = @{Script = $ScriptPath }
        It "can be tokenized by the PowerShell parser without any errors" -TestCases $validPowerShellTestCase {
            param ($Script)
            $ScriptContents = Get-Content -LiteralPath $Script -ErrorAction Stop
            $Errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($ScriptContents, [ref]$Errors)
            $Errors.Count | Should -Be 0
        }

        $noErrorsTestCase = @{ThisScriptPath = $ScriptPath }
        It "runs without throwing errors" -TestCases $noErrorsTestCase {
            param ($ThisScriptPath)
            { . $ThisScriptPath } | Should -Not -Throw
        }

    }
}
