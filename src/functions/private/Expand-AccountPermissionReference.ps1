function Expand-AccountPermissionReference {

    param (

        $Reference,
        [ref]$PrincipalsByResolvedID,
        [ref]$ACEsByGUID,
        [ref]$ACLsByPath

    )

    ForEach ($Account in $Reference) {

        $Access = ForEach ($PermissionRef in $Account.Access) {

            [PSCustomObject]@{
                Access     = Expand-AccountPermissionItemAccessReference -Reference $PermissionRef.AceGUIDs -AccountReference $Account -PrincipalsByResolvedID $PrincipalsByResolvedID -ACEsByGUID $ACEsByGUID -ACLsByPath $ACLsByPath
                Item       = $ACLsByPath.Value[$PermissionRef.Path]
                PSTypeName = 'Permission.AccountPermissionItemAccess'
            }

        }

        [PSCustomObject]@{
            Account     = $PrincipalsByResolvedID.Value[$Account.Account]
            AccountName = $Account.Account
            Access      = $Access
            PSTypeName  = 'Permission.AccountPermission'
        }

    }

}
