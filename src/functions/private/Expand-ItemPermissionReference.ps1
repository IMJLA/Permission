function Expand-ItemPermissionReference {

    param (

        $Reference,
        $PrincipalsByResolvedID,
        $ACEsByGUID,
        $ACLsByPath,
        [hashtable]$IdByShortName = [hashtable]::Synchronized(@{})

    )

    ForEach ($Item in $Reference) {

        [PSCustomObject]@{
            Item       = $ACLsByPath[$Item.Path]
            Access     = Expand-ItemPermissionAccountAccessReference -Reference $Item.Access -AceByGUID $ACEsByGUID -PrincipalByResolvedID $PrincipalsByResolvedID -IdByShortName $IdByShortName
            PSTypeName = 'Permission.ItemPermission'
        }

    }

}
