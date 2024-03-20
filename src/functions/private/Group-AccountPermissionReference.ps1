function Group-AccountPermissionReference {

    param (
        $ID,
        [hashtable]$AceGUIDsByResolvedID,
        [hashtable]$ACEsByGUID
    )

    ForEach ($Identity in ($ID | Sort-Object)) {

        $ItemPaths = @{}
        Write-Host "$($AceGUIDsByResolvedID[$Identity].Count) ACEs for '$Identity' of $($AceGUIDsByResolvedID.Keys.Count) total"
        ForEach ($Guid in $AceGUIDsByResolvedID[$Identity]) {

            $Ace = $ACEsByGUID[$Guid]
            Add-CacheItem -Cache $ItemPaths -Key $Ace.Path -Value $Guid -Type ([guid])

        }
        Write-Host "$($ItemPaths.Keys.Count) Item Paths for '$Identity'"

        [PSCustomObject]@{
            Account = $Identity
            Access  = ForEach ($Item in ($ItemPaths.Keys | Sort-Object)) {

                [PSCustomObject]@{
                    Path     = $Item
                    AceGUIDs = $ItemPaths[$Item]
                }

            }

        }

    }

}
