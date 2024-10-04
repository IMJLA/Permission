function Expand-ItemPermissionAccountAccessReference {

    param (
        $Reference,
        [Hashtable]$PrincipalByResolvedID,
        [Hashtable]$AceByGUID
    )

    $FirstRef = @($Reference)[0]
    $FirstAce = @($FirstRef.AceGUIDs)[0]
    if (-not $FirstAce) { pause }
    $ACEProps = $AceByGUID[$FirstAce].PSObject.Properties.GetEnumerator().Name

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
