function Expand-ItemPermissionReference {

    param (

        $Reference,
        $PrincipalsByResolvedID,
        $ACEsByGUID,
        $ACLsByPath

    )

    ForEach ($Item in $Reference) {

        [PSCustomObject]@{
            Item       = $ACLsByPath[$Item.Path]
            Access     = Expand-ItemPermissionAccountAccessReference -Reference $Item.Access -AceByGUID $ACEsByGUID -PrincipalByResolvedID $PrincipalsByResolvedID
            PSTypeName = 'Permission.ItemPermission'
        }

    }

}
