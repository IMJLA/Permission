function Select-UniquePrincipal {

    param (

        # Cache of security principals keyed by resolved identity reference
        [hashtable]$PrincipalsByResolvedID = ([hashtable]::Synchronized(@{})),

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

    ForEach ($ThisID in $PrincipalsByResolvedID.Keys) {
        $ShortName = $ThisID

        ForEach ($IgnoreThisDomain in $IgnoreDomain) {
            $ShortName = $ShortName -replace "^$IgnoreThisDomain\\", ''
        }

        $ThisKnownUser = $null
        $ThisKnownUser = $UniquePrincipal[$ShortName]
        if ($null -eq $ThisKnownUser) {
            $UniquePrincipal[$ShortName] = [System.Collections.Generic.List[string]]::new()

        }

        $null = $UniquePrincipal[$ShortName].Add($ThisID)
        $UniquePrincipalsByResolvedID[$ThisID] = $ShortName

    }

}
