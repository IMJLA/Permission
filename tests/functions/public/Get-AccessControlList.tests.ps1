$ScriptName = 'Get-AccessControlList.ps1'
$ScriptPath = "$($PSScriptRoot -replace 'tests','src')\$ScriptName"

Describe "'$ScriptName' Function Tests" {
    # TestCases are splatted to the script so we need hashtables
    $validPowerShellTestCase = @{ Script = $ScriptPath }
    It "Script '<Script>' can be tokenized by the PowerShell parser without any errors" -TestCases $validPowerShellTestCase {
        param ($Script)
        $ScriptContents = Get-Content -LiteralPath $Script -ErrorAction Stop
        $Errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize($ScriptContents, [ref]$Errors)
        $Errors.Count | Should -Be 0
    }

    $noErrorsTestCase = @{ ThisScriptPath = $ScriptPath }
    It "Script file '$ScriptName' runs without any errors" -TestCases $noErrorsTestCase {
        param ($ThisScriptPath)
        { . $ThisScriptPath } | Should -Not -Throw
    }

}
