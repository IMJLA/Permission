function Merge-AceAndPrincipal {

    param (
        $Principal,
        $ACE,
        $PrincipalByResolvedID,
        [hashtable]$ShortNameByID = [hashtable]::Synchronized(@{})
    )

    ForEach ($Member in $Principal.Members) {

        Merge-AceAndPrincipal -ACE $ACE -Principal $PrincipalByResolvedID[$Member] -PrincipalByResolvedID $PrincipalByResolvedID -ShortNameByID $ShortNameByID

    }

    $OutputProperties = @{
        PSTypeName  = 'Permission.FlatPermission'
        ItemPath    = $ACE.Path
        AdsiPath    = $Principal.Path
        AccountName = $ShortNameByID[$Principal.ResolvedAccountName]
    }

    ForEach ($Prop in ($ACE | Get-Member -View All -MemberType Property, NoteProperty).Name) {
        $OutputProperties[$Prop] = $ACE.$Prop
    }

    ForEach ($Prop in ($Principal | Get-Member -View All -MemberType Property, NoteProperty).Name) {
        $OutputProperties[$Prop] = $Principal.$Prop
    }

    [pscustomobject]$OutputProperties

}
