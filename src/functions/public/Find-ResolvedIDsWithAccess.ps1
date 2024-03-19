function Find-ResolvedIDsWithAccess {

    param (
        $ItemPath,
        $AceGUIDsByPath,
        $ACEsByGUID,
        $PrincipalsByResolvedID
    )

    $IDsWithAccess = @{}

    ForEach ($Item in $ItemPath) {

        $Guids = $AceGUIDsByPath[$Item]

        if ($Guids) {

            ForEach ($Guid in $Guids) {

                $Ace = $ACEsByGUID[$Guid]

                Add-CacheItem -Cache $IDsWithAccess -Key $Ace.IdentityReferenceResolved -Value $Guid -Type ([guid])

                ForEach ($Member in $PrincipalsByResolvedID[$Ace.IdentityReferenceResolved].Members) {

                    Add-CacheItem -Cache $IDsWithAccess -Key $Member -Value $Guid -Type ([guid])

                }

            }

        }

    }

    return $IDsWithAccess

}
