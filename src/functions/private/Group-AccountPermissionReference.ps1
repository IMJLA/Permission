function Group-AccountPermissionReference {

    param (
        $ID,
        [hashtable]$AceGUIDsByResolvedID,
        [hashtable]$ACEsByGUID
    )

    ForEach ($Identity in ($ID | Sort-Object)) {

        $ItemPaths = @{}
        if ($AceGUIDsByResolvedID[$Identity].Count -eq 0) {
            Write-Host "0 ACEs for '$Identity' which is a $($Identity.GetType().FullName)"
            Write-Host "Available keys are: $($AceGUIDsByResolvedID.Keys -join ',')"
            $FirstKey = @($AceGUIDsByResolvedID.Keys)[0]
            Write-Host "First key '$FirstKey' is a: $($FirstKey.GetType().FullName)"
        }
        ForEach ($Guid in $AceGUIDsByResolvedID[$Identity]) {

            $Ace = $ACEsByGUID[$Guid]
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
