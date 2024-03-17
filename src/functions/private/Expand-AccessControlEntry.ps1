function Expand-AccessControlEntry {

    param (
        $AccessControlEntry,
        $PrincipalsByResolvedID
    )

    ForEach ($ACE in $AccessControlEntry) {

        #$Principal = $PrincipalsByResolvedID[$ACE.IdentityReferenceResolved]

        $OutputProperties = @{
            PSTypeName = 'Permission.ItemPermissionAccountAccess'
            ItemPath   = $ACE.Path
            Account    = $PrincipalsByResolvedID[$ACE.IdentityReferenceResolved]
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
