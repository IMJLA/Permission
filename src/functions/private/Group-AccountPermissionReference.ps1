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
        | none    | source    | 1 file with all permissions grouped by source path |
        | account | none    | 1 file per account; in each file, sort permissions by item path |
        | account | account | (same as -SplitBy account -GroupBy none) |
        | account | item    | 1 file per account; in each file, group permissions by item and sort by item path |
        | account | source  | 1 file per account; in each file, group permissions by source path and sort by item path |
        | source  | none    | 1 file per source path; in each file, sort permissions by item path |
        | source  | account | 1 file per source path; in each file, group permissions by account and sort by account name |
        | source  | item    | 1 file per source path; in each file, group permissions by item and sort by item path |
        | source  | source  | (same as -SplitBy source -GroupBy none) |
        #>
        [ValidateSet('account', 'item', 'none', 'source')]
        [string]$GroupBy = 'item'

    )

    $ParentBySourcePath = $Cache.Value['ParentBySourcePath'].Value
    $GuidType = [guid]
    $StringType = [string]
    $Comparer = [StringComparer]::OrdinalIgnoreCase

    $CommonParams = @{
        AceGUIDsByPath         = $AceGuidByPath
        ACEsByGUID             = $ACEsByGUID
        PrincipalsByResolvedID = $PrincipalByResolvedID
    }

    switch ($GroupBy) {

        'item' {

            ForEach ($Identity in ($ID | Sort-Object)) {

                # Create a new cache for items accessible to the current identity, keyed by network path
                $ItemPathByNetworkPath = New-PermissionCacheRef -Key $StringType -Value ([System.Collections.Generic.List[string]]) -Comparer $Comparer
                $AceGuidByPathForThisId = New-PermissionCacheRef -Key $StringType -Value ([System.Collections.Generic.List[guid]]) -Comparer $Comparer
                $AceGuidByPathByNetworkPathForThisId = @{}

                ForEach ($Guid in $AceGuidByID.Value[$Identity]) {

                    $AceList = $AceByGuid.Value[$Guid]

                    ForEach ($Ace in $AceList) {

                        ForEach ($SourcePath in $ParentBySourcePath.Keys) {

                            ForEach ($NetworkPath in $ParentBySourcePath[$SourcePath]) {

                                if ($Ace.Path.StartsWith($NetworkPath)) {

                                    Add-PermissionCacheItem -Cache $AceGuidByPathForThisId -Key $Ace.Path -Value $Guid -Type $GuidType
                                    $AceGuidByPathByNetworkPathForThisId[$NetworkPath] = $AceGuidByPathForThisId

                                    if ($Ace.Path -ne $NetworkPath) {
                                        Add-PermissionCacheItem -Cache $ItemPathByNetworkPath -Key $NetworkPath -Value $Ace.Path -Type $StringType
                                    }

                                }

                            }

                        }

                    }

                }

                [PSCustomObject]@{
                    Account      = $Identity
                    NetworkPaths = ForEach ($SourcePath in $ParentBySourcePath.Keys) {

                        ForEach ($NetworkPath in $ParentBySourcePath[$SourcePath]) {

                            $NetworkPathProperties = @{
                                'Path' = $NetworkPath
                            }

                            $SortedPath = $ItemPathByNetworkPath.Value[$NetworkPath] | Sort-Object -Unique
                            $ForThisId = $AceGuidByPathByNetworkPathForThisId[$NetworkPath]

                            if ($ForThisId) {

                                $CommonParams['AceGuidsByPath'] = $ForThisId
                                $NetworkPathProperties['Items'] = Group-ItemPermissionReference -Identity $Identity -SortedPath $SortedPath @CommonParams
                                $NetworkPathProperties['AceGuidByPath'] = $ForThisId

                            } else {

                                $NetworkPathProperties['Items'] = $null
                                $NetworkPathProperties['AceGuidByPath'] = $AceGuidByPath

                            }

                        }

                        Group-ItemPermissionReference -Identity $Identity -SortedPath $NetworkPath -Property $NetworkPathProperties @CommonParams

                    }

                }

            }

            break

        }

        'source' {}

        # 'none' and 'account' behave the same
        default {

            ForEach ($Identity in ($ID | Sort-Object)) {

                # Create a new cache for items accessible to the current identity, keyed by network path
                $ItemPathByNetworkPath = New-PermissionCacheRef -Key $StringType -Value ([System.Collections.Generic.List[string]]) -Comparer $Comparer
                $AceGuidByPathForThisId = New-PermissionCacheRef -Key $StringType -Value ([System.Collections.Generic.List[guid]]) -Comparer $Comparer
                $AceGuidByPathByNetworkPathForThisId = @{}

                ForEach ($Guid in $AceGuidByID.Value[$Identity]) {

                    $AceList = $AceByGuid.Value[$Guid]

                    ForEach ($Ace in $AceList) {

                        ForEach ($SourcePath in $ParentBySourcePath.Keys) {

                            ForEach ($NetworkPath in $ParentBySourcePath[$SourcePath]) {

                                if ($Ace.Path.StartsWith($NetworkPath)) {

                                    Add-PermissionCacheItem -Cache $AceGuidByPathForThisId -Key $Ace.Path -Value $Guid -Type $GuidType
                                    Add-PermissionCacheItem -Cache $ItemPathByNetworkPath -Key $NetworkPath -Value $Ace.Path -Type $StringType
                                    $AceGuidByPathByNetworkPathForThisId[$NetworkPath] = $AceGuidByPathForThisId

                                }

                            }

                        }

                    }

                }

                [PSCustomObject]@{
                    Account      = $Identity
                    NetworkPaths = ForEach ($SourcePath in $ParentBySourcePath.Keys) {

                        ForEach ($NetworkPath in $ParentBySourcePath[$SourcePath]) {

                            $NetworkPathProperties = @{
                                'Path' = $NetworkPath
                            }

                            $SortedPath = $ItemPathByNetworkPath.Value[$NetworkPath] | Sort-Object -Unique
                            $ForThisId = $AceGuidByPathByNetworkPathForThisId[$NetworkPath]

                            if ($ForThisId) {

                                $CommonParams['AceGuidsByPath'] = $ForThisId
                                $CommonParams['PrincipalsByResolvedID'] = [ref]@{ $Identity = $PrincipalByResolvedID.Value[$Identity] }
                                $NetworkPathProperties['Items'] = Expand-FlatPermissionReference -Identity $Identity -SortedPath $SortedPath @CommonParams
                                $NetworkPathProperties['AceGuidByPath'] = $ForThisId

                            } else {

                                $NetworkPathProperties['Items'] = $null
                                $NetworkPathProperties['AceGuidByPath'] = $AceGuidByPath

                            }

                            [pscustomobject]$NetworkPathProperties

                        }

                    }

                }

            }

        }

    }

}
