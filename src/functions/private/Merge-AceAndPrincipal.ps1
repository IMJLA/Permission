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

    $AccountName = $ShortNameByID[$Principal.ResolvedAccountName]

    # If the Export-Permission parameters excluded this principal it will not exist in the $ShortNameByID hashtable so we do not want to return this ACE; return nothing instead.
    if (-not $AccountName) { return }

    $OutputProperties = @{
        PSTypeName  = 'Permission.FlatPermission'
        ItemPath    = $ACE.Path
        AdsiPath    = $Principal.Path
        AccountName = $AccountName
    }

    ForEach ($Prop in ($ACE | Get-Member -View All -MemberType Property, NoteProperty).Name) {
        $OutputProperties[$Prop] = $ACE.$Prop
    }

    ForEach ($Prop in ($Principal | Get-Member -View All -MemberType Property, NoteProperty).Name) {
        $OutputProperties[$Prop] = $Principal.$Prop
    }

    return [pscustomobject]$OutputProperties

}
