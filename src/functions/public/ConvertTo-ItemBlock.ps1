function ConvertTo-ItemBlock {

    param (

        $ItemPermissions

    )

    $Culture = Get-Culture

    Write-LogMsg @LogParams -Text "`$ObjectsForTable = Select-ItemTableProperty -InputObject `$ItemPermissions -Culture '$Culture'"
    $ObjectsForTable = Select-ItemTableProperty -InputObject $ItemPermissions -Culture $Culture

    Write-LogMsg @LogParams -Text "`$ObjectsForTable | ConvertTo-Html -Fragment | New-BootstrapTable"
    $HtmlTable = $ObjectsForTable |
    ConvertTo-Html -Fragment |
    New-BootstrapTable

    $JsonData = $ObjectsForTable |
    ConvertTo-Json

    Write-LogMsg @LogParams -Text "Get-FolderColumnJson -InputObject `$ObjectsForTable"
    $JsonColumns = Get-FolderColumnJson -InputObject $ObjectsForTable

    Write-LogMsg @LogParams -Text "ConvertTo-BootstrapJavaScriptTable -Id 'Folders' -InputObject `$ObjectsForTable -DataFilterControl -SearchableColumn 'Folder' -DropdownColumn 'Inheritance'"
    $JsonTable = ConvertTo-BootstrapJavaScriptTable -Id 'Folders' -InputObject $ObjectsForTable -DataFilterControl -SearchableColumn 'Folder' -DropdownColumn 'Inheritance'

    return [pscustomobject]@{
        HtmlDiv     = $HtmlTable
        JsonDiv     = $JsonTable
        JsonData    = $JsonData
        JsonColumns = $JsonColumns
    }

}
