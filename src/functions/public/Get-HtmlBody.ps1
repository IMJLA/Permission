function Get-HtmlBody {
    param (
        $FolderList,
        $HtmlFolderPermissions
    )
    (New-HtmlHeading "Folders with Permissions in This Report" -Level 3) +
    $FolderList +
(New-HtmlHeading "Accounts Included in Those Permissions" -Level 3) +
    $HtmlFolderPermissions
}