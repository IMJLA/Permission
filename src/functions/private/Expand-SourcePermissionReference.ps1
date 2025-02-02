function Expand-SourcePermissionReference {

    # Expand each Access Control Entry with the Security Principal for the resolved IdentityReference.

    param (

        $Reference,
        [ref]$PrincipalsByResolvedID,
        [ref]$ACEsByGUID,
        [ref]$ACLsByPath,
        [ref]$AceGuidByPath,
        [string[]]$SortedPath,

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

    switch ($GroupBy) {

        'account' {

            ForEach ($Source in $Reference) {

                $SourceProperties = @{
                    PSTypeName = 'Permission.SourcePermission'
                    Path       = $Source.Path
                }

                # Expand reference GUIDs into their associated Access Control Entries and Security Principals.
                $SourceProperties['NetworkPaths'] = ForEach ($NetworkPath in $Source.NetworkPaths) {

                    [pscustomobject]@{
                        Item       = $AclsByPath.Value[$NetworkPath.Path]
                        PSTypeName = 'Permission.ParentItemPermission'
                        Accounts   = Expand-AccountPermissionReference -Reference $NetworkPath.Accounts -ACEsByGUID $ACEsByGUID -PrincipalsByResolvedID $PrincipalsByResolvedID -AclByPath $ACLsByPath -AceGuidByPath $AceGuidByPath -SortedPath $SortedPath -GroupBy $GroupBy
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
                    PSTypeName = 'Permission.SourcePermission'
                    Path       = $Source.Path
                }

                # Expand reference GUIDs into their associated Access Control Entries and Security Principals.
                $SourceProperties['NetworkPaths'] = ForEach ($NetworkPath in $Source.NetworkPaths) {

                    [pscustomobject]@{
                        Access     = Expand-FlatPermissionReference -SortedPath $SortedPath @ExpansionParameters
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
