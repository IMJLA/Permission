function Expand-ItemPermissionAccountAccessReference {

    param (
        $Reference,
        [Hashtable]$PrincipalByResolvedID,
        [Hashtable]$AceByGUID
    )

    ForEach ($PermissionRef in $Reference) {

        $Account = $PrincipalByResolvedID[$PermissionRef.Account]

        [PSCustomObject]@{
            Account     = $Account
            AccountName = $PermissionRef.Account
            Access      = ForEach ($GuidList in $PermissionRef.AceGUIDs) {
                ForEach ($Guid in $GuidList) {
                    Merge-AceAndPrincipal -ACE $AceByGUID[$Guid] -Principal $Account -PrincipalByResolvedID $PrincipalByResolvedID
                }
            }
            PSTypeName  = 'Permission.ItemPermissionAccountAccess'
        }

    }

}
