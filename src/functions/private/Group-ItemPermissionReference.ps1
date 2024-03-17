function Group-ItemPermissionReference {

    param (
        $SortedPath,
        $AceGUIDsByPath,
        $ACEsByGUID,
        $PrincipalsByResolvedID,
        [hashtable]$Property = @{}
    )

    ForEach ($ItemPath in $SortedPath) {

        $Property['Path'] = $ItemPath
        $IDsWithAccess = Find-ResolvedIDsWithAccess -ItemPath $ItemPath -AceGUIDsByPath $AceGUIDsByPath -ACEsByGUID $ACEsByGUID -PrincipalsByResolvedID $PrincipalsByResolvedID

        $Property['Access'] = ForEach ($ID in ($IDsWithAccess.Keys | Sort-Object)) {

            [PSCustomObject]@{
                Account  = $ID
                AceGUIDs = $IDsWithAccess[$ID]
            }

        }

        [PSCustomObject]$Property

    }

}
