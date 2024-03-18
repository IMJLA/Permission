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

            Write-Host "Guids Type '$($Guids.GetType())' for '$Item'" -ForegroundColor Yellow
            Write-Host "Guids Count '$($Guids.Count)'" -ForegroundColor Yellow
            Write-Host "Guids Length '$($Guids.Length)'" -ForegroundColor Yellow

            ForEach ($Guid in $Guids) {

                Write-Host "Guid Type '$($Guid.GetType())' for '$Guid'" -ForegroundColor Green
                Write-Host "Guid Count '$($Guid.Count)'" -ForegroundColor Green
                Write-Host "Guid Length '$($Guid.Length)'" -ForegroundColor Green

                $Ace = $ACEsByGUID[$Guid]

                if ($Ace) {
                    Write-Host "ACE found" -ForegroundColor Green

                    Add-CacheItem -Cache $IDsWithAccess -Key $Ace.IdentityReferenceResolved -Value $Guid -Type ([guid])

                    ForEach ($Member in $PrincipalsByResolvedID[$Ace.IdentityReferenceResolved].Members) {

                        Add-CacheItem -Cache $IDsWithAccess -Key $Member -Value $Guid -Type ([guid])

                    }
                } else {
                    Write-Host "No ACE found" -ForegroundColor Cyan
                }

            }

        } else {
            Write-Host "No Guids for '$Item'" -ForegroundColor Yellow
        }

    }

    return $IDsWithAccess

}
