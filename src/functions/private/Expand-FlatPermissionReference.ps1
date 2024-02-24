function Expand-FlatPermissionReference {

    # Expand each Access Control Entry with the Security Principal for the resolved IdentityReference.

    param (

        $SortedPaths,
        $PrincipalsByResolvedID,
        $ACEsByGUID,
        $AceGUIDsByPath

    )

    ForEach ($Item in $SortedPaths) {

        ForEach ($ACE in $ACEsByGUID[$AceGUIDsByPath[$Item]]) {

            $Principal = $PrincipalsByResolvedID[$ACE.IdentityReferenceResolved]

            $OutputProperties = @{
                PSTypeName = 'Permission.FlatPermission'
            }

            ForEach ($Prop in ($ACE | Get-Member -View All -MemberType Property, NoteProperty).Name) {
                $OutputProperties[$Prop] = $ACE.$Prop
            }

            ForEach ($Prop in ($Principal | Get-Member -View All -MemberType Property, NoteProperty).Name) {
                $OutputProperties[$Prop] = $Principal.$Prop
            }

            [pscustomobject]$OutputProperties

        }

    }

}
