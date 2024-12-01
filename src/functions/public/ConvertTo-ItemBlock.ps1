function ConvertTo-ItemBlock {

    # TODO - Investigate.  Possibly unused.

    param (

        $ItemPermissions,

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache,

        $Culture = (Get-Culture)

    )

    Write-LogMsg -Cache $Cache -Text "`$ObjectsForTable = Select-ItemTableProperty -InputObject `$ItemPermissions -Culture '$Culture'"
    $ObjectsForTable = Select-ItemTableProperty -InputObject $ItemPermissions -Culture $Culture

    Write-LogMsg -Cache $Cache -Text "`$ObjectsForTable | ConvertTo-Html -Fragment | New-BootstrapTable"
    $HtmlTable = $ObjectsForTable |
    ConvertTo-Html -Fragment |
    New-BootstrapTable

    $JsonData = $ObjectsForTable |
    ConvertTo-Json -Compress

    Write-LogMsg -Cache $Cache -Text "Get-ColumnJson -InputObject `$ObjectsForTable"
    $JsonColumns = Get-ColumnJson -InputObject $ObjectsForTable

    Write-LogMsg -Cache $Cache -Text "ConvertTo-BootstrapJavaScriptTable -Id 'Folders' -InputObject `$ObjectsForTable -DataFilterControl -SearchableColumn 'Folder' -DropdownColumn 'Inheritance'"
    $JsonTable = ConvertTo-BootstrapJavaScriptTable -Id 'Folders' -InputObject $ObjectsForTable -DataFilterControl -SearchableColumn 'Folder' -DropdownColumn 'Inheritance'

    return [pscustomobject]@{
        HtmlDiv     = $HtmlTable
        JsonDiv     = $JsonTable
        JsonData    = $JsonData
        JsonColumns = $JsonColumns
    }

}
