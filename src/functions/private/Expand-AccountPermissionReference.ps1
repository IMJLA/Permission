function Expand-AccountPermissionReference {

    param (

        $Reference,
        [ref]$PrincipalsByResolvedID,
        [ref]$ACEsByGUID,
        [ref]$ACLsByPath,
        [ref]$ParentBySourcePath,

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

    switch ($GroupBy) {

        'item' {}
        'source' {}

        # 'none' and 'account' behave the same
        default {

            ForEach ($Account in $Reference) {

                [PSCustomObject]@{
                    PSTypeName   = 'Permission.AccountPermission'
                    Account      = $PrincipalsByResolvedID.Value[$Account.Account]
                    NetworkPaths = ForEach ($NetworkPath in $Account.NetworkPaths) {
                        Pause # pause here to figure out where the heck SortedPaths is supposed to come from
                        [pscustomobject]@{
                            Access     = Expand-FlatPermissionReference -SortedPath $SortedPaths @ExpansionParameters
                            Item       = $AclsByPath.Value[$NetworkPath.Path]
                            PSTypeName = 'Permission.FlatPermission'
                        }

                    }

                }

            }

        }

    }




    <#

    $ParentBySourcePath = $Cache.Value['ParentBySourcePath'].Value
    $SourcePathByParent = @{}

    ForEach ($SourcePath in $ParentBySourcePath.Keys) {

        ForEach ($NetworkPath in $ParentBySourcePath[$SourcePath]) {
            $SourcePathByParent[$NetworkPath] += $SourcePath
        }

    }

    ForEach ($Account in $Reference) {

        $ItemByNetworkPath = New-PermissionCacheRef -Key ([string]) -Value ([System.Collections.Generic.List[PSCustomObject]])

        ForEach ($Access in $Account.Access) {

            ForEach ($Key in $ParentBySourcePath.Keys) {

                ForEach ($NetworkPath in $ParentBySourcePath[$Key]) {

                    if ($Access.Path.StartsWith($NetworkPath)) {

                        Add-PermissionCacheItem -Cache $ItemByNetworkPath -Key $NetworkPath -Value $Access -Type ([PSCustomObject])

                    }

                }

            }

        }

        [PSCustomObject]@{
            PSTypeName   = 'Permission.AccountPermission'
            Account      = $PrincipalsByResolvedID.Value[$Account.Account]
            NetworkPaths = ForEach ($NetworkPath in $ItemByNetworkPath.Keys) {

                $ItemPaths = $ItemByNetworkPath[$NetworkPath]

                [PSCustomObject]@{

                    Item   = $ACLsByPath.Value[$NetworkPath]
                    Access = Expand-AccountPermissionItemAccessReference -Reference $Account.Access -AceByGUID $ACEsByGUID -AclByPath $ACLsByPath
                }

            }
        }

    }
    #>

}
