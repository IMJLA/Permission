function Select-PermissionTableProperty {

    # For the HTML table
    param (
        $InputObject,
        [String]$GroupBy,
        [Hashtable]$ShortNameByID = [Hashtable]::Synchronized(@{}),
        [Hashtable]$OutputHash = [Hashtable]::Synchronized(@{}),
        [Hashtable]$IncludeFilterContents = [Hashtable]::Synchronized(@{})
    )

    $Type = [PSCustomObject]

    $IncludeFilterCount = $IncludeFilterContents.Keys.Count

    switch ($GroupBy) {

        'account' {

            ForEach ($Object in $InputObject) {

                $AccountName = $ShortNameByID[$Object.Account.ResolvedAccountName]

                if ($AccountName) {

                    ForEach ($AceList in $Object.Access) {

                        ForEach ($ACE in $AceList) {

                            if ($ACE.Access.IdentityReferenceResolved -eq $Object.Account.ResolvedAccountName) {

                                # In this case the ACE's account is directly referenced in the DACL; it is merely a member of a group from the DACL
                                $GroupString = ''

                            } else {

                                # In this case the ACE contains the original IdentityReference representing the group the virtual ACE's account is a member of
                                $GroupString = $ShortNameByID[$ACE.Access.IdentityReferenceResolved]

                                if (
                                    -not $GroupString -and
                                    (
                                        $IncludeFilterCount -gt 0 -and -not
                                        $IncludeFilterContents[$Object.Account.ResolvedAccountName]
                                    )
                                ) {
                                    $GroupString = $ACE.Access.IdentityReferenceResolved #TODO - Apply IgnoreDomain here.  Put that .Replace logic into a function.
                                }

                            }

                            if ($GroupString) {

                                $Value = [pscustomobject]@{
                                    'Path'                 = $ACE.Path
                                    'Access'               = $ACE.Access.Access
                                    'Due to Membership In' = $GroupString
                                    'Source of Access'     = $ACE.Access.SourceOfAccess
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
                ForEach ($ACE in $Object.Access) {

                    $AccountName = $ShortNameByID[$ACE.Account.ResolvedAccountName]

                    # Exclude the ACEs whose account names match the regular expressions specified in the -ExcludeAccount parameter
                    # Include the ACEs whose account names match the regular expressions specified in the -IncludeAccount parameter
                    # Exclude the ACEs whose account classes were included in the -ExcludeClass parameter
                    if ($AccountName) {

                        # Each ACE contains the original IdentityReference representing the group the Object is a member of
                        ##$GroupString = ($ACE.Access.IdentityReferenceResolved | Sort-Object -Unique) -join ' ; '
                        $GroupString = $ShortNameByID[$ACE.Access.IdentityReferenceResolved]

                        # Exclude the virtual ACEs for members of groups whose group names match the regular expressions specified in the -ExcludeAccount parameter
                        # Include the virtual ACEs for members of groups whose group names match the regular expressions specified in the -IncludeAccount parameter
                        # Exclude the virtual ACEs for members of groups whose group classes were included in the -ExcludeClass parameter
                        if ($GroupString) {
                            Add-CacheItem -Cache $Accounts -Key $AccountName -Value $ACE -Type $Type
                        }

                    }

                }

                $OutputHash[$Object.Item.Path] = ForEach ($ResolvedName in $Accounts.Keys) {

                    ForEach ($AceList in $Accounts[$ResolvedName]) {

                        ForEach ($ACE in $AceList) {

                            # ToDo: param to allow setting [self] instead of the objects own name for this property
                            #if ($GroupString -eq $Object.Account.ResolvedAccountName) {
                            #    $GroupString = '[self]'
                            #}

                            [pscustomobject]@{
                                'Account'              = $ShortNameByID[$ResolvedName]
                                'Access'               = $ACE.Access.Access #($ACE.Access.Access | Sort-Object -Unique) -join ' ; '
                                'Due to Membership In' = $GroupString = $ShortNameByID[$ACE.Access.IdentityReferenceResolved]
                                'Source of Access'     = $ACE.Access.SourceOfAccess #($ACE.Access.SourceOfAccess | Sort-Object -Unique) -join ' ; '
                                'Name'                 = $ACE.Account.Name
                                'Department'           = $ACE.Account.Department
                                'Title'                = $ACE.Account.Title
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

                    $AccountName = $ShortNameByID[$ACE.ResolvedAccountName]

                    # Exclude the ACEs whose account names match the regular expressions specified in the -ExcludeAccount parameter
                    # Include the ACEs whose account names match the regular expressions specified in the -IncludeAccount parameter
                    # Exclude the ACEs whose account classes were included in the -ExcludeClass parameter
                    if ($AccountName) {

                        # Each ACE contains the original IdentityReference representing the group the Object is a member of
                        #$GroupString = ($ACE.IdentityReferenceResolved | Sort-Object -Unique) -join ' ; '
                        $GroupString = $ShortNameByID[$ACE.IdentityReferenceResolved]

                        # Exclude the virtual ACEs for members of groups whose group names match the regular expressions specified in the -ExcludeAccount parameter
                        # Include the virtual ACEs for members of groups whose group names match the regular expressions specified in the -IncludeAccount parameter
                        # Exclude the virtual ACEs for members of groups whose group classes were included in the -ExcludeClass parameter
                        if ($GroupString) {

                            # ToDo: param to allow setting [self] instead of the objects own name for this property
                            #if ($GroupString -eq $Object.Account.ResolvedAccountName) {
                            #    $GroupString = '[self]'
                            #}

                            [pscustomobject]@{
                                'Item'                 = $Object.ItemPath
                                'Account'              = $AccountName
                                'Access'               = $ACE.Access # | Sort-Object -Unique) -join ' ; '
                                'Due to Membership In' = $GroupString
                                'Source of Access'     = $ACE.SourceOfAccess # | Sort-Object -Unique) -join ' ; '
                                'Name'                 = $ACE.Name
                                'Department'           = $ACE.Department
                                'Title'                = $ACE.Title
                            }

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
