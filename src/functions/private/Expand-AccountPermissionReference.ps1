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
                PSTypeName = 'Permission.AccountPermissionItemAccess'
                # Enumerate the list because the returned dictionary value is a list
                Access     = ForEach ($ACE in $ACEsByGUID[$PermissionRef.AceGUIDs]) {
                    $ACE
                }
            }

        }

        [PSCustomObject]@{
            Account     = $PrincipalsByResolvedID[$Account.Account]
            AccountName = $Account.Account
            Access      = $Access
            PSTypeName  = 'Permission.AccountPermission'
        }

    }

}
