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

        ForEach ($Guid in $AceGUIDs) {

            $ACE = $ACEsByGUID.Value[$Guid]

            Merge-AceAndPrincipal -ACE $ACE -Principal $PrincipalsByResolvedID.Value[$ACE.IdentityReferenceResolved] -PrincipalByResolvedID $PrincipalsByResolvedID

        }

    }

}
