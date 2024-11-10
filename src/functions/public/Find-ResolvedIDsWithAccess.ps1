function Find-ResolvedIDsWithAccess {

    param (
        $ItemPath,
        [ref]$AceGUIDsByPath,
        [ref]$ACEsByGUID,
        [ref]$PrincipalsByResolvedID
    )

    $IDsWithAccess = @{}

    ForEach ($Item in $ItemPath) {

        $Guids = $AceGUIDsByPath.Value[$Item]

        # Not all Paths have ACEs in the cache, so we need to test for null results
        if ($Guids) {

            ForEach ($Guid in $Guids) {

                ForEach ($Ace in $ACEsByGUID.Value[$Guid]) {

                    Add-CacheItem -Cache $IDsWithAccess -Key $Ace.IdentityReferenceResolved -Value $Guid -Type ([guid])

                    ForEach ($Member in $PrincipalsByResolvedID.Value[$Ace.IdentityReferenceResolved].Members) {

                        Add-CacheItem -Cache $IDsWithAccess -Key $Member -Value $Guid -Type ([guid])

                    }

                }

            }

        }

    }

    return $IDsWithAccess

}
