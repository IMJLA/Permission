function Expand-AccountPermissionItemAccessReference {

    param (

        $Reference,
        [ref]$AceByGUID,
        [ref]$AclByPath

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
        }

        if ($ACEList -is [System.Collections.IEnumerable]) {
            $FirstACE = $ACEList[0]
        } else {
            $FirstACE = $ACEList
        }

        $ACEProps = $FirstACE.PSObject.Properties.GetEnumerator().Name

    }

    ForEach ($PermissionRef in $Reference) {

        $Item = $AclByPath.Value[$PermissionRef.Path]

        [PSCustomObject]@{
            Access     = ForEach ($GuidList in $PermissionRef.AceGUIDs) {

                ForEach ($Guid in $GuidList) {

                    $ACE = $AceByGUID.Value[$Guid]

                    $OutputProperties = @{
                        Item = $Item
                    }

                    ForEach ($Prop in $ACEProps) {
                        $OutputProperties[$Prop] = $ACE.$Prop
                    }

                    [PSCustomObject]$OutputProperties

                }

            }
            Item       = $Item
            ItemPath   = $PermissionRef.Path
            PSTypeName = 'Permission.AccountPermissionItemAccess'

        }

    }

}
