function Group-AccountPermissionReference {

    param (
        $ID,
        [hashtable]$AceGuidByID,
        [hashtable]$AceByGuid
    )

    ForEach ($Identity in ($ID | Sort-Object)) {

        if ($AceGuidByID[$Identity].Count -eq 0) {
            Write-Host "0 ACEs for '$Identity' which is a $($Identity.GetType().FullName)"
            $Joined = ($AceGuidByID.Keys | Sort-Object) -join "`r`n"
            Write-Host "The $($AceGuidByID.Keys.Count) available keys are: $Joined"
            $FirstKey = @($AceGuidByID.Keys)[0]
            Write-Host "First key '$FirstKey' is a: $($FirstKey.GetType().FullName)"
        }

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
