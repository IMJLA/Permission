function Expand-ItemPermissionReference {

    param (

        $Reference,
        [ref]$PrincipalsByResolvedID,
        [ref]$ACEsByGUID,
        [ref]$ACLsByPath

    )

    ForEach ($Item in $Reference) {

        [PSCustomObject]@{
            Item       = $ACLsByPath.Value[$Item.Path]
            Access     = Expand-ItemPermissionAccountAccessReference -Reference $Item.Access -AceByGUID $ACEsByGUID -PrincipalByResolvedID $PrincipalsByResolvedID
            PSTypeName = 'Permission.ItemPermission'
        }

    }

}
