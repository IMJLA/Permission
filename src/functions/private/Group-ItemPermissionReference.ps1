function Group-ItemPermissionReference {

    param (
        $SortedPath,
        [ref]$AceGUIDsByPath,
        [ref]$ACEsByGUID,
        [ref]$PrincipalsByResolvedID,
        [Hashtable]$Property = @{},
        [string]$Identity
    )

    ForEach ($ItemPath in $SortedPath) {

        $Property['Path'] = $ItemPath
        $IDsWithAccess = Find-ResolvedIDsWithAccess -ItemPath $ItemPath -AceGUIDsByPath $AceGUIDsByPath -ACEsByGUID $ACEsByGUID -PrincipalsByResolvedID $PrincipalsByResolvedID

        if ($Identity) {

            $Property['Access'] = [PSCustomObject]@{
                'Account'  = $Identity
                'AceGUIDs' = $IDsWithAccess.Value[$Identity]
            }

        } else {

            $Property['Access'] = ForEach ($ID in ($IDsWithAccess.Value.Keys | Sort-Object)) {

                [PSCustomObject]@{
                    'Account'  = $ID
                    'AceGUIDs' = $IDsWithAccess.Value[$ID]
                }

            }

        }

        [PSCustomObject]$Property

    }

}
