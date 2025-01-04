function Group-AccountPermissionReference {

    param (

        [string[]]$ID,
        [ref]$AceGuidByID,
        [ref]$AceByGuid,
        [ref]$AceGuidByPath,
        [ref]$PrincipalByResolvedID,

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
        AceGUIDsByPath         = $AceGuidByPath
        ACEsByGUID             = $ACEsByGUID
        PrincipalsByResolvedID = $PrincipalByResolvedID
    }

    switch ($GroupBy) {

        'item' {}
        'source' {}

        # 'none' and 'account' behave the same
        default {

            $ParentBySourcePath = $Cache.Value['ParentBySourcePath'].Value

            ForEach ($Identity in ($ID | Sort-Object)) {

                # Limit the PrincipalByResolvedID cache to the current identity
                $CommonParams['PrincipalByResolvedID'] = [ref]@{ $Identity = $PrincipalByResolvedID.Value[$Identity] }
                # Create a new cache for items accessible to the current identity, keyed by network path
                $ItemPathByNetworkPath = New-PermissionCacheRef -Key ([string]) -Value ([System.Collections.Generic.List[string]])

                ForEach ($Guid in $AceGuidByID.Value[$Identity]) {

                    $AceList = $AceByGuid.Value[$Guid]

                    ForEach ($Ace in $AceList) {

                        ForEach ($Key in $ParentBySourcePath.Keys) {

                            ForEach ($NetworkPath in $ParentBySourcePath[$Key]) {

                                if ($Ace.Path.StartsWith($NetworkPath)) {

                                    Add-PermissionCacheItem -Cache $ItemPathByNetworkPath -Key $NetworkPath -Value $Ace.Path -Type ([string])

                                }

                            }

                        }

                    }

                }

                [PSCustomObject]@{
                    Account      = $Identity
                    NetworkPaths = ForEach ($NetworkPath in $ItemPathByNetworkPath.Value.Keys) {

                        $SortedPath = $ItemPathByNetworkPath.Value[$NetworkPath] | Sort-Object

                        [pscustomobject]@{
                            Path  = $NetworkPath
                            Items = Expand-FlatPermissionReference -SortedPath $SortedPath @CommonParams
                        }

                    }

                }

            }

        }

    }

}
