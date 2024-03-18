function Find-ResolvedIDsWithAccess {

    param (
        $ItemPath,
        $AceGUIDsByPath,
        $ACEsByGUID,
        $PrincipalsByResolvedID
    )

    $IDsWithAccess = @{}

    $Guids = $AceGUIDsByPath[$ItemPath]
    Write-Host "Guids Type '$($Guids.GetType())'" -ForegroundColor Yellow
    Write-Host "Guids Count '$($Guids.Count)'" -ForegroundColor Yellow
    Write-Host "Guids Length '$($Guids.Length)'" -ForegroundColor Yellow

    ForEach ($Guid in $Guids) {

        Write-Host "Guid Type '$($Guid.GetType())'" -ForegroundColor Green
        Write-Host "Guid Count '$($Guid.Count)'" -ForegroundColor Green
        Write-Host "Guid Length '$($Guid.Length)'" -ForegroundColor Green

        $Ace = $ACEsByGUID[$Guid]

        if ($Ace) {
            Write-Host "ACE found for '$Guid' for '$ItemPath'" -ForegroundColor Green
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
