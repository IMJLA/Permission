function Group-ItemPermissionReference {

    param (
        $SortedPath,
        $AceGUIDsByPath,
        $ACEsByGUID,
        $PrincipalsByResolvedID,
        [hashtable]$Property = @{}##,
        ##[hashtable]$IdByShortName = [hashtable]::Synchronized(@{}),
        ##[hashtable]$ShortNameByID = [hashtable]::Synchronized(@{})
    )

    ForEach ($ItemPath in $SortedPath) {

        $Property['Path'] = $ItemPath
        $IDsWithAccess = Find-ResolvedIDsWithAccess -ItemPath $ItemPath -AceGUIDsByPath $AceGUIDsByPath -ACEsByGUID $ACEsByGUID -PrincipalsByResolvedID $PrincipalsByResolvedID

        ##$Property['Access'] = ForEach ($ShortName in ($ShortNameByID[$IDsWithAccess.Keys] | Sort-Object)) {
        $Property['Access'] = ForEach ($ID in ($IDsWithAccess.Keys | Sort-Object)) {
            [PSCustomObject]@{
                ##Account  = $ShortName
                ##AceGUIDs = $IDsWithAccess[$IdByShortName[$ShortName]]
                Account  = $ID
                AceGUIDs = $IDsWithAccess[$ID]
            }
        }

        [PSCustomObject]$Property

    }

}
