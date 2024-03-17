function Expand-ItemPermissionAccountAccessReference {

    param (
        $Reference,
        [hashtable]$PrincipalsByResolvedID,
        [hashtable]$ACEsByGUID
    )

    ForEach ($PermissionRef in $Reference) {

        [PSCustomObject]@{
            Account    = $PrincipalsByResolvedID[$PermissionRef.Account]
            Access     = $ACEsByGUID[$PermissionRef.AceGUIDs]
            PSTypeName = 'Permission.ItemPermissionAccountAccess'
        }

    }

}
