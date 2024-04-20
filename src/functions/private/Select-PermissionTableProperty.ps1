function Select-PermissionTableProperty {

    # For the HTML table
    param (
        $InputObject,
        $IgnoreDomain,
        [Hashtable]$OutputHash = [Hashtable]::Synchronized(@{}),
        [String]$GroupBy
    )

    $Type = [PSCustomObject]

    switch ($GroupBy) {

        'account' {

            ForEach ($Object in $InputObject) {

                $AccountName = $Object.Account.ResolvedAccountName

                ForEach ($IgnoreThisDomain in $IgnoreDomain) {
                    $AccountName = $AccountName.Replace("$IgnoreThisDomain\", '')
                }

                ForEach ($ACE in $Object.Access) {

                    # Each ACE contains the original IdentityReference representing the group the Object is a member of
                    $GroupString = ($ACE.Access.IdentityReferenceResolved | Sort-Object -Unique) -join ' ; '

                    # ToDo: param to allow setting [self] instead of the objects own name for this property
                    #if ($GroupString -eq $Object.Account.ResolvedAccountName) {
                    #    $GroupString = '[self]'
                    #} else {
                    ForEach ($IgnoreThisDomain in $IgnoreDomain) {
                        $GroupString = $GroupString.Replace("$IgnoreThisDomain\", '')
                    }
                    #}

                    $Value = [pscustomobject]@{
                        'Path'                 = $ACE.Path
                        'Access'               = ($ACE.Access.Access | Sort-Object -Unique) -join ' ; '
                        'Due to Membership In' = $GroupString
                        'Source of Access'     = ($ACE.Access.SourceOfAccess | Sort-Object -Unique) -join ' ; '
                    }

                    Add-CacheItem -Cache $OutputHash -Key $AccountName -Value $Value -Type $Type

                }



            }
            break

        }

        'item' {

            ForEach ($Object in $InputObject) {

                $Accounts = @{}

                # Apply the -IgnoreDomain parameter
                ForEach ($ACE in $Object.Access) {

                    $AccountName = $ACE.Account.ResolvedAccountName

                    ForEach ($IgnoreThisDomain in $IgnoreDomain) {
                        $AccountName = $AccountName.Replace("$IgnoreThisDomain\", '')
                    }

                    Add-CacheItem -Cache $Accounts -Key $AccountName -Value $ACE -Type $Type

                }

                $OutputHash[$Object.Item.Path] = ForEach ($AccountName in $Accounts.Keys) {

                    ForEach ($ACE in $Accounts[$AccountName]) {

                        # Each ACE contains the original IdentityReference representing the group the Object is a member of
                        $GroupString = ($ACE.Access.IdentityReferenceResolved | Sort-Object -Unique) -join ' ; '

                        # ToDo: param to allow setting [self] instead of the objects own name for this property
                        #if ($GroupString -eq $Object.Account.ResolvedAccountName) {
                        #    $GroupString = '[self]'
                        #} else {
                        ForEach ($IgnoreThisDomain in $IgnoreDomain) {
                            $GroupString = $GroupString.Replace("$IgnoreThisDomain\", '')
                        }
                        #}

                        [pscustomobject]@{
                            'Account'              = $AccountName
                            'Access'               = ($ACE.Access.Access | Sort-Object -Unique) -join ' ; '
                            'Due to Membership In' = $GroupString
                            'Source of Access'     = ($ACE.Access.SourceOfAccess | Sort-Object -Unique) -join ' ; '
                            'Name'                 = $ACE.Account.Name
                            'Department'           = $ACE.Account.Department
                            'Title'                = $ACE.Account.Title
                        }

                    }

                }

            }
            break

        }

        # 'none' and 'target' behave the same
        default {

            ForEach ($Object in $InputObject) {

                $OutputHash[[guid]::NewGuid()] = ForEach ($ACE in $Object) {

                    $AccountName = $ACE.ResolvedAccountName

                    # Each ACE contains the original IdentityReference representing the group the Object is a member of
                    $GroupString = ($ACE.IdentityReferenceResolved | Sort-Object -Unique) -join ' ; '

                    # ToDo: param to allow setting [self] instead of the objects own name for this property
                    #if ($GroupString -eq $Object.Account.ResolvedAccountName) {
                    #    $GroupString = '[self]'
                    #} else {
                    ForEach ($IgnoreThisDomain in $IgnoreDomain) {
                        $AccountName = $AccountName.Replace("$IgnoreThisDomain\", '')
                        $GroupString = $GroupString -replace "$IgnoreThisDomain\\", ''
                    }
                    #}

                    [pscustomobject]@{
                        'Item'                 = $Object.ItemPath
                        'Account'              = $AccountName
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
