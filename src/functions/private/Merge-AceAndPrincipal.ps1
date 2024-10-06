function Merge-AceAndPrincipal {

    param (
        $Principal,
        $ACE,
        $PrincipalByResolvedID
    )

    ForEach ($Member in $Principal.Members) {

        Merge-AceAndPrincipal -ACE $ACE -Principal $PrincipalByResolvedID[$Member] -PrincipalByResolvedID $PrincipalByResolvedID

    }

    $OutputProperties = @{
        PSTypeName  = 'Permission.FlatPermission'
        ItemPath    = $ACE.Path
        AdsiPath    = $Principal.Path
        AccountName = $Principal.ResolvedAccountName
    }

    #ForEach ($Prop in ($ACE | Get-Member -View All -MemberType Property, NoteProperty).Name) {
    ForEach ($Prop in $ACE.PSObject.Properties.GetEnumerator().Name) {
        $OutputProperties[$Prop] = $ACE.$Prop
    }

    #ForEach ($Prop in ($Principal | Get-Member -View All -MemberType Property, NoteProperty).Name) {
    ForEach ($Prop in $Principal.PSObject.Properties.GetEnumerator().Name) {
        $OutputProperties[$Prop] = $Principal.$Prop
    }

    return [pscustomobject]$OutputProperties

}
