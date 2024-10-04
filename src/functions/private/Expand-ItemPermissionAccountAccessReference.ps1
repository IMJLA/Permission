function Expand-ItemPermissionAccountAccessReference {

    param (
        $Reference,
        [Hashtable]$PrincipalByResolvedID,
        [Hashtable]$AceByGUID
    )

    $ACEProps = $AceByGUID[@(@($Reference)[0].AceGUIDs)[0]].PSObject.Properties.GetEnumerator().Name

    ForEach ($PermissionRef in $Reference) {

        $Account = $PrincipalByResolvedID[$PermissionRef.Account]

        [PSCustomObject]@{
            Account     = $Account
            AccountName = $PermissionRef.Account
            Access      = ForEach ($GuidList in $PermissionRef.AceGUIDs) {

                ForEach ($Guid in $GuidList) {

                    $OutputProperties = @{
                        Account = $Account
                    }

                    ForEach ($Prop in $ACEProps) {
                        $OutputProperties[$Prop] = $ACE.$Prop
                    }

                    [pscustomobject]$OutputProperties

                }
            }
            PSTypeName  = 'Permission.ItemPermissionAccountAccess'
        }

    }

}
