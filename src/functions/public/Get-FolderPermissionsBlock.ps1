function Get-FolderPermissionsBlock {
    param (

        $FolderPermissions,

        # Regular expressions matching names of Users or Groups to exclude from the Html report
        [string[]]$ExcludeAccount,

        $ExcludeEmptyGroups,

        <#
        Domain(s) to ignore (they will be removed from the username)

        Intended when a user has matching SamAccountNames in multiple domains but you only want them to appear once on the report.

        Can also be used to remove all domains simply for brevity in the report.
        #>
        [string[]]$IgnoreDomain

    )

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

        if ($ExcludeEmptyGroups) {
            $FilteredAccounts = $FilteredAccounts |
            Where-Object -FilterScript {
                # Eliminate empty groups (not useful to see in the middle of a list of users/job titles/departments/etc).
                $_.Group.SchemaClassName -notcontains 'group'
            }
        }

        $ObjectsForFolderPermissionTable = Select-FolderPermissionTableProperty -InputObject $FilteredAccounts -IgnoreDomain $IgnoreDomain |
        Sort-Object -Property Name

        $ThisTable = $ObjectsForFolderPermissionTable |
        ConvertTo-Html -Fragment |
        New-BootstrapTable

        $ThisJsonTable = ConvertTo-BootstrapJavaScriptTable -Id "#$($ThisFolder.Name)" -InputObject $ObjectsForFolderPermissionTable -DataFilterControl -AllColumnsSearchable

        [pscustomobject]@{
            HtmlDiv     = New-BootstrapDiv -Text ($ThisHeading + $ThisSubHeading + $ThisTable)
            JsonDiv     = New-BootstrapDiv -Text ($ThisHeading + $ThisSubHeading + $ThisJsonTable)
            JsonData    = $ObjectsForFolderPermissionTable | ConvertTo-Json
            JsonColumns = Get-FolderColumnJson -InputObject $ObjectsForFolderPermissionTable
        }
    }
}
