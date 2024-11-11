function Find-ResolvedIDsWithAccess {

    param (
        $ItemPath,
        [ref]$AceGUIDsByPath,
        [ref]$ACEsByGUID,
        [ref]$PrincipalsByResolvedID
    )

    $GuidType = [guid]
    $IDsWithAccess = New-PermissionCacheRef -Key ([string]) -Value ([System.Collections.Generic.List[guid]])

    ForEach ($Item in $ItemPath) {

        $Guids = $AceGUIDsByPath.Value[$Item]

        # Not all Paths have ACEs in the cache, so we need to test for null results
        if ($Guids) {

            ForEach ($Guid in $Guids) {

                ForEach ($Ace in $ACEsByGUID.Value[$Guid]) {

                    Add-PermissionCacheItem -Cache $IDsWithAccess -Key $Ace.IdentityReferenceResolved -Value $Guid -Type $GuidType

                    ForEach ($Member in $PrincipalsByResolvedID.Value[$Ace.IdentityReferenceResolved].Members) {

                        Add-PermissionCacheItem -Cache $IDsWithAccess -Key $Member -Value $Guid -Type $GuidType

                    }

                }

            }

        }

    }

    return $IDsWithAccess

}
