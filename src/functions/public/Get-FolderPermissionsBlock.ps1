function Get-FolderPermissionsBlock {
    param (

        $FolderPermissions,

        # Regular expressions matching names of Users or Groups to exclude from the Html report
        [string[]]$ExcludeAccount,

        # Accounts whose objectClass property is in this list are excluded from the HTML report
        [string[]]$ExcludeAccountClass = @('group', 'computer'),

        <#
        Domain(s) to ignore (they will be removed from the username)

        Intended when a user has matching SamAccountNames in multiple domains but you only want them to appear once on the report.

        Can also be used to remove all domains simply for brevity in the report.
        #>
        [string[]]$IgnoreDomain

    )

    # Convert the $ExcludeAccountClass array into a dictionary for fast lookups
    $ClassExclusions = @{}
    ForEach ($ThisClass in $ExcludeAccountClass) {
        $ClassExclusions[$_] = $true
    }

    $ShortestFolderPath = $FolderPermissions.Name |
    Sort-Object |
    Select-Object -First 1

    ForEach ($ThisFolder in $FolderPermissions) {

        $ThisHeading = New-HtmlHeading "Accounts with access to $($ThisFolder.Name)" -Level 5

        $ThisSubHeading = Get-FolderPermissionTableHeader -ThisFolder $ThisFolder -ShortestFolderPath $ShortestFolderPath

        $FilterContents = @{}
        $FilteredAccounts = $ThisFolder.Group |
        Group-Object -Property Account |
        # Skip the accounts we need to skip
        Where-Object -FilterScript {
            ![bool]$(
                ForEach ($RegEx in $ExcludeAccount) {
                    if ($_.Name -match $RegEx) {
                        $FilterContents[$_.Name] = $_
                        $true
                    }
                }
            )
        }

        # Exclude groups with members (the group will be reflected on the report with its members)
        $FilteredAccounts = $FilteredAccounts |
        Where-Object -FilterScript {
            -not (
                $_.Group.SchemaClassName -contains 'group' -and
                $null -eq $_.Group.IdentityReference
            )
        }

        # Eliminate the specified classes, such as groups
        # (any remaining groups are empty and not useful to see in the middle of a list of users/job titles/departments/etc)
        if ($ExcludeAccountClass.Count -ge 0) {
            $FilteredAccounts = $FilteredAccounts |
            Where-Object -FilterScript {
                ForEach ($Schema in $_.Group.SchemaClassName) {
                    if ($ClassExclusions[$Schema]) {
                        $true
                    }
                }
            }
        }

        $ObjectsForFolderPermissionTable = Select-FolderPermissionTableProperty -InputObject $FilteredAccounts -IgnoreDomain $IgnoreDomain |
        Sort-Object -Property Name

        $ThisTable = $ObjectsForFolderPermissionTable |
        ConvertTo-Html -Fragment |
        New-BootstrapTable

        $TableId = $ThisFolder.Name -replace '[^A-Za-z0-9\-_:.]', '-'


        $ThisJsonTable = ConvertTo-BootstrapJavaScriptTable -Id "Perms_$TableId" -InputObject $ObjectsForFolderPermissionTable -DataFilterControl -AllColumnsSearchable

        # Remove spaces from property titles
        $ObjectsForJsonData = $ObjectsForFolderPermissionTable |
        Select-Object -Property Account, Access, @{Label = 'DuetoMembershipIn'; Expression = { $_.'Due to Membership In' } }, Name, Department, Title

        [pscustomobject]@{
            HtmlDiv     = New-BootstrapDiv -Text ($ThisHeading + $ThisSubHeading + $ThisTable)
            JsonDiv     = New-BootstrapDiv -Text ($ThisHeading + $ThisSubHeading + $ThisJsonTable)
            JsonData    = $ObjectsForJsonData | ConvertTo-Json
            JsonColumns = Get-FolderColumnJson -InputObject $ObjectsForFolderPermissionTable -PropNames Account, Access, 'Due to Membership In', Name, Department, Title
            Path        = $ThisFolder.Name
        }
    }
}
