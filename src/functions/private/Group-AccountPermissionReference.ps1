function Group-AccountPermissionReference {

    param (
        $ID,
        $AceGUIDsByResolvedID,
        $ACEsByGUID
    )

    ForEach ($Identity in $ID) {

        $ACEGuidsForThisID = $AceGUIDsByResolvedID[$Identity]
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
            Account = $Identity
            Access  = $ItemPermissionsForThisAccount
        }

    }

}
