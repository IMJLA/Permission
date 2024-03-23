function Group-AccountPermissionReference {

    param (
        $ID,
        [hashtable]$AceGuidByID,
        [hashtable]$AceByGuid
    )

    ForEach ($Identity in ($ID | Sort-Object)) {

        $ItemPaths = @{}

        ForEach ($Guid in $AceGuidByID[$Identity]) {

            $Ace = $AceByGuid[$Guid]
            Add-CacheItem -Cache $ItemPaths -Key $Ace.Path -Value $Guid -Type ([guid])

        }

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
