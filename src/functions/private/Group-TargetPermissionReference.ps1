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

                    $AceGuidByIDForThisNetworkPath = @{}

                    ForEach ($ID in $IDsWithAccess.Keys) {

                        $IdentityString = [string]$ID
                        $GuidsForThisID = $AceGUIDsByResolvedID[$IdentityString]

                        if ($GuidsForThisID) {

                            $GuidsForThisIDAndNetworkPath = [System.Collections.Generic.List[guid]]::new()

                            ForEach ($Guid in $GuidsForThisID) {

                                $AceContainsThisID = $AceGuidsForThisNetworkPath[$Guid]

                                if ($AceContainsThisID) {
                                    $GuidsForThisIDAndNetworkPath.Add($Guid)
                                }

                            }

                            if ($GuidsForThisIDAndNetworkPath) {

                                $AceGuidByIDForThisNetworkPath[$IdentityString] = $GuidsForThisIDAndNetworkPath

                            } else {
                                Write-Host "0 GUIDs for this ID and Network Path '$IdentityString' on '$NetworkPath')" -ForegroundColor Magenta
                                #$Joined = ($AceGuidsForThisNetworkPath.Keys | Sort-Object) -join "`r`n"
                                Write-Host "The $($AceGuidsForThisNetworkPath.Keys.Count) available keys are: `$Joined" -ForegroundColor Magenta
                                $FirstKey = @($AceGuidsForThisNetworkPath.Keys)[0]
                                Write-Host "First key '$FirstKey' is a: $($FirstKey.GetType().FullName)" -ForegroundColor Magenta
                                $FirstLookupKey = $GuidsForThisID[0]
                                Write-Host "First lookup key '$FirstLookupKey' is a: $($FirstLookupKey.GetType().FullName)" -ForegroundColor Magenta

                            }

                        } else {
                            Write-Host "0 GUIDs for this ID '$IdentityString' which is a $($IdentityString.GetType().FullName)" -ForegroundColor Red
                            $Joined = ($AceGUIDsByResolvedID.Keys | Sort-Object) -join "`r`n"
                            Write-Host "The $($AceGUIDsByResolvedID.Keys.Count) available keys are: $Joined" -ForegroundColor Red
                            $FirstKey = @($AceGUIDsByResolvedID.Keys)[0]
                            Write-Host "First key '$FirstKey' is a: $($FirstKey.GetType().FullName)" -ForegroundColor Red
                        }

                    }

                    [PSCustomObject]@{
                        Path     = $NetworkPath
                        Accounts = Group-AccountPermissionReference -ID $IDsWithAccess.Keys -AceGuidByID $AceGuidByIDForThisNetworkPath -AceByGuid $ACEsByGUID
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
