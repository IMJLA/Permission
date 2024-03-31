function Merge-AceAndPrincipal {

    param ($Principal, $ACE, $PrincipalsByResolvedID)

    ForEach ($Member in $Principal.Members) {

        Merge-AceAndPrincipal -ACE $ACE -Principal $PrincipalsByResolvedID[$Member] -PrincipalsByResolvedID $PrincipalsByResolvedID

    }

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
