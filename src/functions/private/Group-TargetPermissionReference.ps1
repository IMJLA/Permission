function Group-TargetPermissionReference {

    # Expand each Access Control Entry with the Security Principal for the resolved IdentityReference.

    param (

        [ref]$TargetPath,
        [Hashtable]$Children,
        [ref]$PrincipalsByResolvedID,
        [ref]$AceGuidByID,
        [ref]$ACEsByGUID,
        [ref]$AceGUIDsByPath,
        [ref]$ACLsByPath,

        # How to group the permissions in the output stream and within each exported file
        [ValidateSet('account', 'item', 'none', 'target')]
        [String]$GroupBy = 'item'

    )

    $CommonParams = @{
        AceGUIDsByPath         = $AceGUIDsByPath
        ACEsByGUID             = $ACEsByGUID
        PrincipalsByResolvedID = $PrincipalsByResolvedID
    }

    switch ($GroupBy) {

        'account' {

            ForEach ($Target in ($TargetPath.Value.Keys | Sort-Object)) {

                $TargetProperties = @{
                    Path = $Target
                }

                $NetworkPaths = $TargetPath.Value[$Target] | Sort-Object

                $TargetProperties['NetworkPaths'] = ForEach ($NetworkPath in $NetworkPaths) {

                    $ItemsForThisNetworkPath = [System.Collections.Generic.List[String]]::new()
                    $ItemsForThisNetworkPath.Add($NetworkPath)
                    $ItemsForThisNetworkPath.AddRange([string[]]$Children[$NetworkPath])
                    $IDsWithAccess = Find-ResolvedIDsWithAccess -ItemPath $ItemsForThisNetworkPath @CommonParams

                    # Prepare a dictionary for quick lookup of ACE GUIDs for this target
                    $AceGuidsForThisNetworkPath = @{}

                    # Enumerate the collection of ACE GUIDs for this target
                    ForEach ($Item in $ItemsForThisNetworkPath) {

                        ForEach ($Guid in $AceGUIDsByPath.Value[$Item]) {

                            # Check for null (because we send a list into the dictionary for lookup, we receive a null result for paths that do not exist as a key in the dict)
                            if ($Guid) {

                                # The returned dictionary value is a lists of guids, so we need to enumerate the list
                                ForEach ($ListItem in $Guid) {

                                    # Add each GUID to the dictionary for quick lookups
                                    $AceGuidsForThisNetworkPath[$ListItem] = $true

                                }

                            }

                        }

                    }

                    $AceGuidByIDForThisNetworkPath = @{}

                    ForEach ($ID in $IDsWithAccess.Value.Keys) {

                        $GuidsForThisIDAndNetworkPath = [System.Collections.Generic.List[guid]]::new()

                        ForEach ($Guid in $AceGuidByID.Value[$ID]) {

                            $AceContainsThisID = $AceGuidsForThisNetworkPath[$Guid]

                            if ($AceContainsThisID) {
                                $GuidsForThisIDAndNetworkPath.Add($Guid)
                            }

                        }

                        $AceGuidByIDForThisNetworkPath[$ID] = $GuidsForThisIDAndNetworkPath

                    }

                    [PSCustomObject]@{
                        Path     = $NetworkPath
                        Accounts = Group-AccountPermissionReference -ID $IDsWithAccess.Value.Keys -AceGuidByID [ref]$AceGuidByIDForThisNetworkPath -AceByGuid $ACEsByGUID
                    }

                }

                [pscustomobject]$TargetProperties

            }
            break

        }

        'item' {

            ForEach ($Target in ($TargetPath.Value.Keys | Sort-Object)) {

                $TargetProperties = @{
                    Path = $Target
                }

                $NetworkPaths = $TargetPath.Value[$Target] | Sort-Object

                $TargetProperties['NetworkPaths'] = ForEach ($NetworkPath in $NetworkPaths) {

                    $TopLevelItemProperties = @{
                        'Items' = Group-ItemPermissionReference -SortedPath ($Children[$NetworkPath] | Sort-Object) -ACLsByPath $ACLsByPath @CommonParams
                    }

                    Group-ItemPermissionReference -SortedPath $NetworkPath -Property $TopLevelItemProperties -ACLsByPath $ACLsByPath @CommonParams

                }

                [pscustomobject]$TargetProperties

            }
            break

        }

        # 'none' and 'target' behave the same
        default {

            ForEach ($Target in ($TargetPath.Value.Keys | Sort-Object)) {

                $TargetProperties = @{
                    Path = $Target
                }

                $NetworkPaths = $TargetPath.Value[$Target] | Sort-Object

                $TargetProperties['NetworkPaths'] = ForEach ($NetworkPath in $NetworkPaths) {

                    $ItemsForThisNetworkPath = [System.Collections.Generic.List[String]]::new()
                    $ItemsForThisNetworkPath.Add($NetworkPath)
                    $ItemsForThisNetworkPath.AddRange([string[]]$Children[$NetworkPath])

                    [PSCustomObject]@{
                        Path   = $NetworkPath
                        Access = Expand-FlatPermissionReference -SortedPath $ItemsForThisNetworkPath @CommonParams
                    }

                }

                [pscustomobject]$TargetProperties

            }
            break

        }

    }

}
