function Select-FolderTableProperty {
    # For the HTML table
    param (
        $InputObject
    )
    $Culture = Get-Culture
    $InputObject | Select-Object -Property @{
        Label      = 'Folder'
        Expression = { $_.Name }
    },
    @{
        Label      = 'Inheritance'
        Expression = {
            $Culture.TextInfo.ToTitleCase(@($_.Group.FolderInheritanceEnabled)[0])
        }
    }
}
