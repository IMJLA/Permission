function Get-FolderAccessList {
    param (
        $FolderTargets,
        $LevelsOfSubfolders
    )
    ForEach ($ThisFolder in $FolderTargets) {
        $Subfolders = $null
        $Subfolders = Get-Subfolder -TargetPath $ThisFolder -FolderRecursionDepth $LevelsOfSubfolders -ErrorAction Continue
        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExport-Permission`tGet-FolderAccessList`tFolders (including parent): $($Subfolders.Count + 1)"
        Get-FolderAce -LiteralPath $ThisFolder -IncludeInherited
        if ($Subfolders) {
            Split-Thread -Command Get-FolderAce -InputObject $Subfolders -InputParameter LiteralPath
        }
    }
}
