function Expand-Permission {

    # TODO: If SplitBy account or item, each file needs to include inherited permissions (with default $SplitBy = 'none', the parent folder's inherited permissions are already included)

    param (
        $SortedPaths,
        $SplitBy,
        $GroupBy,
        $AceGUIDsByPath,
        $AceGUIDsByResolvedID,
        $ACEsByGUID,
        $PrincipalsByResolvedID,
        $ACLsByPath,
        [hashtable]$TargetPath,
        [hashtable]$Children,

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId

    )

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    Write-LogMsg -Text "Resolve-SplitByParameter -SplitBy $SplitBy" @LogParams
    $HowToSplit = Resolve-SplitByParameter -SplitBy $SplitBy

    $CommonParams = @{
        ACEsByGUID             = $ACEsByGUID
        PrincipalsByResolvedID = $PrincipalsByResolvedID
    }

    if (
        $HowToSplit['account'] -or
        $GroupBy -eq 'account'
    ) {

        # Group reference GUIDs by the name of their associated account.
        Write-LogMsg -Text '$AccountPermissionReferences = Group-AccountPermissionReference -ID $PrincipalsByResolvedID.Keys -AceGuidByID $AceGUIDsByResolvedID -AceByGuid $ACEsByGUID' @LogParams
        $AccountPermissionReferences = Group-AccountPermissionReference -ID $PrincipalsByResolvedID.Keys -AceGuidByID $AceGUIDsByResolvedID -AceByGuid $ACEsByGUID

        # Expand reference GUIDs into their associated Access Control Entries and Security Principals.
        Write-LogMsg -Text '$AccountPermissions = Expand-AccountPermissionReference -Reference $AccountPermissionReferences @CommonParams' @LogParams
        $AccountPermissions = Expand-AccountPermissionReference -Reference $AccountPermissionReferences @CommonParams

    }

    if (
        $HowToSplit['item'] -or
        $GroupBy -eq 'item'
    ) {

        # Group reference GUIDs by the path to their associated item.
        Write-LogMsg -Text '$ItemPermissionReferences = Group-ItemPermissionReference @CommonParams -SortedPath $SortedPaths -AceGUIDsByPath $AceGUIDsByPath -ACLsByPath $ACLsByPath' @LogParams
        $ItemPermissionReferences = Group-ItemPermissionReference @CommonParams -SortedPath $SortedPaths -AceGUIDsByPath $AceGUIDsByPath -ACLsByPath $ACLsByPath

        # Expand reference GUIDs into their associated Access Control Entries and Security Principals.
        Write-LogMsg -Text '$ItemPermissions = Expand-ItemPermissionReference -Reference $ItemPermissionReferences -ACLsByPath $ACLsByPath @CommonParams' @LogParams
        $ItemPermissions = Expand-ItemPermissionReference -Reference $ItemPermissionReferences -ACLsByPath $ACLsByPath @CommonParams

    }

    if (
        $HowToSplit['none']
    ) {

        # Expand each Access Control Entry with the Security Principal for the resolved IdentityReference.
        Write-LogMsg -Text '$FlatPermissions = Expand-FlatPermissionReference -SortedPath $SortedPaths -AceGUIDsByPath $AceGUIDsByPath @CommonParams' @LogParams
        $FlatPermissions = Expand-FlatPermissionReference -SortedPath $SortedPaths -AceGUIDsByPath $AceGUIDsByPath @CommonParams

    }

    if (
        $HowToSplit['target'] -or
        $GroupBy -eq 'target'
    ) {

        # Group reference GUIDs by their associated TargetPath.
        Write-LogMsg -Text '$TargetPermissionReferences = Group-TargetPermissionReference -TargetPath $TargetPath -Children $Children -AceGUIDsByPath $AceGUIDsByPath -ACLsByPath $ACLsByPath -GroupBy $GroupBy -AceGUIDsByResolvedID $AceGUIDsByResolvedID @CommonParams' @LogParams
        $TargetPermissionReferences = Group-TargetPermissionReference -TargetPath $TargetPath -Children $Children -AceGUIDsByPath $AceGUIDsByPath -ACLsByPath $ACLsByPath -GroupBy $GroupBy -AceGUIDsByResolvedID $AceGUIDsByResolvedID @CommonParams

        # Expand reference GUIDs into their associated Access Control Entries and Security Principals.
        Write-LogMsg -Text '$TargetPermissions = Expand-TargetPermissionReference -Reference $TargetPermissionReferences -GroupBy $GroupBy -ACLsByPath $ACLsByPath @CommonParams' @LogParams
        $TargetPermissions = Expand-TargetPermissionReference -Reference $TargetPermissionReferences -GroupBy $GroupBy -ACLsByPath $ACLsByPath @CommonParams

    }

    return [PSCustomObject]@{
        AccountPermissions = $AccountPermissions
        FlatPermissions    = $FlatPermissions
        ItemPermissions    = $ItemPermissions
        TargetPermissions  = $TargetPermissions
        SplitBy            = $HowToSplit
    }

}
