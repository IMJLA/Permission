function Group-ItemPermissionReference {

    param (
        $SortedPath,
        $AceGUIDsByPath,
        $ACEsByGUID,
        $ACLsByPath,
        $PrincipalsByResolvedID
    )

    ForEach ($ItemPath in $SortedPath) {

        $Acl = $ACLsByPath[$ItemPath]
        $IDsWithAccess = Find-ResolvedIDsWithAccess -ItemPath $ItemPath -AceGUIDsByPath $AceGUIDsByPath -ACEsByGUID $ACEsByGUID -PrincipalsByResolvedID $PrincipalsByResolvedID

        $AccountPermissionsForThisItem = ForEach ($ID in ($IDsWithAccess.Keys | Sort-Object)) {

            [PSCustomObject]@{
                Account  = $ID
                AceGUIDs = $IDsWithAccess[$ID]
            }

        }

        [PSCustomObject]@{
            Item   = $Acl
            Access = $AccountPermissionsForThisItem
        }

    }

}
