function Find-ResolvedIDsWithAccess {

    param (
        $ItemPath,
        $AceGUIDsByPath,
        $ACEsByGUID,
        $PrincipalsByResolvedID
    )

    $IDsWithAccess = @{}

    ForEach ($Guid in [guid[]]$AceGUIDsByPath[$ItemPath]) {

        $Ace = $ACEsByGUID[$Guid]
        if ($Ace) {
            Write-Host "ACE found for '$Guid' for '$ItemPath'" -ForegroundColor Cyan
        } else {
            Write-Host "No ACE found for '$Guid' for '$ItemPath'" -ForegroundColor Cyan
        }

        Add-CacheItem -Cache $IDsWithAccess -Key $Ace.IdentityReferenceResolved -Value $Guid -Type ([guid])

        ForEach ($Member in $PrincipalsByResolvedID[$Ace.IdentityReferenceResolved].Members) {

            Add-CacheItem -Cache $IDsWithAccess -Key $Member -Value $Guid -Type ([guid])

        }
    }

    return $IDsWithAccess

}
