function ConvertTo-ItemBlock {

    # TODO - Investigate.  Possibly unused.

    param (

        $ItemPermissions,

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    <#
    Information about the current culture settings.
    This includes information about the current language settings on the system, such as the keyboard layout, and the
    display format of items such as numbers, currency, and dates.
    #>
    $Culture = $Cache.Value['Culture'].Value

    $Log = @{
        'Cache'        = $Cache
        'ExpansionMap' = $Cache.Value['LogEmptyMap'].Value
    }

    Write-LogMsg @Log -Text "`$ObjectsForTable = Select-ItemTableProperty -InputObject `$ItemPermissions -Culture '$Culture'"
    $ObjectsForTable = Select-ItemTableProperty -InputObject $ItemPermissions -Culture $Culture

    Write-LogMsg @Log -Text "`$ObjectsForTable | ConvertTo-Html -Fragment | New-BootstrapTable"
    $HtmlTable = $ObjectsForTable |
    ConvertTo-Html -Fragment |
    New-BootstrapTable

    $JsonData = $ObjectsForTable |
    ConvertTo-Json -Compress

    Write-LogMsg @Log -Text "Get-ColumnJson -InputObject `$ObjectsForTable"
    $JsonColumns = Get-ColumnJson -InputObject $ObjectsForTable

    Write-LogMsg @Log -Text "ConvertTo-BootstrapJavaScriptTable -Id 'Folders' -InputObject `$ObjectsForTable -DataFilterControl -SearchableColumn 'Folder' -DropdownColumn 'Inheritance'"
    $JsonTable = ConvertTo-BootstrapJavaScriptTable -Id 'Folders' -InputObject $ObjectsForTable -DataFilterControl -SearchableColumn 'Folder' -DropdownColumn 'Inheritance'

    return [pscustomobject]@{
        HtmlDiv     = $HtmlTable
        JsonDiv     = $JsonTable
        JsonData    = $JsonData
        JsonColumns = $JsonColumns
    }

}
