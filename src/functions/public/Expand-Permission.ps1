function Expand-Permission {

    # TODO: If SplitBy account or item, each file needs to include inherited permissions (with default $SplitBy = 'none', the parent folder's inherited permissions are already included)

    param (
        $SplitBy,
        $GroupBy,
        [Hashtable]$TargetPath,
        [Hashtable]$Children,

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [String]$ThisHostName = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [String]$WhoAmI = (whoami.EXE),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [String]$DebugOutputStream = 'Debug',

        # ID of the parent progress bar under which to show progress
        [int]$ProgressParentId,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $Log = @{ ThisHostname = $ThisHostname ; Type = $DebugOutputStream ; Buffer = $Cache.Value['LogBuffer'] ; WhoAmI = $WhoAmI }

    $Progress = @{
        Activity = 'Expand-Permission'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }

    Write-Progress @Progress -Status '0% : Group permission references, then expand them into objects' -CurrentOperation 'Resolve-SplitByParameter' -PercentComplete 0
    Write-LogMsg @Log -Text "Resolve-SplitByParameter -SplitBy $SplitBy"
    $HowToSplit = Resolve-SplitByParameter -SplitBy $SplitBy
    Write-LogMsg @Log -Text "`$SortedPaths = `$AceGuidByPath.Keys | Sort-Object"
    $SortedPaths = $Cache.Value['AceGuidByPath'].Value.Keys | Sort-Object
    $AceGuidByPath = $Cache.Value['AceGuidByPath']
    $AceGuidByID = $Cache.Value['AceGuidByID']
    $ACEsByGUID = $Cache.Value['AceByGUID']
    $PrincipalsByResolvedID = $Cache.Value['PrincipalByID']
    $ACLsByPath = $Cache.Value['AclByPath']

    $CommonParams = @{
        ACEsByGUID             = $ACEsByGUID
        PrincipalsByResolvedID = $PrincipalsByResolvedID
    }

    if (
        $HowToSplit['account']
    ) {

        # Group reference GUIDs by the name of their associated account.
        Write-LogMsg @Log -Text '$AccountPermissionReferences = Group-AccountPermissionReference -ID $PrincipalsByResolvedID.Keys -AceGuidByID $AceGuidByID -AceByGuid $ACEsByGUID'
        $AccountPermissionReferences = Group-AccountPermissionReference -ID $PrincipalsByResolvedID.Value.Keys -AceGuidByID $AceGuidByID -AceByGuid $ACEsByGUID

        # Expand reference GUIDs into their associated Access Control Entries and Security Principals.
        Write-LogMsg @Log -Text '$AccountPermissions = Expand-AccountPermissionReference -Reference $AccountPermissionReferences @CommonParams'
        $AccountPermissions = Expand-AccountPermissionReference -Reference $AccountPermissionReferences @CommonParams

    }

    if (
        $HowToSplit['item']
    ) {

        # Group reference GUIDs by the path to their associated item.
        Write-LogMsg @Log -Text '$ItemPermissionReferences = Group-ItemPermissionReference @CommonParams -SortedPath $SortedPaths -AceGUIDsByPath $AceGuidByPath -ACLsByPath $ACLsByPath'
        $ItemPermissionReferences = Group-ItemPermissionReference -SortedPath $SortedPaths -AceGUIDsByPath $AceGuidByPath -ACLsByPath $ACLsByPath @CommonParams

        # Expand reference GUIDs into their associated Access Control Entries and Security Principals.
        Write-LogMsg @Log -Text '$ItemPermissions = Expand-ItemPermissionReference -Reference $ItemPermissionReferences -ACLsByPath $ACLsByPath @CommonParams'
        $ItemPermissions = Expand-ItemPermissionReference -Reference $ItemPermissionReferences -ACLsByPath $ACLsByPath @CommonParams

    }

    if (
        $HowToSplit['none']
    ) {

        # Expand each Access Control Entry with the Security Principal for the resolved IdentityReference.
        Write-LogMsg @Log -Text '$FlatPermissions = Expand-FlatPermissionReference -SortedPath $SortedPaths -AceGUIDsByPath $AceGuidByPath @CommonParams'
        $FlatPermissions = Expand-FlatPermissionReference -SortedPath $SortedPaths -AceGUIDsByPath $AceGuidByPath @CommonParams

    }

    if (
        $HowToSplit['target']
    ) {

        # Group reference GUIDs by their associated TargetPath.
        Write-LogMsg @Log -Text '$TargetPermissionReferences = Group-TargetPermissionReference -TargetPath $TargetPath -Children $Children -AceGUIDsByPath $AceGuidByPath -ACLsByPath $ACLsByPath -GroupBy $GroupBy -AceGuidByID $AceGuidByID @CommonParams'
        $TargetPermissionReferences = Group-TargetPermissionReference -TargetPath $TargetPath -Children $Children -AceGUIDsByPath $AceGuidByPath -ACLsByPath $ACLsByPath -GroupBy $GroupBy -AceGuidByID $AceGuidByID @CommonParams

        # Expand reference GUIDs into their associated Access Control Entries and Security Principals.
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
