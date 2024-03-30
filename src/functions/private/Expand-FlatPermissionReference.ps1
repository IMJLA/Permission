function Expand-FlatPermissionReference {

    # Expand each Access Control Entry with the Security Principal for the resolved IdentityReference.

    param (

        $SortedPath,
        $PrincipalsByResolvedID,
        $ACEsByGUID,
        $AceGUIDsByPath

    )

    ForEach ($Item in $SortedPath) {

        $AceGUIDs = $AceGUIDsByPath[$Item]

        if (-not $AceGUIDs) { continue }

        ForEach ($ACE in $ACEsByGUID[$AceGUIDs]) {

            $Principal = $PrincipalsByResolvedID[$ACE.IdentityReferenceResolved]

            $OutputProperties = @{
                PSTypeName = 'Permission.FlatPermission'
                ItemPath   = $ACE.Path
                AdsiPath   = $Principal.Path
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
