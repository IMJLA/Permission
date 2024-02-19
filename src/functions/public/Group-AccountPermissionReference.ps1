function Group-AccountPermissionReference {

    param (
        $PrincipalsByResolvedID,
        $AceGUIDsByResolvedID,
        $ACEsByGUID
    )

    ForEach ($ID in $PrincipalsByResolvedID.Keys) {

        $ACEGuidsForThisID = $AceGUIDsByResolvedID[$ID]
        $ItemPaths = @{}

        ForEach ($Guid in $ACEGuidsForThisID) {

            $Ace = $ACEsByGUID[$Guid]
            Add-CacheItem -Cache $ItemPaths -Key $Ace.Path -Value $Guid -Type ([guid])

        }

        $ItemPermissionsForThisAccount = ForEach ($Item in $ItemPaths.Keys) {

            [PSCustomObject]@{
                Path     = $Item
                AceGUIDs = $ItemPaths[$Item]
            }

        }

        [PSCustomObject]@{
            Account = $ID
            Access  = $ItemPermissionsForThisAccount
        }

    }

}
