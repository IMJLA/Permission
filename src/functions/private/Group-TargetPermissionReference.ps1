function Group-TargetPermissionReference {

    # Expand each Access Control Entry with the Security Principal for the resolved IdentityReference.

    param (

        [hashtable]$TargetPath,
        [hashtable]$Children,
        $PrincipalsByResolvedID,
        $AceGUIDsByResolvedID,
        $ACEsByGUID,
        $AceGUIDsByPath,
        $ACLsByPath,
        [string]$GroupBy

    )

    $CommonParams = @{
        AceGUIDsByPath         = $AceGUIDsByPath
        ACEsByGUID             = $ACEsByGUID
        PrincipalsByResolvedID = $PrincipalsByResolvedID
    }

    switch ($GroupBy) {

        'account' {

            ForEach ($Target in ($TargetPath.Keys | Sort-Object)) {

                $TargetProperties = @{
                    Path = $Target
                }

                $NetworkPaths = $TargetPath[$Target] | Sort-Object

                $TargetProperties['NetworkPaths'] = ForEach ($NetworkPath in $NetworkPaths) {

                    $ItemsForThisNetworkPath = [System.Collections.Generic.List[string]]::new()
                    $ItemsForThisNetworkPath.Add($NetworkPath)
                    $ItemsForThisNetworkPath.AddRange([string[]]$Children[$NetworkPath])
                    $IDsWithAccess = Find-ResolvedIDsWithAccess -ItemPath $ItemsForThisNetworkPath -AceGUIDsByPath $AceGUIDsByPath -ACEsByGUID $ACEsByGUID -PrincipalsByResolvedID $PrincipalsByResolvedID
                    Write-Host "$($IDsWithAccess.Count) IDsWithAccess for '$NetworkPath'"
                    # Prepare a dictionary for quick lookup of ACE GUIDs for this target
                    $AceGuidsForThisNetworkPath = @{}

                    # Enumerate the collection of ACE GUIDs for this target
                    ForEach ($Guid in $AceGUIDsByPath[$ItemsForThisNetworkPath]) {

                        # Check for null (because we send a list into the dictionary for lookup, we receive a null result for paths that do not exist as a key in the dict)
                        if ($Guid) {

                            # Add each GUID to the dictionary for quick lookups
                            $AceGuidsForThisNetworkPath[$Guid] = $true

                        }

                    }
                    Write-Host "$($AceGuidsForThisNetworkPath.Keys.Count) ACEs for '$NetworkPath'"

                    $AceGuidByResolvedIDForThisNetworkPath = @{}

                    ForEach ($ID in $IDsWithAccess.Keys) {

                        $AllGuidsForThisID = $AceGUIDsByResolvedID[$ID]
                        Write-Host "$($AllGuidsForThisID.Count) ACEs for '$ID' out of $($AceGUIDsByResolvedID.Keys.Count) total ACEs"


                        if ($AllGuidsForThisID) {

                            $AceGuidByResolvedIDForThisNetworkPath[$ID] = $AllGuidsForThisID | Where-Object -FilterScript {
                                $AceGuidsForThisNetworkPath[$_]
                            }

                        }

                    }
                    Write-Host "$($AceGuidByResolvedIDForThisNetworkPath.Keys.Count) ACEs by Resolved ID for '$NetworkPath'"

                    [PSCustomObject]@{
                        Path     = $NetworkPath
                        Accounts = Group-AccountPermissionReference -ID $IDsWithAccess.Keys -AceGUIDsByResolvedID $AceGuidByResolvedIDForThisNetworkPath -ACEsByGUID $ACEsByGUID
                    }

                }

                [pscustomobject]$TargetProperties

            }

        }

        'item' {

            ForEach ($Target in ($TargetPath.Keys | Sort-Object)) {

                $TargetProperties = @{
                    Path = $Target
                }

                $NetworkPaths = $TargetPath[$Target] | Sort-Object

                $TargetProperties['NetworkPaths'] = ForEach ($NetworkPath in $NetworkPaths) {

                    $TopLevelItemProperties = @{
                        'Items' = Group-ItemPermissionReference -SortedPath ($Children[$NetworkPath] | Sort-Object) -ACLsByPath $ACLsByPath @CommonParams
                    }

                    Group-ItemPermissionReference -SortedPath $NetworkPath -Property $TopLevelItemProperties -ACLsByPath $ACLsByPath @CommonParams

                }

                [pscustomobject]$TargetProperties

            }

        }

        'none' {

            ForEach ($Target in ($TargetPath.Keys | Sort-Object)) {

                $TargetProperties = @{
                    Path = $Target
                }

                $NetworkPaths = $TargetPath[$Target] | Sort-Object

                $TargetProperties['NetworkPaths'] = ForEach ($NetworkPath in $NetworkPaths) {

                    $ItemsForThisNetworkPath = [System.Collections.Generic.List[string]]::new()
                    $ItemsForThisNetworkPath.Add($NetworkPath)
                    $ItemsForThisNetworkPath.AddRange($Children[$TargetParent])

                    [PSCustomObject]@{
                        Path   = $NetworkPath
                        Access = Expand-FlatPermissionReference -SortedPath $ItemsForThisNetworkPath @CommonParams
                    }

                }

                [pscustomobject]$TargetProperties

            }

        }

        'target' {}

    }

}
