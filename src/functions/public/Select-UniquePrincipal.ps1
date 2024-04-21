function Select-UniquePrincipal {

    param (

        # Cache of security principals keyed by resolved identity reference
        [Hashtable]$PrincipalsByResolvedID = ([Hashtable]::Synchronized(@{})),

        # Regular expressions matching names of Users or Groups to exclude from the Html report
        [string[]]$ExcludeAccount,

        <#
        Domain(s) to ignore (they will be removed from the username)

        Intended when a user has matching SamAccountNames in multiple domains but you only want them to appear once on the report.

        Can also be used to remove all domains simply for brevity in the report.
        #>
        [string[]]$IgnoreDomain,

        [Hashtable]$IdByShortName = [Hashtable]::Synchronized(@{}),

        [Hashtable]$ShortNameByID = [Hashtable]::Synchronized(@{}),

        [Hashtable]$ExcludeFilterContents = [Hashtable]::Synchronized(@{}),

        [Hashtable]$IncludeFilterContents = [Hashtable]::Synchronized(@{})

    )

    $Type = [string]

    ForEach ($ThisID in $PrincipalsByResolvedID.Keys) {

        if (

            # Exclude the objects whose names match the regular expressions specified in the parameters
            [bool]$(
                ForEach ($RegEx in $ExcludeAccount) {
                    if ($ThisID -match $RegEx) {
                        $ExcludeFilterContents[$ThisID] = $ThisID
                        $true
                    }
                }
            ) -or

            # Include the objects whose names match the regular expressions specified in the -IncludeAccount parameter
            -not [bool]$(

                if ($IncludeAccount.Count -eq 0) {
                    # If no regular expressions were specified, then return $true here
                    # This will be reversed into a $false by the -not operator above
                    # Resulting in the 'continue' statement not being reached, therefore this principal not being filtered out
                    $true
                } else {
                    ForEach ($RegEx in $IncludeAccount) {
                        if ($AccountName -match $RegEx) {
                            # If the account name matches one of the regular expressions, then return $true here
                            # This will be reversed into a $false by the -not operator above
                            # Resulting in the 'continue' statement not being reached, therefore this principal not being filtered out
                            $true
                        } else {
                            $IncludeFilterContents[$AccountName] = $AccountName
                        }
                    }
                }

            )
        ) { continue }

        $ShortName = $ThisID

        ForEach ($IgnoreThisDomain in $IgnoreDomain) {
            $ShortName = $ShortName -replace "^$IgnoreThisDomain\\", ''
        }

        Add-CacheItem -Cache $IdByShortName -Key $ShortName -Value $ThisID -Type $Type
        $ShortNameByID[$ThisID] = $ShortName

    }

}
