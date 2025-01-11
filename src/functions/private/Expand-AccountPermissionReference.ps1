function Expand-AccountPermissionReference {

    param (

        $Reference,
        [ref]$PrincipalsByResolvedID,
        [ref]$ACEsByGUID,
        [ref]$AceGuidByPath,
        [ref]$AclByPath,
        [string[]]$SortedPath,
        [switch]$NoMembers,

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

        'item' {

            $ExpansionParameters = @{
                'AceByGUID' = $ACEsByGUID
            }

            ForEach ($Account in $Reference) {

                $Principal = $PrincipalsByResolvedID.Value[$Account.Account]

                [PSCustomObject]@{
                    'PSTypeName'   = 'Permission.AccountPermission'
                    'Account'      = $Principal
                    'NetworkPaths' = ForEach ($NetworkPath in $Account.NetworkPaths) {

                        $ExpansionParameters['PrincipalByResolvedID'] = [ref]@{ $Account.Account = $Principal }

                        [pscustomobject]@{
                            'Access' = Expand-ItemPermissionAccountAccessReference -Reference $NetworkPath.Access @ExpansionParameters
                            'Item'   = $AclByPath.Value[$NetworkPath.Path]
                            'Items'  = ForEach ($SourceChild in $NetworkPath.Items) {

                                $Access = Expand-ItemPermissionAccountAccessReference -Reference $SourceChild.Access @ExpansionParameters

                                if ($Access) {

                                    [pscustomobject]@{
                                        'Access'     = $Access
                                        'Item'       = $AclByPath.Value[$SourceChild.Path]
                                        'PSTypeName' = 'Permission.ChildItemPermission'
                                    }

                                }

                            }

                        }

                    }

                }

            }

        }

        'source' {}

        # 'none' and 'account' behave the same
        default {

            $ExpansionParameters = @{
                AceGUIDsByPath         = $AceGuidByPath
                ACEsByGUID             = $ACEsByGUID
                PrincipalsByResolvedID = $PrincipalsByResolvedID
            }

            ForEach ($Account in $Reference) {

                $Principal = $PrincipalsByResolvedID.Value[$Account.Account]

                [PSCustomObject]@{
                    PSTypeName   = 'Permission.AccountPermission'
                    Account      = $Principal
                    NetworkPaths = ForEach ($NetworkPath in $Account.NetworkPaths) {

                        $ExpansionParameters['AceGuidsByPath'] = $NetworkPath.AceGuidByPath
                        $ExpansionParameters['PrincipalsByResolvedID'] = [ref]@{ $Account.Account = $Principal }

                        [pscustomobject]@{
                            Access     = Expand-FlatPermissionReference -Identity $Account.Account -SortedPath $SortedPath @ExpansionParameters
                            Item       = $AclByPath.Value[$NetworkPath.Path]
                            PSTypeName = 'Permission.FlatPermission'
                        }

                    }

                }

            }

        }

    }

}
