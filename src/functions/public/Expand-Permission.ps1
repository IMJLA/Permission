function Expand-Permission {

    # TODO: If SplitBy account or item, each file needs to include inherited permissions (with default $SplitBy = 'none', the parent folder's inherited permissions are already included)

    param (

        <#
        How to split up the exported files:
            none    generate 1 report file with all permissions
            target  generate 1 report file per target (default)
            item    generate 1 report file per item
            account generate 1 report file per account
            all     generate 1 report file per target and 1 file per item and 1 file per account and 1 file with all permissions.
        #>
        [ValidateSet('account', 'item', 'none', 'target')]
        [string[]]$SplitBy = 'target',

        <#
        How to group the permissions in the output stream and within each exported file

            SplitBy	GroupBy
            none	none	$FlatPermissions all in 1 file
            none	account	$AccountPermissions all in 1 file
            none	item	$ItemPermissions all in 1 file

            account	none	1 file per item in $AccountPermissions.  In each file, $_.Access | sort path
            account	account	(same as -SplitBy account -GroupBy none)
            account	item	1 file per item in $AccountPermissions.  In each file, $_.Access | group item | sort name

            item	none	1 file per item in $ItemPermissions.  In each file, $_.Access | sort account
            item	account	1 file per item in $ItemPermissions.  In each file, $_.Access | group account | sort name
            item	item	(same as -SplitBy item -GroupBy none)

            target	none	1 file per $TargetPath.  In each file, sort ACEs by item path then account name
            target	account	1 file per $TargetPath.  In each file, group ACEs by account and sort by account name
            target	item	1 file per $TargetPath.  In each file, group ACEs by item and sort by item path
            target  target  (same as -SplitBy target -GroupBy none)
        #>
        [ValidateSet('account', 'item', 'none', 'target')]
        [string]$GroupBy = 'item',

        [Hashtable]$Children,

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $Log = @{ 'Cache' = $Cache }

    $Progress = @{
        Activity = 'Expand-Permission'
    }
    [int]$ProgressParentId = $Cache.Value['ProgressParentId'].Value
    if ($ProgressParentId ) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }

    Write-Progress @Progress -Status '0% : Prepare to group permission references, then expand them into objects' -CurrentOperation 'Resolve-SplitByParameter' -PercentComplete 0
    Write-LogMsg @Log -Text "Resolve-SplitByParameter -SplitBy $SplitBy"
    $HowToSplit = Resolve-SplitByParameter -SplitBy $SplitBy
    Write-LogMsg @Log -Text "`$SortedPaths = `$AceGuidByPath.Keys | Sort-Object"
    $AceGuidByPath = $Cache.Value['AceGuidByPath']
    $SortedPaths = $AceGuidByPath.Value.Keys | Sort-Object
    $AceGuidByID = $Cache.Value['AceGuidByID']
    $ACEsByGUID = $Cache.Value['AceByGUID']
    $PrincipalsByResolvedID = $Cache.Value['PrincipalByID']
    $ACLsByPath = $Cache.Value['AclByPath']
    $TargetPath = $Cache.Value['ParentByTargetPath']

    $CommonParams = @{
        ACEsByGUID             = $ACEsByGUID
        PrincipalsByResolvedID = $PrincipalsByResolvedID
    }

    if (
        $HowToSplit['account']
    ) {

        Write-Progress @Progress -Status '13% : Group permission references by account' -CurrentOperation 'Resolve-SplitByParameter' -PercentComplete 17

        # Group reference GUIDs by the name of their associated account.
        Write-LogMsg @Log -Text '$AccountPermissionReferences = Group-AccountPermissionReference -ID $PrincipalsByResolvedID.Keys -AceGuidByID $AceGuidByID -AceByGuid $ACEsByGUID'
        $AccountPermissionReferences = Group-AccountPermissionReference -ID $PrincipalsByResolvedID.Value.Keys -AceGuidByID $AceGuidByID -AceByGuid $ACEsByGUID

        Write-Progress @Progress -Status '25% : Expand account permissions into objects' -CurrentOperation 'Resolve-SplitByParameter' -PercentComplete 33

        # Expand reference GUIDs into their associated Access Control Entries and Security Principals.
        Write-LogMsg @Log -Text '$AccountPermissions = Expand-AccountPermissionReference -Reference $AccountPermissionReferences @CommonParams'
        $AccountPermissions = Expand-AccountPermissionReference -Reference $AccountPermissionReferences @CommonParams

    }

    if (
        $HowToSplit['item']
    ) {

        # Group reference GUIDs by the path to their associated item.
        Write-Progress @Progress -Status '38% : Group permission references by item' -CurrentOperation 'Group-ItemPermissionReference' -PercentComplete 50
        Write-LogMsg @Log -Text '$ItemPermissionReferences = Group-ItemPermissionReference @CommonParams -SortedPath $SortedPaths -AceGUIDsByPath $AceGuidByPath -ACLsByPath $ACLsByPath'
        $ItemPermissionReferences = Group-ItemPermissionReference -SortedPath $SortedPaths -AceGUIDsByPath $AceGuidByPath -ACLsByPath $ACLsByPath @CommonParams


        # Expand reference GUIDs into their associated Access Control Entries and Security Principals.
        Write-Progress @Progress -Status '50% : Expand item permissions into objects' -CurrentOperation 'Expand-ItemPermissionReference' -PercentComplete 67
        Write-LogMsg @Log -Text '$ItemPermissions = Expand-ItemPermissionReference -Reference $ItemPermissionReferences -ACLsByPath $ACLsByPath @CommonParams'
        $ItemPermissions = Expand-ItemPermissionReference -Reference $ItemPermissionReferences -ACLsByPath $ACLsByPath @CommonParams

    }

    if (
        $HowToSplit['none']
    ) {

        # Expand each Access Control Entry with the Security Principal for the resolved IdentityReference.
        Write-Progress @Progress -Status '63% : Expand flat permissions into objects' -CurrentOperation 'Expand-FlatPermissionReference' -PercentComplete 83
        Write-LogMsg @Log -Text '$FlatPermissions = Expand-FlatPermissionReference -SortedPath $SortedPaths -AceGUIDsByPath $AceGuidByPath @CommonParams'
        $FlatPermissions = Expand-FlatPermissionReference -SortedPath $SortedPaths -AceGUIDsByPath $AceGuidByPath @CommonParams

    }

    if (
        $HowToSplit['target']
    ) {

        # Group reference GUIDs by their associated TargetPath.
        Write-Progress @Progress -Status '75% : Group permission references by target' -CurrentOperation 'Group-TargetPermissionReference' -PercentComplete 17
        Write-LogMsg @Log -Text '$TargetPermissionReferences = Group-TargetPermissionReference -TargetPath $TargetPath -Children $Children -AceGUIDsByPath $AceGuidByPath -ACLsByPath $ACLsByPath -GroupBy $GroupBy -AceGuidByID $AceGuidByID @CommonParams'
        $TargetPermissionReferences = Group-TargetPermissionReference -TargetPath $TargetPath -Children $Children -AceGUIDsByPath $AceGuidByPath -ACLsByPath $ACLsByPath -GroupBy $GroupBy -AceGuidByID $AceGuidByID @CommonParams


        # Expand reference GUIDs into their associated Access Control Entries and Security Principals.
        Write-Progress @Progress -Status '88% : Expand item permissions into objects' -CurrentOperation 'Expand-TargetPermissionReference' -PercentComplete 67
        Write-LogMsg @Log -Text '$TargetPermissions = Expand-TargetPermissionReference -Reference $TargetPermissionReferences -GroupBy $GroupBy -ACLsByPath $ACLsByPath @CommonParams'
        $TargetPermissions = Expand-TargetPermissionReference -Reference $TargetPermissionReferences -GroupBy $GroupBy -ACLsByPath $ACLsByPath -AceGuidByPath $AceGuidByPath @CommonParams

    }

    Write-Progress @Progress -Completed

    return [PSCustomObject]@{
        AccountPermissions = $AccountPermissions
        FlatPermissions    = $FlatPermissions
        ItemPermissions    = $ItemPermissions
        TargetPermissions  = $TargetPermissions
        SplitBy            = $HowToSplit
    }

}
