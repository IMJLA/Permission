function Get-ReportErrorDiv {

    param (

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $EnumErrors = $Cache.Value['ErrorByItemPath_Enumeration'].Value
    $AclErrors = $Cache.Value['ErrorByItemPath_AclRetrieval'].Value

    if ($EnumErrors.Keys.Count -gt 0 -or $AclErrors.Keys.Count -gt 0) {

        $StringBuilder = [System.Text.StringBuilder]::new()
        $Alert = New-BootstrapAlert -Class danger -Text 'Danger! Errors were encountered which could result in permissions missing from this report.'
        $null = $StringBuilder.Append($Alert)

        $ErrorObjects = [System.Collections.Generic.list[PSCustomObject]]::new()

        ForEach ($EnumErrorPath in $EnumErrors.Keys) {

            $ErrorObjects.Add([PSCustomObject]@{
                    'Stage' = 'Item Enumeration'
                    'Item'  = $EnumErrorPath
                    'Error' = $EnumErrors[$EnumErrorPath]
                })

        }

        ForEach ($AclErrorPath in $AclErrors.Keys) {

            $ErrorObjects.Add([PSCustomObject]@{
                    'Stage' = 'ACL Retrieval'
                    'Item'  = $AclErrorPath
                    'Error' = $AclErrors[$AclErrorPath]
                })
        }

        $ErrorTable = $ErrorObjects |
        Sort-Object -Property Item, Stage |
        ConvertTo-Html -Fragment |
        New-BootstrapTable -Class ' table-danger'

        $null = $StringBuilder.AppendLine($ErrorTable)
        New-BootstrapDiv -Text ($StringBuilder.ToString())

    }

}
