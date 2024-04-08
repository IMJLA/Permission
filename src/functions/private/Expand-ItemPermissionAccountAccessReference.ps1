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
            Access      = $AceByGUID[$PermissionRef.AceGUIDs]
            PSTypeName  = 'Permission.ItemPermissionAccountAccess'
        }

    }

}
