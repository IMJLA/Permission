function Group-TargetPermissionReference {

    # Expand each Access Control Entry with the Security Principal for the resolved IdentityReference.

    param (

        [hashtable]$TargetPath,
        [hashtable]$Children,
        $PrincipalsByResolvedID,
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

    ForEach ($Target in $TargetPath.Keys) {

        $TargetProperties = @{
            Path = $Target
        }

        switch ($GroupBy) {

            'account' {

                $PathsForThisTarget = [System.Collections.Generic.List[string]]::new()
                $PathsForThisTarget.AddRange([string[]]$TargetPath[$Target])

                ForEach ($TargetParent in $TargetPath[$Target]) {
                    $PathsForThisTarget.AddRange([string[]]$Children[$TargetParent])
                }

                $IDsWithAccess = Find-ResolvedIDsWithAccess -ItemPath $PathsForThisTarget -AceGUIDsByPath $AceGUIDsByPath -ACEsByGUID $ACEsByGUID -PrincipalsByResolvedID $PrincipalsByResolvedID

                # Prepare a dictionary for quick lookup of ACE GUIDs for this target
                $AceGuidsForThisTarget = @{}

                # Enumerate the collection of ACE GUIDs for this target
                ForEach ($Guid in $AceGUIDsByPath[$PathsForThisTarget]) {

                    # Check for null (because we send a list into the dictionary for lookup, we receive a null result for paths that do not exist as a key in the dict)
                    if ($Guid) {
                        # Add each GUID to the dictionary for quick lookups
                        $AceGuidsForThisTarget[$Guid] = $true

                    }

                }

                $AceGuidsByResolvedIDForThisTarget = @{}

                ForEach ($ID in $IDsWithAccess) {

                    $AllGuidsForThisID = $AceGUIDsByResolvedID[$ID]

                    if ($AllGuidsForThisID) {

                        $AceGuidsByResolvedIDForThisTarget[$ID] = $AllGuidsForThisID |
                        Where-Object -FilterScript {
                            $AceGuidsForThisTarget[$_]
                        }

                    }

                }

                $TargetProperties['Accounts'] = Group-AccountPermissionReference -ID $IDsWithAccess -AceGUIDsByResolvedID $AceGuidsByResolvedIDForThisTarget -ACEsByGUID $ACEsByGUID

            }

            'item' {

                $TargetProperties['Items'] = ForEach ($TargetParent in ($TargetPath[$Target] | Sort-Object)) {

                    $TopLevelItemProperties = @{
                        'Children' = Group-ItemPermissionReference -SortedPath ($Children[$TargetParent] | Sort-Object) -ACLsByPath $ACLsByPath @CommonParams
                    }

                    Group-ItemPermissionReference -SortedPath $TargetParent -Property $TopLevelItemProperties -ACLsByPath $ACLsByPath @CommonParams

                }

            }

            # none
            default {

                $PathsForThisTarget = [System.Collections.Generic.List[string]]::new()
                $PathsForThisTarget.AddRange($TargetPath[$Target])

                ForEach ($TargetParent in $TargetPath[$Target]) {
                    $PathsForThisTarget.AddRange($Children[$TargetParent])
                }

                $TargetProperties['Access'] = Expand-FlatPermissionReference -SortedPath $PathsForThisTarget @CommonParams

            }

        }

        [pscustomobject]$TargetProperties

    }

}
