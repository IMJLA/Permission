function Expand-ItemPermissionAccountAccessReference {

    param (
        $Reference,
        [Hashtable]$PrincipalByResolvedID,
        [Hashtable]$AceByGUID
    )

    ForEach ($PermissionRef in $Reference) {

        [PSCustomObject]@{
            Account     = $PrincipalByResolvedID[$PermissionRef.Account]
            AccountName = $PermissionRef.Account
            Access      = ForEach ($GuidList in $PermissionRef.AceGUIDs) {
                ForEach ($Guid in $GuidList) {
                    $AceByGUID[$Guid]
                }
            }
            PSTypeName  = 'Permission.ItemPermissionAccountAccess'
        }

    }

}
