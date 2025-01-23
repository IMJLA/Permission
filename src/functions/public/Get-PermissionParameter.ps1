function Get-PermissionParameter {

    [CmdletBinding()]

    param (

        # $MyInvocation from the calling script
        [System.Management.Automation.InvocationInfo]$Invocation,

        # $PSBoundParameters from the calling script
        [System.Collections.Generic.Dictionary`2[System.String, System.Object]]$BoundParameter

    )

    foreach ($ParamName in $Invocation.MyCommand.Parameters.Keys) {

        if (-not $BoundParameter.ContainsKey($ParamName)) {
            try {
                $BoundParameter.Add($ParamName, (Get-Variable -Name $ParamName -Scope Script -ValueOnly))
            } catch {}
        }

    }

    return $BoundParameter

}
