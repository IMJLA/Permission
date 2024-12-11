function Select-PermissionTableProperty {

    # For the HTML table

    param (

        $InputObject,

        [String]$GroupBy,

        # Dictionary of shortened account IDs keyed by full resolved account IDs
        # Populated by Select-PermissionPrincipal
        [ref]$ShortNameByID,

        [ref]$ExcludeClassFilterContents,

        [ref]$IncludeAccountFilterContents,

        # Properties of each Account to display on the report (left out: managedby)
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description')

    )

    $OutputHash = @{}
    $Type = [PSCustomObject]
    $IncludeFilterCount = $IncludeAccountFilterContents.Value.Keys.Count

    switch ($GroupBy) {

        'account' {

            ForEach ($Object in $InputObject) {

                # Determine whether the account should be included according to inclusion/exclusion parameters
                $AccountName = $ShortNameByID.Value[$Object.Account.ResolvedAccountName]

                if ($AccountName) {

                    ForEach ($AceList in $Object.Access) {

                        ForEach ($ACE in $AceList.Access) {

                            if ($ACE.IdentityReferenceResolved -eq $Object.Account.ResolvedAccountName) {

                                # In this case the ACE's account is directly referenced in the DACL; it is merely a member of a group from the DACL
                                $GroupString = ''

                            } else {

                                # In this case the ACE contains the original IdentityReference representing the group the virtual ACE's account is a member of
                                $GroupString = $ShortNameByID.Value[$ACE.IdentityReferenceResolved]

                                if ( -not $GroupString ) {

                                    if (
                                        $ExcludeClassFilterContents.Value[$ACE.IdentityReferenceResolved] -or
                                        (
                                            $IncludeFilterCount -gt 0 -and -not
                                            $IncludeAccountFilterContents.Value[$Object.Account.ResolvedAccountName]
                                        )
                                    ) {
                                        $GroupString = $ACE.IdentityReferenceResolved #TODO - Apply IgnoreDomain here.  Put that .Replace logic into a function.
                                    }

                                }

                            }

                            # Use '$null -ne' to avoid treating an empty string '' as $null
                            if ($null -ne $GroupString) {

                                $Value = [pscustomobject]@{
                                    'Path'                 = $ACE.Path
                                    'Access'               = $ACE.Access
                                    'Due to Membership In' = $GroupString
                                    'Source of Access'     = $ACE.SourceOfAccess
                                }

                                Add-CacheItem -Cache $OutputHash -Key $AccountName -Value $Value -Type $Type

                            }

                        }

                    }

                }

            }
            break

        }

        'item' {

            ForEach ($Object in $InputObject) {

                $Accounts = @{}

                # Apply the -IgnoreDomain parameter
                ForEach ($AceList in $Object.Access) {

                    if ($null -ne $Object.Account) {
                        $Account = $Object.Account
                        $Item = $Object.Access.Item
                    } else {
                        $Item = $Object.Item
                        $Account = $AceList.Account
                    }

                    $AccountName = $ShortNameByID.Value[$Account.ResolvedAccountName]

                    if ($AccountName) {

                        ForEach ($ACE in $AceList.Access) {
                            Add-CacheItem -Cache $Accounts -Key $AccountName -Value $ACE -Type $Type
                        }

                    }

                }

                $OutputHash[$Item.Path] = ForEach ($AccountName in $Accounts.Keys) {

                    ForEach ($AceList in $Accounts[$AccountName]) {

                        ForEach ($ACE in $AceList) {

                            if ($ACE.IdentityReferenceResolved -eq $AccountName) {

                                # In this case the ACE's account is directly referenced in the DACL
                                $GroupString = ''

                            } else {

                                # In this case the account is merely a member of a group from the DACL

                                # Exclude the ACEs whose account names match the regular expressions specified in the -ExcludeAccount parameter
                                # Include the ACEs whose account names match the regular expressions specified in the -IncludeAccount parameter
                                # Exclude the ACEs whose account classes were included in the -ExcludeClass parameter

                                # Each ACE contains the original IdentityReference representing the group the Object is a member of
                                $GroupString = $ShortNameByID.Value[$ACE.IdentityReferenceResolved]

                                if ( -not $GroupString ) {

                                    if (
                                        $ExcludeClassFilterContents.Value[$ACE.IdentityReferenceResolved] -or
                                        (
                                            $IncludeFilterCount -gt 0 -and -not
                                            $IncludeAccountFilterContents.Value[$AccountName]
                                        )
                                    ) {
                                        $GroupString = $ACE.IdentityReferenceResolved #TODO - Apply IgnoreDomain here.  Put that .Replace logic into a function.
                                    }

                                }

                            }

                            # Exclude the virtual ACEs for members of groups whose group names match the regular expressions specified in the -ExcludeAccount parameter
                            # Include the virtual ACEs for members of groups whose group names match the regular expressions specified in the -IncludeAccount parameter
                            # Exclude the virtual ACEs for members of groups whose group classes were included in the -ExcludeClass parameter
                            # Use '$null -ne' to avoid treating an empty string '' as $null
                            if ($null -ne $GroupString) {

                                # this indicates SplitBy Account GroupBy Item
                                if ($null -ne $Object.Account) {

                                    $Props = [ordered]@{
                                        'Item'                 = $ACE.Path
                                        'Access'               = $ACE.Access #($ACE.Access.Access | Sort-Object -Unique) -join ' ; '
                                        'Due to Membership In' = $GroupString
                                        'Source of Access'     = $ACE.SourceOfAccess #($ACE.Access.SourceOfAccess | Sort-Object -Unique) -join ' ; '
                                    }

                                    [PSCustomObject]$Props

                                } else {

                                    $Props = [ordered]@{
                                        'Account'              = $AccountName
                                        'Access'               = $ACE.Access #($ACE.Access.Access | Sort-Object -Unique) -join ' ; '
                                        'Due to Membership In' = $GroupString
                                        'Source of Access'     = $ACE.SourceOfAccess #($ACE.Access.SourceOfAccess | Sort-Object -Unique) -join ' ; '
                                        'Name'                 = $AceList.Account.Name
                                    }

                                    ForEach ($PropName in $AccountProperty) {
                                        $Props[$PropName] = $AceList.Account.$PropName
                                    }

                                    [PSCustomObject]$Props

                                }

                            }

                        }

                    }

                }

            }
            break

        }

        # 'none' and 'target' behave the same
        default {

            $i = 0

            ForEach ($Object in $InputObject) {

                $OutputHash[$i] = ForEach ($ACE in $Object) {

                    $AccountName = $ShortNameByID.Value[$ACE.ResolvedAccountName]

                    # Exclude the ACEs whose account names match the regular expressions specified in the -ExcludeAccount parameter
                    # Include the ACEs whose account names match the regular expressions specified in the -IncludeAccount parameter
                    # Exclude the ACEs whose account classes were included in the -ExcludeClass parameter
                    if ($AccountName) {

                        if ($ACE.IdentityReferenceResolved -eq $ACE.ResolvedAccountName) {
                            $GroupString = ''
                        } else {

                            # Each ACE contains the original IdentityReference representing the group the Object is a member of
                            $GroupString = $ShortNameByID.Value[$ACE.IdentityReferenceResolved]

                            if ( -not $GroupString ) {

                                if (
                                    $ExcludeClassFilterContents.Value[$ACE.IdentityReferenceResolved] -or
                                    (
                                        $IncludeFilterCount -gt 0 -and -not
                                        $IncludeAccountFilterContents.Value[$ACE.ResolvedAccountName]
                                    )
                                ) {
                                    $GroupString = $ACE.IdentityReferenceResolved #TODO - Apply IgnoreDomain here.  Put that .Replace logic into a function.
                                }

                            }

                        }

                        # Exclude the virtual ACEs for members of groups whose group names match the regular expressions specified in the -ExcludeAccount parameter
                        # Include the virtual ACEs for members of groups whose group names match the regular expressions specified in the -IncludeAccount parameter
                        # Exclude the virtual ACEs for members of groups whose group classes were included in the -ExcludeClass parameter
                        # Use '$null -ne' to avoid treating an empty string '' as $null
                        if ($null -ne $GroupString) {

                            $Props = [ordered]@{
                                'Item'                 = $Object.ItemPath
                                'Account'              = $AccountName
                                'Access'               = $ACE.Access
                                'Due to Membership In' = $GroupString
                                'Source of Access'     = $ACE.SourceOfAccess
                                'Name'                 = $ACE.Name
                            }

                            ForEach ($PropName in $AccountProperty) {
                                $Props[$PropName] = $ACE.$PropName
                            }

                            [PSCustomObject]$Props

                        }

                    }

                }

                $i = $i + 1

            }
            break

        }

    }

    return $OutputHash

}
