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

                if ($Ace) {

                    Add-CacheItem -Cache $IDsWithAccess -Key $Ace.IdentityReferenceResolved -Value $Guid -Type ([guid])

                    ForEach ($Member in $PrincipalsByResolvedID[$Ace.IdentityReferenceResolved].Members) {

                        Add-CacheItem -Cache $IDsWithAccess -Key $Member -Value $Guid -Type ([guid])

                    }
                } else {
                    Write-Warning "No ACE found for '$Guid' for '$Item'"
                }

            }

        }

    }

    return $IDsWithAccess

}
