function Expand-FlatPermissionReference {

    # Expand each Access Control Entry with the Security Principal for the resolved IdentityReference.

    param (

        $SortedPath,
        [ref]$PrincipalsByResolvedID,
        [ref]$ACEsByGUID,
        [ref]$AceGUIDsByPath

    )

    ForEach ($Item in $SortedPath) {

        $AceGUIDs = $AceGUIDsByPath.Value[$Item]

        if (-not $AceGUIDs) { continue }

        ForEach ($ACE in $ACEsByGUID.Value[$AceGUIDs]) {

            Merge-AceAndPrincipal -ACE $ACE -Principal $PrincipalsByResolvedID.Value[$ACE.IdentityReferenceResolved] -PrincipalByResolvedID $PrincipalsByResolvedID

        }

    }

}
