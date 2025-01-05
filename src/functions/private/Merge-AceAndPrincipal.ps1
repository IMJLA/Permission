function Merge-AceAndPrincipal {

    param (
        $Principal,
        $ACE,
        [ref]$PrincipalByResolvedID,
        [switch]$NoMembers
    )

    if (-not $NoMembers) {

        ForEach ($Member in $Principal.Members) {

            Merge-AceAndPrincipal -ACE $ACE -Principal $PrincipalByResolvedID.Value[$Member] -PrincipalByResolvedID $PrincipalByResolvedID

        }

    }

    $OutputProperties = @{
        PSTypeName  = 'Permission.FlatPermission'
        ItemPath    = $ACE.Path
        AdsiPath    = $Principal.Path
        AccountName = $Principal.ResolvedAccountName
    }

    ForEach ($Prop in $ACE.PSObject.Properties.GetEnumerator().Name) {
        $OutputProperties[$Prop] = $ACE.$Prop
    }

    ForEach ($Prop in $Principal.PSObject.Properties.GetEnumerator().Name) {
        $OutputProperties[$Prop] = $Principal.$Prop
    }

    return [pscustomobject]$OutputProperties

}
