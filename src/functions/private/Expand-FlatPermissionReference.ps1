function Expand-FlatPermissionReference {

    # Expand each Access Control Entry with the Security Principal for the resolved IdentityReference.

    param (

        $SortedPath,
        [string]$Identity,
        [ref]$PrincipalsByResolvedID,
        [ref]$ACEsByGUID,
        [ref]$AceGUIDsByPath

    )

    ForEach ($Item in $SortedPath) {

        $AceGUIDs = $AceGUIDsByPath.Value[$Item]

        ForEach ($Guid in $AceGUIDs) {

            ForEach ($ACE in $ACEsByGUID.Value[$Guid]) {

                if ($Identity) {
                    $Principal = $PrincipalsByResolvedID.Value[$Identity]
                } else {
                    $Principal = $PrincipalsByResolvedID.Value[$ACE.IdentityReferenceResolved]
                }

                Merge-AceAndPrincipal -ACE $ACE -Principal $Principal -PrincipalByResolvedID $PrincipalsByResolvedID

            }

        }

    }

}
