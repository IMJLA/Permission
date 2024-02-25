function Expand-ItemPermissionReference {

    param (

        $Reference,
        $PrincipalsByResolvedID,
        $ACEsByGUID

    )

    ForEach ($Item in $Reference) {

        $Access = ForEach ($PermissionRef in $Item.Access) {

            [PSCustomObject]@{
                Account    = $PrincipalsByResolvedID[$PermissionRef.Account]
                Access     = $ACEsByGUID[$PermissionRef.AceGUIDs]
                PSTypeName = 'Permission.ItemPermissionAccountAccess'
            }

        }

        [PSCustomObject]@{
            Item       = $Item.Item
            Access     = $Access
            PSTypeName = 'Permission.ItemPermission'
        }

    }

}