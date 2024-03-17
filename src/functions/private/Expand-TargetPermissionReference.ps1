function Expand-TargetPermissionReference {

    # Expand each Access Control Entry with the Security Principal for the resolved IdentityReference.

    param (

        $Reference,
        $PrincipalsByResolvedID,
        $ACEsByGUID,
        $ACLsByPath,
        [string]$GroupBy

    )

    ForEach ($Target in $Reference) {

        $TargetProperties = @{
            PSTypeName = 'Permission.TargetPermission'
            Target     = $Target.Path
        }

        switch ($GroupBy) {
            'account' {}
            'item' {

                # Expand reference GUIDs into their associated Access Control Entries and Security Principals.
                $TargetProperties['Items'] = ForEach ($ParentItem in $Target.Items) {

                    [pscustomobject]@{
                        Access     = Expand-ItemPermissionAccountAccessReference -Reference $ParentItem.Access -ACEsByGUID $ACEsByGUID -PrincipalsByResolvedID $PrincipalsByResolvedID
                        Item       = $AclsByPath[$ParentItem.Path]
                        PSTypeName = 'Permission.ItemPermission'
                        Children   = ForEach ($TargetChild in $ParentItem.Children) {

                            $ChildItemProperties = @{
                                Item       = $AclsByPath[$TargetChild]
                                PSTypeName = 'Permission.ChildItemPermission'
                            }

                            $ChildItemProperties['Access'] = Expand-ItemPermissionAccountAccessReference -Reference $TargetChild.Access -ACEsByGUID $ACEsByGUID -PrincipalsByResolvedID $PrincipalsByResolvedID
                            [pscustomobject]$ChildItemProperties

                        }

                    }

                }

            }

            default {} # none
        }

        [pscustomobject]$TargetProperties

    }

}
