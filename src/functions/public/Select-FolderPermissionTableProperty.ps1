function Select-FolderPermissionTableProperty {
    # For the HTML table
    param (
        $InputObject,
        $IgnoreDomain
    )
    <#
    $InputObject |
    Select-Object -Property @{Label = 'Account'; Expression = { $_.Name } },
    @{Label = 'Access'; Expression = { ($_.Group | Sort-Object -Property IdentityReference -Unique).Access -join ' ; ' } },
    @{Label = 'Due to Membership In'; Expression = {
            $GroupString = ($_.Group.IdentityReference | Sort-Object -Unique) -join ' ; '
            ForEach ($IgnoreThisDomain in $IgnoreDomain) {
                $GroupString = $GroupString -replace "$IgnoreThisDomain\\", ''
            }
            $GroupString
        }
    },
    @{Label = 'Name'; Expression = { $_.Group.Name | Sort-Object -Unique } },
    @{Label = 'Department'; Expression = { $_.Group.Department | Sort-Object -Unique } },
    @{Label = 'Title'; Expression = { $_.Group.Title | Sort-Object -Unique } }
    #>
    ForEach ($Object in $InputObject) {
        $GroupString = ($Object.Group.IdentityReference | Sort-Object -Unique) -join ' ; '
        ForEach ($IgnoreThisDomain in $IgnoreDomain) {
            $GroupString = $GroupString -replace "$IgnoreThisDomain\\", ''
        }
        [pscustomobject]@{
            'Account'              = $Object.Name
            'Access'               = ($Object.Group | Sort-Object -Property IdentityReference -Unique).Access -join ' ; '
            'Due to Membership In' = $GroupString
            'Name'                 = $Object.Group.Name | Sort-Object -Unique
            'Department'           = $Object.Group.Department | Sort-Object -Unique
            'Title'                = $Object.Group.Title | Sort-Object -Unique
        }
    }

}
