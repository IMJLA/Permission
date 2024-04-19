function Select-PermissionTableProperty {

    # For the HTML table
    param (
        $InputObject,
        $IgnoreDomain,
        [Hashtable]$OutputHash = [Hashtable]::Synchronized(@{}),
        [String]$GroupBy
    )

    switch ($GroupBy) {

        'account' {

            ForEach ($Object in $InputObject) {

                $OutputHash[$Object.Account.ResolvedAccountName] = ForEach ($ACE in $Object.Access) {

                    # Each ACE contains the original IdentityReference representing the group the Object is a member of
                    $GroupString = ($ACE.Access.IdentityReferenceResolved | Sort-Object -Unique) -join ' ; '

                    # ToDo: param to allow setting [self] instead of the objects own name for this property
                    #if ($GroupString -eq $Object.Account.ResolvedAccountName) {
                    #    $GroupString = '[self]'
                    #} else {
                    ForEach ($IgnoreThisDomain in $IgnoreDomain) {
                        $GroupString = $GroupString -replace "$IgnoreThisDomain\\", ''
                    }
                    #}

                    [pscustomobject]@{
                        'Path'                 = $ACE.Path
                        'Access'               = ($ACE.Access.Access | Sort-Object -Unique) -join ' ; '
                        'Due to Membership In' = $GroupString
                        'Source of Access'     = ($ACE.Access.SourceOfAccess | Sort-Object -Unique) -join ' ; '
                    }

                }

            }
            break

        }

        'item' {

            ForEach ($Object in $InputObject) {

                $OutputHash[$Object.Item.Path] = ForEach ($ACE in $Object.Access) {

                    # Each ACE contains the original IdentityReference representing the group the Object is a member of
                    $GroupString = ($ACE.Access.IdentityReferenceResolved | Sort-Object -Unique) -join ' ; '

                    # ToDo: param to allow setting [self] instead of the objects own name for this property
                    #if ($GroupString -eq $Object.Account.ResolvedAccountName) {
                    #    $GroupString = '[self]'
                    #} else {
                    ForEach ($IgnoreThisDomain in $IgnoreDomain) {
                        $GroupString = $GroupString -replace "$IgnoreThisDomain\\", ''
                    }
                    #}

                    [pscustomobject]@{
                        'Account'              = $ACE.Account.ResolvedAccountName
                        'Access'               = ($ACE.Access.Access | Sort-Object -Unique) -join ' ; '
                        'Due to Membership In' = $GroupString
                        'Source of Access'     = ($ACE.Access.SourceOfAccess | Sort-Object -Unique) -join ' ; '
                        'Name'                 = $ACE.Account.Name
                        'Department'           = $ACE.Account.Department
                        'Title'                = $ACE.Account.Title
                    }

                }

            }
            break

        }

        # 'none' and 'target' behave the same
        default {

            ForEach ($Object in $InputObject) {

                $OutputHash[[guid]::NewGuid()] = ForEach ($ACE in $Object) {

                    # Each ACE contains the original IdentityReference representing the group the Object is a member of
                    $GroupString = ($ACE.IdentityReferenceResolved | Sort-Object -Unique) -join ' ; '

                    # ToDo: param to allow setting [self] instead of the objects own name for this property
                    #if ($GroupString -eq $Object.Account.ResolvedAccountName) {
                    #    $GroupString = '[self]'
                    #} else {
                    ForEach ($IgnoreThisDomain in $IgnoreDomain) {
                        $GroupString = $GroupString -replace "$IgnoreThisDomain\\", ''
                    }
                    #}

                    [pscustomobject]@{
                        'Item'                 = $Object.ItemPath
                        'Account'              = $ACE.ResolvedAccountName
                        'Access'               = ($ACE.Access | Sort-Object -Unique) -join ' ; '
                        'Due to Membership In' = $GroupString
                        'Source of Access'     = ($ACE.SourceOfAccess | Sort-Object -Unique) -join ' ; '
                        'Name'                 = $ACE.Name
                        'Department'           = $ACE.Department
                        'Title'                = $ACE.Title
                    }

                }

            }
            break

        }

    }

    return $OutputHash

}
