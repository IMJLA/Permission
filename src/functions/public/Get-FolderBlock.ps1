function Get-FolderBlock {
    param (

        $FolderPermissions

    )

    Write-LogMsg @LogParams -Text "Select-FolderTableProperty -InputObject `$FolderPermissions | ConvertTo-Html -Fragment | New-BootstrapTable"
    $FolderObjectsForTable = Select-FolderTableProperty -InputObject $FolderPermissions |
    Sort-Object -Property Folder

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
