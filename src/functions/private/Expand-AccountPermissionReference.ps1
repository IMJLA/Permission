function Expand-AccountPermissionReference {

    param (

        $Reference,
        $PrincipalsByResolvedID,
        $ACEsByGUID

    )

    ForEach ($Account in $Reference) {

        $Access = ForEach ($PermissionRef in $Account.Access) {

            [PSCustomObject]@{
                Path       = $PermissionRef.Path
                Access     = $ACEsByGUID[$PermissionRef.AceGUIDs]
                PSTypeName = 'Permission.AccountPermissionItemAccess'
            }

        }

        [PSCustomObject]@{
            Account    = $PrincipalsByResolvedID[$Account.Account]
            Access     = $Access
            PSTypeName = 'Permission.AccountPermission'
        }

    }

}
