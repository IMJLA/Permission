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
        $ACLsByPath
    )

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
        $AccountPermissionReferences = Group-AccountPermissionReference @CommonParams -AceGUIDsByResolvedID $AceGUIDsByResolvedID

        # Expand reference GUIDs into their associated Access Control Entries and Security Principals.
        $AccountPermissions = Expand-AccountPermissionReference @CommonParams -Reference $AccountPermissionReferences

    }

    if (
        $HowToSplit['item'] -or
        $GroupBy -eq 'item'
    ) {

        # Group reference GUIDs by the path to their associated item.
        $ItemPermissionReferences = Group-ItemPermissionReference @CommonParams -SortedPath $SortedPaths -AceGUIDsByPath $AceGUIDsByPath -ACLsByPath $ACLsByPath

        # Expand reference GUIDs into their associated Access Control Entries and Security Principals.
        $ItemPermissions = Expand-ItemPermissionReference @CommonParams -Reference $ItemPermissionReferences

    }

    if (
        $HowToSplit['none'] -and
        $GroupBy -eq 'none'
    ) {

        # Expand each Access Control Entry with the Security Principal for the resolved IdentityReference.
        $FlatPermissions = Expand-FlatPermissionReference @CommonParams -SortedPath $SortedPaths -AceGUIDsByPath $AceGUIDsByPath

    }

    return [PSCustomObject]@{
        AccountPermissions = $AccountPermissions
        FlatPermissions    = $FlatPermissions
        ItemPermissions    = $ItemPermissions
        SplitBy            = $HowToSplit
    }

}
