function Expand-AccountPermissionReference {

    param (

        $Reference,
        [ref]$PrincipalsByResolvedID,
        [ref]$ACEsByGUID,
        [ref]$ACLsByPath

    )

    ForEach ($Account in $Reference) {

        [PSCustomObject]@{
            Account    = $PrincipalsByResolvedID.Value[$Account.Account]
            Access     = Expand-AccountPermissionItemAccessReference -Reference $Account.Access -AceByGUID $ACEsByGUID -AclByPath $ACLsByPath
            PSTypeName = 'Permission.AccountPermission'
        }

    }

}
