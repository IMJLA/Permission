function Group-AccountPermissionReference {

    param (
        [string[]]$ID,
        [ref]$AceGuidByID,
        [ref]$AceByGuid
    )

    $GuidType = [guid]

    ForEach ($Identity in ($ID | Sort-Object)) {

        $ItemPaths = @{}

        ForEach ($Guid in $AceGuidByID.Value[$Identity]) {

            Add-CacheItem -Cache $ItemPaths -Key $AceByGuid.Value[$Guid].Path -Value $Guid -Type $GuidType

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
