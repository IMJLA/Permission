function Get-FolderPermissionsBlock {
    param (
        $FolderPermissions,
        # Regular expressions that will identify Users or Groups you do not want included in the Html report
        [string[]]$ExcludeAccount,
        $ExcludeEmptyGroups,
        $IgnoreDomain
    )

    $ShortestFolderPath = $ThisFolder.Name |
    Sort-Object |
    Select-Object -First 1

    ForEach ($ThisFolder in $FolderPermissions) {

        $ThisHeading = New-HtmlHeading "Accounts with access to $($ThisFolder.Name)" -Level 5

        $Leaf = $ThisFolder.Name | Split-Path -Parent | Split-Path -Leaf -ErrorAction SilentlyContinue

        if ($Leaf) {
            $ParentLeaf = $Leaf
        } else {
            $ParentLeaf = $ThisFolder.Name | Split-Path -Parent
        }
        if ('' -ne $ParentLeaf) {
            if (($ThisFolder.Group.FolderInheritanceEnabled | Select-Object -First 1) -eq $true) {
                if ($ThisFolder.Name -eq $ShortestFolderPath) {
                    $ThisSubHeading = "Inherited permissions from the parent folder ($ParentLeaf) are included.  This folder can only be accessed by the users listed below:"
                } else {
                    $ThisSubHeading = "Accounts with access to the parent folder and subfolders ($ParentLeaf) can access this folder. So can any users listed below:"
                }
            } else {
                $ThisSubHeading = "Accounts with access to the parent folder and subfolders ($ParentLeaf) cannot access this folder unless they are listed below:"
            }
        } else {
            $ThisSubHeading = "This is the top-level folder. It can only be accessed by the users listed below:"
        }

        $FilteredAccounts = $ThisFolder.Group |
        Group-Object -Property Account |
        # Skip the accounts we need to skip
        Where-Object -FilterScript {
            ![bool]$(
                ForEach ($RegEx in $ExcludeAccount) {
                    if ($_.Name -match $RegEx) {
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
                #Eliminate empty groups (not useful to see in the middle of a list of users/job titles/departments/etc).
                $_.Group.SchemaClassName -notcontains 'group'
            }
        }

        $ThisTable = $FilteredAccounts |
        Select-Object -Property @{Label = 'Account'; Expression = { $_.Name } },
        @{Label = 'Access'; Expression = { ($_.Group | Sort-Object -Property IdentityReference -Unique).Access -join ' ; ' } },
        @{Label = 'Due to Membership In'; Expression = {
                $GroupString = ($_.Group.IdentityReference | Sort-Object -Unique) -join ' ; '
                ForEach ($IgnoreThisDomain in $IgnoreDomain) {
                    $GroupString = $GroupString -replace $IgnoreThisDomain, ''
                }
                $GroupString
            }
        },
        @{Label = 'Name'; Expression = { $_.Group.Name | Sort-Object -Unique } },
        @{Label = 'Department'; Expression = { $_.Group.Department | Sort-Object -Unique } },
        @{Label = 'Title'; Expression = { $_.Group.Title | Sort-Object -Unique } } |
        ConvertTo-Html -Fragment |
        New-BootstrapTable

        New-BootstrapDiv -Text ($ThisHeading + $ThisSubHeading + $ThisTable)
    }
}
