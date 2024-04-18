function Expand-FlatPermissionReference {

    # Expand each Access Control Entry with the Security Principal for the resolved IdentityReference.

    param (

        $SortedPath,
        $PrincipalsByResolvedID,
        $ACEsByGUID,
        $AceGUIDsByPath##,
        ##[hashtable]$ShortNameByID = [hashtable]::Synchronized(@{})

    )

    ForEach ($Item in $SortedPath) {

        $AceGUIDs = $AceGUIDsByPath[$Item]

        if (-not $AceGUIDs) { continue }

        ForEach ($ACE in $ACEsByGUID[$AceGUIDs]) {

            Merge-AceAndPrincipal -ACE $ACE -Principal $PrincipalsByResolvedID[$ACE.IdentityReferenceResolved] -PrincipalByResolvedID $PrincipalsByResolvedID ##-ShortNameByID $ShortNameByID

        }

    }

}
