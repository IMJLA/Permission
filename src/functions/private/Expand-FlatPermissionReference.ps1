function Expand-FlatPermissionReference {

    # Expand each Access Control Entry with the Security Principal for the resolved IdentityReference.

    param (

        $SortedPath,
        [ref]$PrincipalsByResolvedID,
        [ref]$ACEsByGUID,
        [ref]$AceGUIDsByPath,
        [string]$Account

    )

    ForEach ($Item in $SortedPath) {

        $AceGUIDs = $AceGUIDsByPath.Value[$Item]

        ForEach ($Guid in $AceGUIDs) {

            ForEach ($ACE in $ACEsByGUID.Value[$Guid]) {

                if ($Account -eq $ACE.IdentityReferenceResolved) {

                    Merge-AceAndPrincipal -ACE $ACE -Principal $PrincipalsByResolvedID.Value[$ACE.IdentityReferenceResolved] -PrincipalByResolvedID $PrincipalsByResolvedID

                }

            }

        }

    }

}
