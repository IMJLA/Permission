function Expand-TargetPermissionReference {

    # Expand each Access Control Entry with the Security Principal for the resolved IdentityReference.

    param (

        $Reference,
        [ref]$PrincipalsByResolvedID,
        [ref]$ACEsByGUID,
        [ref]$ACLsByPath,
        [ref]$AceGuidByPath,

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

        'account' {

            ForEach ($Source in $Reference) {

                $SourceProperties = @{
                    PSTypeName = 'Permission.TargetPermission'
                    Path       = $Source.Path
                }

                # Expand reference GUIDs into their associated Access Control Entries and Security Principals.
                $SourceProperties['NetworkPaths'] = ForEach ($NetworkPath in $Source.NetworkPaths) {

                    [pscustomobject]@{
                        Item       = $AclsByPath.Value[$NetworkPath.Path]
                        PSTypeName = 'Permission.ParentItemPermission'
                        Accounts   = Expand-AccountPermissionReference -Reference $NetworkPath.Accounts -ACEsByGUID $ACEsByGUID -PrincipalsByResolvedID $PrincipalsByResolvedID -ACLsByPath $ACLsByPath
                    }

                }

                [pscustomobject]$SourceProperties

            }
            break

        }

        'item' {

            ForEach ($Source in $Reference) {

                $SourceProperties = @{
                    Path = $Source.Path
                }

                # Expand reference GUIDs into their associated Access Control Entries and Security Principals.
                $SourceProperties['NetworkPaths'] = ForEach ($NetworkPath in $Source.NetworkPaths) {

                    [pscustomobject]@{
                        Access = Expand-ItemPermissionAccountAccessReference -Reference $NetworkPath.Access -AceByGUID $ACEsByGUID -PrincipalByResolvedID $PrincipalsByResolvedID
                        Item   = $AclsByPath.Value[$NetworkPath.Path]
                        Items  = ForEach ($SourceChild in $NetworkPath.Items) {

                            $Access = Expand-ItemPermissionAccountAccessReference -Reference $SourceChild.Access -AceByGUID $ACEsByGUID -PrincipalByResolvedID $PrincipalsByResolvedID

                            if ($Access) {

                                [pscustomobject]@{
                                    Access     = $Access
                                    Item       = $AclsByPath.Value[$SourceChild.Path]
                                    PSTypeName = 'Permission.ChildItemPermission'
                                }

                            }

                        }

                    }

                }

                [pscustomobject]$SourceProperties

            }
            break

        }

        # 'none' and 'source' behave the same
        default {

            $ExpansionParameters = @{
                AceGUIDsByPath         = $AceGuidByPath
                ACEsByGUID             = $ACEsByGUID
                PrincipalsByResolvedID = $PrincipalsByResolvedID
            }

            ForEach ($Source in $Reference) {

                $SourceProperties = @{
                    PSTypeName = 'Permission.TargetPermission'
                    Path       = $Source.Path
                }

                # Expand reference GUIDs into their associated Access Control Entries and Security Principals.
                $SourceProperties['NetworkPaths'] = ForEach ($NetworkPath in $Source.NetworkPaths) {

                    [pscustomobject]@{
                        Access     = Expand-FlatPermissionReference -SortedPath $SortedPaths @ExpansionParameters
                        Item       = $AclsByPath.Value[$NetworkPath.Path]
                        PSTypeName = 'Permission.FlatPermission'

                    }

                }

                [pscustomobject]$SourceProperties

            }
            break

        }

    }

}
