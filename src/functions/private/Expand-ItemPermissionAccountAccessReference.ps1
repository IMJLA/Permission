function Expand-ItemPermissionAccountAccessReference {

    param (
        $Reference,
        [ref]$PrincipalByResolvedID,
        [ref]$AceByGUID
    )

    if ($Reference) {

        if ($Reference -is [System.Collections.IEnumerable]) {
            $FirstRef = $Reference[0]
        } else {
            $FirstRef = $Reference
        }

        if ($FirstRef) {

            if ($FirstRef.AceGUIDs -is [System.Collections.IEnumerable]) {
                $FirstACEGuid = $FirstRef.AceGUIDs[0]
            } else {
                $FirstACEGuid = $FirstRef.AceGUIDs
            }

        }

        if ($FirstACEGuid) {
            $ACEList = $AceByGUID.Value[$FirstACEGuid]
            if ($ACEList -is [System.Collections.IEnumerable]) {
                $FirstACE = $ACEList[0]
            } else {
                $FirstACE = $ACEList
            }
            $ACEProps = $FirstACE.PSObject.Properties.GetEnumerator().Name
        } else {
            $ACEProps = @()
        }

    }

    ForEach ($PermissionRef in $Reference) {

        $Account = $PrincipalByResolvedID.Value[$PermissionRef.Account]

        [PSCustomObject]@{
            Account     = $Account
            AccountName = $PermissionRef.Account
            Access      = ForEach ($GuidList in $PermissionRef.AceGUIDs) {

                ForEach ($Guid in $GuidList) {

                    $ACE = $AceByGUID.Value[$Guid]

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
