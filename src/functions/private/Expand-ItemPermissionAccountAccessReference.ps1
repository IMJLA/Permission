function Expand-ItemPermissionAccountAccessReference {

    param (
        $Reference,
        [hashtable]$PrincipalByResolvedID,
        [hashtable]$AceByGUID,
        [hashtable]$IdByShortName = [hashtable]::Synchronized(@{})
    )

    ForEach ($PermissionRef in $Reference) {

        [PSCustomObject]@{
            Account     = $PrincipalByResolvedID[$IdByShortName[$PermissionRef.Account]]
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
