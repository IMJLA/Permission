function ConvertTo-PermissionList {

    param (

        # Permission object from Expand-Permission
        [Hashtable]$Permission,

        [PSCustomObject[]]$PermissionGrouping,

        # Type of output returned to the output stream
        [ValidateSet('csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [String]$Format,

        [String]$ShortestPath,

        [String]$NetworkPath,

        # How to group the permissions in the output stream and within each exported file
        [ValidateSet('account', 'item', 'none', 'target')]
        [String]$GroupBy = 'item',

        [Hashtable]$HowToSplit,

        [PSCustomObject]$Analysis

    )

    switch ($Format) {

        'csv' {

            if (
                $GroupBy -eq 'none' -or
                $HowToSplit[$GroupBy]
            ) {

                $Sorted = $Permission.Values | Sort-Object -Property Item, Account

                [PSCustomObject]@{
                    PSTypeName = 'Permission.PermissionList'
                    Data       = $Sorted | ConvertTo-Csv
                    PassThru   = $Sorted
                }

            } else {

                switch ($GroupBy) {

                    'account' {

                        ForEach ($Group in $PermissionGrouping) {
                            [PSCustomObject]@{
                                PSTypeName = 'Permission.PermissionList'
                                Data       = $Permission[$Group.Account.ResolvedAccountName] | ConvertTo-Csv
                                PassThru   = $Permission[$Group.Account.ResolvedAccountName]
                                Grouping   = $Group.Account.ResolvedAccountName
                            }
                        }
                        break

                    }

                    'item' {

                        ForEach ($Group in $PermissionGrouping) {
                            [PSCustomObject]@{
                                PSTypeName = 'Permission.PermissionList'
                                Data       = $Permission[$Group.Item.Path] | ConvertTo-Csv
                                PassThru   = $Permission[$Group.Item.Path]
                                Grouping   = $Group.Item.Path
                            }
                        }
                        break

                    }

                    'target' {

                        ForEach ($Group in $PermissionGrouping) {

                            $Perm = $Permission[$Group.Path]

                            if ($Perm) {
                                [PSCustomObject]@{
                                    PSTypeName = 'Permission.PermissionList'
                                    Data       = $Perm | ConvertTo-Csv
                                    Grouping   = $Group.Path
                                    PassThru   = $Perm
                                }

                            }

                        }
                        break

                    }

                }

            }
            break

        }

        'html' {

            if (
                $GroupBy -eq 'none' -or
                $HowToSplit[$GroupBy]
            ) {

                $Heading = New-HtmlHeading "Permissions in $NetworkPath" -Level 6
                $Sorted = $Permission.Values | Sort-Object -Property Item, Account
                $Html = $Sorted | ConvertTo-Html -Fragment
                $Table = $Html | New-BootstrapTable

                [PSCustomObject]@{
                    PSTypeName = 'Permission.PermissionList'
                    Data       = $Html
                    Div        = New-BootstrapDiv -Text ($Heading + $Table) -Class 'h-100 p-1 bg-light border rounded-3 table-responsive'
                    PassThru   = $Sorted
                }

            } else {

                switch ($GroupBy) {

                    'account' {

                        ##ForEach ($Group in $PermissionGrouping) {
                        ForEach ($GroupID in $Permission.Keys) {

                            ##$GroupID = $Group.Account.ResolvedAccountName
                            $Heading = New-HtmlHeading "Folders accessible to $GroupID" -Level 6
                            $StartingPermissions = $Permission[$GroupID]
                            $Html = $StartingPermissions | ConvertTo-Html -Fragment
                            $Table = $Html | New-BootstrapTable

                            [PSCustomObject]@{
                                PSTypeName = 'Permission.PermissionList'
                                Data       = $Html
                                Div        = New-BootstrapDiv -Text ($Heading + $Table) -Class 'h-100 p-1 bg-light border rounded-3 table-responsive'
                                Grouping   = $GroupID
                                PassThru   = $StartingPermissions
                            }

                        }
                        break

                    }

                    'item' {

                        ForEach ($Group in $PermissionGrouping) {

                            $GroupID = $Group.Item.Path
                            $Heading = New-HtmlHeading "Accounts with access to $GroupID" -Level 6
                            $SubHeading = Get-FolderPermissionTableHeader -Group $Group -GroupID $GroupID -ShortestFolderPath $ShortestPath
                            $StartingPermissions = $Permission[$GroupID]
                            $Html = $StartingPermissions | ConvertTo-Html -Fragment
                            $Table = $Html | New-BootstrapTable

                            [PSCustomObject]@{
                                PSTypeName = 'Permission.PermissionList'
                                Data       = $Html
                                Div        = New-BootstrapDiv -Text ($Heading + $SubHeading + $Table) -Class 'h-100 p-1 bg-light border rounded-3 table-responsive'
                                Grouping   = $GroupID
                                PassThru   = $StartingPermissions
                            }

                        }
                        break

                    }

                    'target' {

                        ForEach ($Group in $PermissionGrouping) {

                            $GroupID = $Group.Path
                            $Heading = New-HtmlHeading "Permissions in $GroupID" -Level 5
                            $StartingPermissions = $Permission[$GroupID]
                            $Html = $StartingPermissions | ConvertTo-Html -Fragment
                            $Table = $Html | New-BootstrapTable

                            [PSCustomObject]@{
                                PSTypeName = 'Permission.PermissionList'
                                Data       = $Html
                                Div        = New-BootstrapDiv -Text ($Heading + $Table) -Class 'h-100 p-1 bg-light border rounded-3 table-responsive'
                                Grouping   = $GroupID
                                PassThru   = $StartingPermissions
                            }

                        }
                        break

                    }

                }

            }
            break

        }

        'js' {

            if (
                $GroupBy -eq 'none' -or
                $HowToSplit[$GroupBy]
            ) {

                $Heading = New-HtmlHeading "Permissions in $NetworkPath" -Level 6
                $StartingPermissions = $Permission.Values | Sort-Object -Property Item, Account

                # Remove spaces from property titles
                $ObjectsForJsonData = ForEach ($Obj in $StartingPermissions) {
                    [PSCustomObject]@{
                        Item              = $Obj.Item
                        Account           = $Obj.Account
                        Access            = $Obj.Access
                        DuetoMembershipIn = $Obj.'Due to Membership In'
                        SourceofAccess    = $Obj.'Source of Access'
                        Name              = $Obj.Name
                        Department        = $Obj.Department
                        Title             = $Obj.Title
                    }

                }

                $TableId = 'Perms'
                $Table = ConvertTo-BootstrapJavaScriptTable -Id $TableId -InputObject $StartingPermissions -DataFilterControl -AllColumnsSearchable -PageSize 25

                [PSCustomObject]@{
                    PSTypeName = 'Permission.PermissionList'
                    Columns    = Get-ColumnJson -InputObject $StartingPermissions -PropNames Item, Account, Access, 'Due to Membership In', 'Source of Access', Name, Department, Title
                    Data       = ConvertTo-Json -Compress -InputObject @($ObjectsForJsonData)
                    Div        = New-BootstrapDiv -Text ($Heading + $Table) -Class 'h-100 p-1 bg-light border rounded-3 table-responsive'
                    PassThru   = $ObjectsForJsonData
                    Table      = $TableId
                }

            } else {

                switch ($GroupBy) {

                    'account' {

                        ##ForEach ($Group in $PermissionGrouping) {
                        ForEach ($GroupID in $Permission.Keys) {
                            # TODO: $Permission.Keys | Sort-Object would result in this being sorted, but this wasn't needed previously.  Investigate to avoid redundant sorting.

                            ##$GroupID = $Group.Account.ResolvedAccountName
                            $Heading = New-HtmlHeading "Items accessible to $GroupID" -Level 6
                            $StartingPermissions = $Permission[$GroupID]

                            # Remove spaces from property titles
                            $ObjectsForJsonData = ForEach ($Obj in $StartingPermissions) {
                                [PSCustomObject]@{
                                    Path              = $Obj.Path
                                    Access            = $Obj.Access
                                    DuetoMembershipIn = $Obj.'Due to Membership In'
                                    SourceofAccess    = $Obj.'Source of Access'
                                }
                            }

                            $TableId = "Perms_$($GroupID -replace '[^A-Za-z0-9\-_]', '-')"
                            $Table = ConvertTo-BootstrapJavaScriptTable -Id $TableId -InputObject $StartingPermissions -DataFilterControl -AllColumnsSearchable

                            [PSCustomObject]@{
                                PSTypeName = 'Permission.AccountPermissionList'
                                Columns    = Get-ColumnJson -InputObject $StartingPermissions-PropNames Path, Access, 'Due to Membership In', 'Source of Access'
                                Data       = ConvertTo-Json -Compress -InputObject @($ObjectsForJsonData)
                                Div        = New-BootstrapDiv -Text ($Heading + $Table) -Class 'h-100 p-1 bg-light border rounded-3 table-responsive'
                                PassThru   = $ObjectsForJsonData
                                Grouping   = $GroupID
                                Table      = $TableId
                            }

                        }
                        break

                    }

                    'item' {

                        ForEach ($Group in $PermissionGrouping) {

                            $GroupID = $Group.Item.Path
                            $Heading = New-HtmlHeading "Accounts with access to $GroupID" -Level 6
                            $SubHeading = Get-FolderPermissionTableHeader -Group $Group -GroupID $GroupID -ShortestFolderPath $ShortestPath
                            $StartingPermissions = $Permission[$GroupID]

                            if ($StartingPermissions) {

                                # Remove spaces from property titles
                                $ObjectsForJsonData = ForEach ($Obj in $StartingPermissions) {
                                    [PSCustomObject]@{
                                        Account           = $Obj.Account
                                        Access            = $Obj.Access
                                        DuetoMembershipIn = $Obj.'Due to Membership In'
                                        SourceofAccess    = $Obj.'Source of Access'
                                        Name              = $Obj.Name
                                        Department        = $Obj.Department
                                        Title             = $Obj.Title
                                    }
                                }

                                $TableId = "Perms_$($GroupID -replace '[^A-Za-z0-9\-_]', '-')"
                                $Table = ConvertTo-BootstrapJavaScriptTable -Id $TableId -InputObject $StartingPermissions -DataFilterControl -AllColumnsSearchable

                                [PSCustomObject]@{
                                    PSTypeName = 'Permission.ItemPermissionList'
                                    Columns    = Get-ColumnJson -InputObject $StartingPermissions -PropNames Account, Access, 'Due to Membership In', 'Source of Access', Name, Department, Title
                                    Data       = ConvertTo-Json -Compress -InputObject @($ObjectsForJsonData)
                                    Div        = New-BootstrapDiv -Text ($Heading + $SubHeading + $Table) -Class 'h-100 p-1 bg-light border rounded-3 table-responsive'
                                    Grouping   = $GroupID
                                    PassThru   = $ObjectsForJsonData
                                    Table      = $TableId
                                }

                            }

                        }
                        break

                    }

                    'target' {

                        ForEach ($Group in $PermissionGrouping) {

                            $GroupID = $Group.Path
                            $Heading = New-HtmlHeading "Permissions in $GroupID" -Level 5
                            $StartingPermissions = $Permission[$GroupID]

                            # Remove spaces from property titles
                            $ObjectsForJsonData = ForEach ($Obj in $StartingPermissions) {
                                [PSCustomObject]@{
                                    #Path                 = $Obj.Item.Path
                                    #Access               = ($Obj.Access.Access.Access | Sort-Object -Unique) -join ' ; '
                                    #SourceofAccess = ($Obj.Access.Access.SourceOfAccess | Sort-Object -Unique) -join ' ; '

                                    Item              = $Obj.Item
                                    Account           = $Obj.Account
                                    Access            = $Obj.Access
                                    DuetoMembershipIn = $Obj.'Due to Membership In'
                                    SourceofAccess    = $Obj.'Source of Access'
                                    Name              = $Obj.Name
                                    Department        = $Obj.Department
                                    Title             = $Obj.Title
                                }
                            }

                            $TableId = "Perms_$($GroupID -replace '[^A-Za-z0-9\-_]', '-')"
                            $Table = ConvertTo-BootstrapJavaScriptTable -Id $TableId -InputObject $StartingPermissions -DataFilterControl -AllColumnsSearchable -PageSize 25

                            [PSCustomObject]@{
                                PSTypeName = 'Permission.TargetPermissionList'
                                Columns    = Get-ColumnJson -InputObject $StartingPermissions -PropNames Item, Account, Access, 'Due to Membership In', 'Source of Access', Name, Department, Title
                                Data       = ConvertTo-Json -Compress -InputObject @($ObjectsForJsonData)
                                Div        = New-BootstrapDiv -Text ($Heading + $Table) -Class 'h-100 p-1 bg-light border rounded-3 table-responsive'
                                Grouping   = $GroupID
                                PassThru   = $ObjectsForJsonData
                                Table      = $TableId
                            }

                        }
                        break

                    }

                }

            }
            break

        }

        'prtgxml' {

            # Format the issues as a custom XML sensor for Paessler PRTG Network Monitor
            [PSCustomObject]@{
                PSTypeName = 'Permission.BestPracticeAnalysisPrtg'
                Data       = ConvertTo-PermissionPrtgXml -Analysis $Analysis
                PassThru   = $Analysis
            }
            break

        }

        'xml' {

            if (
                $GroupBy -eq 'none' -or
                $HowToSplit[$GroupBy]
            ) {

                [PSCustomObject]@{
                    PSTypeName = 'Permission.PermissionList'
                    Data       = ($Permission.Values | ConvertTo-Xml).InnerXml
                    PassThru   = $Permission.Values
                }

            } else {

                switch ($GroupBy) {

                    'account' {

                        ForEach ($Group in $PermissionGrouping) {
                            [PSCustomObject]@{
                                PSTypeName = 'Permission.AccountPermissionList'
                                Data       = ($Permission[$Group.Account.ResolvedAccountName] | ConvertTo-Xml).InnerXml
                                PassThru   = $Permission[$Account.ResolvedAccountName]
                                Grouping   = $Account.ResolvedAccountName
                            }
                        }
                        break

                    }

                    'item' {

                        ForEach ($Group in $PermissionGrouping) {
                            [PSCustomObject]@{
                                PSTypeName = 'Permission.ItemPermissionList'
                                Data       = ($Permission[$Group.Item.Path] | ConvertTo-Xml).InnerXml
                                PassThru   = $Permission[$Group.Item.Path]
                                Grouping   = $Group.Item.Path
                            }
                        }
                        break

                    }

                    'target' {

                        ForEach ($Group in $PermissionGrouping) {
                            [PSCustomObject]@{
                                PSTypeName = 'Permission.TargetPermissionList'
                                Data       = ($Permission[$Group.Path] | ConvertTo-Xml).InnerXml
                                PassThru   = $Permission[$Group.Path]
                                Grouping   = $Group.Path
                            }
                        }
                        break

                    }

                }

            }
            break

        }

    }

}
