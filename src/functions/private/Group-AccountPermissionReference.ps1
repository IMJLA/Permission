function Group-AccountPermissionReference {

    param (
        [string[]]$ID,
        [Hashtable]$AceGuidByID,
        [Hashtable]$AceByGuid
    )

    ForEach ($Identity in ($ID | Sort-Object)) {

        $ItemPaths = @{}

        ForEach ($Guid in $AceGuidByID[$Identity]) {

            Add-CacheItem -Cache $ItemPaths -Key $AceByGuid[$Guid].Path -Value $Guid -Type ([guid])

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
