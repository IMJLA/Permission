function Group-SourcePermissionReference {

    # Expand each Access Control Entry with the Security Principal for the resolved IdentityReference.

    param (

        [ref]$SourcePath,
        [Hashtable]$Children,
        [ref]$PrincipalsByResolvedID,
        [ref]$AceGuidByID,
        [ref]$ACEsByGUID,
        [ref]$AceGUIDsByPath,
        [ref]$ACLsByPath,

        <#
        How to group the permissions in the output stream and within each exported file. Interacts with the SplitBy parameter:

        | SplitBy | GroupBy | Behavior |
        |---------|---------|----------|
        | none    | none    | 1 file with all permissions in a flat list |
        | none    | account | 1 file with all permissions grouped by account |
        | none    | item    | 1 file with all permissions grouped by item |
        | account | none    | 1 file per account; in each file, sort ACEs by item path |
        | account | account | (same as -SplitBy account -GroupBy none) |
        | account | item    | 1 file per account; in each file, group ACEs by item and sort by item path |
        | item    | none    | 1 file per item; in each file, sort ACEs by account name |
        | item    | account | 1 file per item; in each file, group ACEs by account and sort by account name |
        | item    | item    | (same as -SplitBy item -GroupBy none) |
        | source  | none    | 1 file per source path; in each file, sort ACEs by source path |
        | source  | account | 1 file per source path; in each file, group ACEs by account and sort by account name |
        | source  | item    | 1 file per source path; in each file, group ACEs by item and sort by item path |
        | source  | source  | (same as -SplitBy source -GroupBy none) |
        #>
        [ValidateSet('account', 'item', 'none', 'source')]
        [string]$GroupBy = 'item'

    )

    $CommonParams = @{
        AceGUIDsByPath         = $AceGUIDsByPath
        ACEsByGUID             = $ACEsByGUID
        PrincipalsByResolvedID = $PrincipalsByResolvedID
    }

    switch ($GroupBy) {

        'account' {

            ForEach ($Source in ($SourcePath.Value.Keys | Sort-Object)) {

                $SourceProperties = @{
                    Path = $Source
                }

                $NetworkPaths = $SourcePath.Value[$Source] | Sort-Object

                $SourceProperties['NetworkPaths'] = ForEach ($NetworkPath in $NetworkPaths) {

                    $ItemsForThisNetworkPath = [System.Collections.Generic.List[String]]::new()
                    $ItemsForThisNetworkPath.Add($NetworkPath)
                    $Kids = [string[]]$Children[$NetworkPath]
                    if ($Kids) {
                        $ItemsForThisNetworkPath.AddRange($Kids)
                    }
                    $IDsWithAccess = Find-ResolvedIDsWithAccess -ItemPath $ItemsForThisNetworkPath @CommonParams

                    # Prepare a dictionary for quick lookup of ACE GUIDs for this source
                    $AceGuidsForThisNetworkPath = @{}

                    # Enumerate the collection of ACE GUIDs for this source
                    ForEach ($Item in $ItemsForThisNetworkPath) {

                        ForEach ($Guid in $AceGUIDsByPath.Value[$Item]) {

                            # The returned dictionary value is a lists of guids, so we need to enumerate the list
                            ForEach ($ListItem in $Guid) {

                                # Add each GUID to the dictionary for quick lookups
                                $AceGuidsForThisNetworkPath[$ListItem] = $null

                            }

                        }

                    }

                    $AceGuidByIDForThisNetworkPath = @{}

                    ForEach ($ID in $IDsWithAccess.Value.Keys) {

                        $GuidsForThisIDAndNetworkPath = [System.Collections.Generic.List[guid]]::new()

                        ForEach ($Guid in $AceGuidByID.Value[$ID]) {

                            if ($AceGuidsForThisNetworkPath.ContainsKey($Guid)) {
                                $GuidsForThisIDAndNetworkPath.Add($Guid)
                            }

                        }

                        $AceGuidByIDForThisNetworkPath[$ID] = $GuidsForThisIDAndNetworkPath

                    }

                    [PSCustomObject]@{
                        Path     = $NetworkPath
                        Accounts = Group-AccountPermissionReference -ID $IDsWithAccess.Value.Keys -AceGuidByID ([ref]$AceGuidByIDForThisNetworkPath) -AceByGuid $ACEsByGUID -GroupBy $GroupBy -AceGuidByPath $AceGuidsByPath -PrincipalByResolvedID $PrincipalsByResolvedID
                    }

                }

                [pscustomobject]$SourceProperties

            }
            break

        }

        'item' {

            ForEach ($Source in ($SourcePath.Value.Keys | Sort-Object)) {

                $SourceProperties = @{
                    Path = $Source
                }

                $NetworkPaths = $SourcePath.Value[$Source] | Sort-Object

                $SourceProperties['NetworkPaths'] = ForEach ($NetworkPath in $NetworkPaths) {

                    $TopLevelItemProperties = @{
                        'Items' = Group-ItemPermissionReference -SortedPath ($Children[$NetworkPath] | Sort-Object) @CommonParams
                    }

                    Group-ItemPermissionReference -SortedPath $NetworkPath -Property $TopLevelItemProperties @CommonParams

                }

                [pscustomobject]$SourceProperties

            }
            break

        }

        # 'none' and 'source' behave the same
        default {

            ForEach ($Source in ($SourcePath.Value.Keys | Sort-Object)) {

                $SourceProperties = @{
                    Path = $Source
                }

                $NetworkPaths = $SourcePath.Value[$Source] | Sort-Object

                $SourceProperties['NetworkPaths'] = ForEach ($NetworkPath in $NetworkPaths) {

                    $ItemsForThisNetworkPath = [System.Collections.Generic.List[String]]::new()
                    $ItemsForThisNetworkPath.Add($NetworkPath)
                    $Kids = [string[]]$Children[$NetworkPath]
                    if ($Kids) {
                        $ItemsForThisNetworkPath.AddRange($Kids)
                    }

                    [PSCustomObject]@{
                        Path   = $NetworkPath
                        Access = Expand-FlatPermissionReference -SortedPath $ItemsForThisNetworkPath @CommonParams
                    }

                }

                [pscustomobject]$SourceProperties

            }
            break

        }

    }

}
