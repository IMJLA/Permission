function Get-FolderBlock {
    param (

        $FolderPermissions

    )
    $Culture = Get-Culture

    Write-LogMsg @LogParams -Text "Select-ItemTableProperty -InputObject `$FolderPermissions | ConvertTo-Html -Fragment | New-BootstrapTable"
    $FolderObjectsForTable = Select-ItemTableProperty -InputObject $FolderPermissions -Culture $Culture |
    Sort-Object -Property Path

    $HtmlTable = $FolderObjectsForTable |
    ConvertTo-Html -Fragment |
    New-BootstrapTable

    $JsonData = $FolderObjectsForTable |
    ConvertTo-Json

    $JsonColumns = Get-FolderColumnJson -InputObject $FolderObjectsForTable
    $JsonTable = ConvertTo-BootstrapJavaScriptTable -Id 'Folders' -InputObject $FolderObjectsForTable -DataFilterControl -SearchableColumn 'Folder' -DropdownColumn 'Inheritance'

    return [pscustomobject]@{
        HtmlDiv     = $HtmlTable
        JsonDiv     = $JsonTable
        JsonData    = $JsonData
        JsonColumns = $JsonColumns
    }

}
