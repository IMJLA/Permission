function Expand-TargetPermissionReference {

    # Expand each Access Control Entry with the Security Principal for the resolved IdentityReference.

    param (

        $Reference,
        [ref]$PrincipalsByResolvedID,
        [ref]$ACEsByGUID,
        [ref]$ACLsByPath,
        [ref]$AceGuidByPath,
        # How to group the permissions in the output stream and within each exported file
        [ValidateSet('account', 'item', 'none', 'target')]
        [String]$GroupBy = 'item'

    )

    switch ($GroupBy) {

        'account' {

            ForEach ($Target in $Reference) {

                $TargetProperties = @{
                    PSTypeName = 'Permission.TargetPermission'
                    Path       = $Target.Path
                }

                # Expand reference GUIDs into their associated Access Control Entries and Security Principals.
                $TargetProperties['NetworkPaths'] = ForEach ($NetworkPath in $Target.NetworkPaths) {

                    [pscustomobject]@{
                        Item       = $AclsByPath.Value[$NetworkPath.Path]
                        PSTypeName = 'Permission.ParentItemPermission'
                        Accounts   = Expand-AccountPermissionReference -Reference $NetworkPath.Accounts -ACEsByGUID $ACEsByGUID -PrincipalsByResolvedID $PrincipalsByResolvedID
                    }

                }

                [pscustomobject]$TargetProperties

            }
            break

        }

        'item' {

            ForEach ($Target in $Reference) {

                $TargetProperties = @{
                    Path = $Target.Path
                }

                # Expand reference GUIDs into their associated Access Control Entries and Security Principals.
                $TargetProperties['NetworkPaths'] = ForEach ($NetworkPath in $Target.NetworkPaths) {

                    [pscustomobject]@{
                        Access = Expand-ItemPermissionAccountAccessReference -Reference $NetworkPath.Access -AceByGUID $ACEsByGUID -PrincipalByResolvedID $PrincipalsByResolvedID
                        Item   = $AclsByPath.Value[$NetworkPath.Path]
                        Items  = ForEach ($TargetChild in $NetworkPath.Items) {

                            $Access = Expand-ItemPermissionAccountAccessReference -Reference $TargetChild.Access -AceByGUID $ACEsByGUID -PrincipalByResolvedID $PrincipalsByResolvedID

                            if ($Access) {

                                [pscustomobject]@{
                                    Access     = $Access
                                    Item       = $AclsByPath.Value[$TargetChild.Path]
                                    PSTypeName = 'Permission.ChildItemPermission'
                                }

                            }

                        }

                    }

                }

                [pscustomobject]$TargetProperties

            }
            break

        }

        # 'none' and 'target' behave the same
        default {

            $ExpansionParameters = @{
                AceGUIDsByPath         = $AceGuidByPath
                ACEsByGUID             = $ACEsByGUID
                PrincipalsByResolvedID = $PrincipalsByResolvedID
            }

            ForEach ($Target in $Reference) {

                $TargetProperties = @{
                    PSTypeName = 'Permission.TargetPermission'
                    Path       = $Target.Path
                }

                # Expand reference GUIDs into their associated Access Control Entries and Security Principals.
                $TargetProperties['NetworkPaths'] = ForEach ($NetworkPath in $Target.NetworkPaths) {

                    [pscustomobject]@{
                        Access     = Expand-FlatPermissionReference -SortedPath $SortedPaths @ExpansionParameters
                        Item       = $AclsByPath[$NetworkPath.Path]
                        PSTypeName = 'Permission.FlatPermission'

                    }

                }

                [pscustomobject]$TargetProperties

            }
            break

        }

    }

}
