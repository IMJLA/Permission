function Group-AccountPermissionReference {

    param (
        $ID,
        [hashtable]$AceGUIDsByResolvedID,
        [hashtable]$ACEsByGUID
    )

    ForEach ($Identity in ($ID | Sort-Object)) {

        $IdentityString = [string]$Identity
        $ItemPaths = @{}
        if ($AceGUIDsByResolvedID[$IdentityString].Count -eq 0) {
            Write-Host "0 ACEs for '$Identity' which is a $($IdentityString.GetType().FullName)"
            Write-Host "Available keys are: $($AceGUIDsByResolvedID.Keys -join ',')"
            Write-Host "First key is a: $($AceGUIDsByResolvedID.Keys[0].GetType().FullName)"
        }
        ForEach ($Guid in $AceGUIDsByResolvedID[$IdenIdentityStringtity]) {

            $Ace = $ACEsByGUID[$Guid]
            Add-CacheItem -Cache $ItemPaths -Key $Ace.Path -Value $Guid -Type ([guid])

        }

        [PSCustomObject]@{
            Account = $IdentityString
            Access  = ForEach ($Item in ($ItemPaths.Keys | Sort-Object)) {

                [PSCustomObject]@{
                    Path     = $Item
                    AceGUIDs = $ItemPaths[$Item]
                }

            }

        }

    }

}
