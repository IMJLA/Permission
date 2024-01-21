function Get-FolderPermissionsBlock {
    param (

        # Output from Format-FolderPermission in the PsNtfsModule which has already been piped to Group-Object using the Folder property
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
        $ClassExclusions[$ThisClass] = $true
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
        Where-Object -FilterScript {

            # On built-in groups like 'Authenticated Users' or 'Administrators' the SchemaClassName is null but we have an ObjectType instead.
            # TODO: Research where this difference came from, should these be normalized earlier in the process?
            # A user who was found by being a member of a local group not have an ObjectType (because they are not directly part of the AccessControlEntry)
            # They should have their parent group's AccessControlEntry there...do they?  Doesn't it have a Group ObjectType there?
            if ($_.Group.AccessControlEntry.ObjectType) {
                $Schema = $_.Group.AccessControlEntry.ObjectType | Select-Object -First 1
            } else {
                $Schema = $_.Group.SchemaClassName | Select-Object -First 1
                #TODO: Why is $_.Group.SchemaClassName 'user' for the local Administrators group?
            }

            # Exclude the object whose classes were specified in the parameters
            $SchemaExclusionResult = if ($ExcludeAccountClass.Count -gt 0) {
                $ClassExclusions[$Schema]
            }
            -not $SchemaExclusionResult -and

            # Exclude the objects whose names match the regular expressions specified in the parameters
            ![bool]$(
                ForEach ($RegEx in $ExcludeAccount) {
                    if ($_.Name -match $RegEx) {
                        $FilterContents[$_.Name] = $_
                        $true
                    }
                }
            ) -and

            # Exclude groups with members (the group will be reflected on the report with its members)
            -not (
                #$_.Group.SchemaClassName -contains 'group' -and
                $Schema -eq 'group' -and
                $null -eq $_.Group.IdentityReference
            )

        }

        # Bugfix #48 https://github.com/IMJLA/Export-Permission/issues/48
        # Sending a dummy object down the line to avoid errors
        # TODO: More elegant solution needed. Downstream code should be able to handle null input.
        # TODO: Why does this suppress errors, but the object never appears in the tables?
        if ($null -eq $FilteredAccounts) {
            $FilteredAccounts = [pscustomobject]@{
                'Name'  = 'NoAccountsMatchingCriteria'
                'Group' = [pscustomobject]@{
                    'IdentityReference' = '.'
                    'Access'            = '.'
                    'Name'              = '.'
                    'Department'        = '.'
                    'Title'             = '.'
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
            JsonData    = $ObjectsForJsonData | ConvertTo-Json -AsArray
            JsonColumns = Get-FolderColumnJson -InputObject $ObjectsForFolderPermissionTable -PropNames Account, Access, 'Due to Membership In', Name, Department, Title
            Path        = $ThisFolder.Name
        }
    }
}
