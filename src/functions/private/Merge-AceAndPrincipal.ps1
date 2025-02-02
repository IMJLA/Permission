function Merge-AceAndPrincipal {

    param (
        $Principal,
        $ACE,
        [ref]$PrincipalByResolvedID
    )

    if (-not $Principal) {
        return
    }

    ForEach ($Member in $Principal.Members) {

        Merge-AceAndPrincipal -ACE $ACE -Principal $PrincipalByResolvedID.Value[$Member] -PrincipalByResolvedID $PrincipalByResolvedID

    }

    $OutputProperties = @{
        PSTypeName  = 'Permission.FlatPermission'
        ItemPath    = $ACE.Path
        AdsiPath    = $Principal.Path
        AccountName = $Principal.ResolvedAccountName
    }

    ForEach ($Prop in $Principal.PSObject.Properties.GetEnumerator().Name) {
        $OutputProperties[$Prop] = $Principal.$Prop
    }

    ForEach ($Prop in $ACE.PSObject.Properties.GetEnumerator().Name) {
        $OutputProperties[$Prop] = $ACE.$Prop
    }

    return [pscustomobject]$OutputProperties

}
