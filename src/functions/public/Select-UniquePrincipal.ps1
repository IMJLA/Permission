function Select-UniquePrincipal {

    param (

        # Cache of security principals keyed by resolved identity reference
        [hashtable]$PrincipalsByResolvedID = ([hashtable]::Synchronized(@{})),

        # Regular expressions matching names of Users or Groups to exclude from the Html report
        [string[]]$ExcludeAccount,

        <#
        Domain(s) to ignore (they will be removed from the username)

        Intended when a user has matching SamAccountNames in multiple domains but you only want them to appear once on the report.

        Can also be used to remove all domains simply for brevity in the report.
        #>
        [string[]]$IgnoreDomain,

        # Hashtable will be used to deduplicate
        $UniquePrincipal = [hashtable]::Synchronized(@{}),

        $UniquePrincipalsByResolvedID = [hashtable]::Synchronized(@{})

    )

    $FilterContents = @{}

    ForEach ($ThisID in $PrincipalsByResolvedID.Keys) {

        if (
            # Exclude the objects whose names match the regular expressions specified in the parameters
            [bool]$(
                ForEach ($RegEx in $ExcludeAccount) {
                    if ($ThisID -match $RegEx) {
                        $FilterContents[$ThisID] = $ThisID
                        $true
                    }
                }
            )
        ) { continue }

        $ShortName = $ThisID

        ForEach ($IgnoreThisDomain in $IgnoreDomain) {
            $ShortName = $ShortName -replace "^$IgnoreThisDomain\\", ''
        }

        $ThisKnownUser = $null
        $ThisKnownUser = $UniquePrincipal[$ShortName]

        if ($null -eq $ThisKnownUser) {
            $ThisKnownUser = [System.Collections.Generic.List[string]]::new()
        }

        $null = $ThisKnownUser.Add($ThisID)
        $UniquePrincipal[$ShortName] = $ThisKnownUser
        $UniquePrincipalsByResolvedID[$ThisID] = $ShortName

    }

}
