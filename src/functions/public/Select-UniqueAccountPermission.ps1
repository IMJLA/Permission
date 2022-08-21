function Select-UniqueAccountPermission {

    param (

        # Objects output from Format-SecurityPrincipal ... | Group-Object -Property User
        [Parameter(ValueFromPipeline)]
        $AccountPermission,

        <#
        Domain(s) to ignore (they will be removed from the username)

        Intended when a user has matching SamAccountNames in multiple domains but you only want them to appear once on the report.

        Can also be used to remove all domains simply for brevity in the report.
        #>
        [string[]]$IgnoreDomain,

        # Hashtable will be used to deduplicate
        $KnownUsers = [hashtable]::Synchronized(@{})

    )
    process {

        ForEach ($ThisUser in $AccountPermission) {

            $ShortName = $ThisUser.Name
            ForEach ($IgnoreThisDomain in $IgnoreDomain) {
                $ShortName = $ShortName -replace "^$IgnoreThisDomain\\", ''
            }

            $ThisKnownUser = $null
            $ThisKnownUser = $KnownUsers[$ShortName]
            if ($null -eq $ThisKnownUser) {
                $KnownUsers[$ShortName] = [pscustomobject]@{
                    'Name'  = $ShortName
                    'Group' = $ThisUser.Group
                }
            } else {
                $KnownUsers[$ShortName] = [pscustomobject]@{
                    'Name'  = $ShortName
                    'Group' = $ThisKnownUser.Group + $ThisUser.Group
                }
            }
        }

    }
    end {
        $KnownUsers.Values
    }

}
