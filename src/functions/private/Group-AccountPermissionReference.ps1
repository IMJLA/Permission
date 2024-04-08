function Group-AccountPermissionReference {

    param (
        [hashtable]$ID,
        [hashtable]$AceGuidByID,
        [hashtable]$AceByGuid
    )

    ForEach ($ShortName in ($ID.Keys | Sort-Object)) {

        $ItemPaths = @{}

        ForEach ($Identity in $ID[$ShortName]) {

            ForEach ($Guid in $AceGuidByID[$Identity]) {

                Add-CacheItem -Cache $ItemPaths -Key $AceByGuid[$Guid].Path -Value $Guid -Type ([guid])

            }

        }

        [PSCustomObject]@{
            Account = $ShortName
            Access  = ForEach ($Item in ($ItemPaths.Keys | Sort-Object)) {

                [PSCustomObject]@{
                    Path     = $Item
                    AceGUIDs = $ItemPaths[$Item]
                }

            }

        }

    }

}
