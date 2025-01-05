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

        <#
        How to group the permissions in the output stream and within each exported file. Interacts with the SplitBy parameter:

        | SplitBy | GroupBy | Behavior |
        |---------|---------|----------|
        | none    | none    | 1 file with all permissions in a flat list |
        | none    | account | 1 file with all permissions grouped by account |
        | none    | item    | 1 file with all permissions grouped by item |
        | account | none    | 1 file per account; in each file, sort ACEs by item path |
        | account | account | (same as -SplitBy account -GroupBy none) |
        | account | item    | 1 file per account; in each file, group ACEs by item and sort by item path |
        | item    | none    | 1 file per item; in each file, sort ACEs by account name |
        | item    | account | 1 file per item; in each file, group ACEs by account and sort by account name |
        | item    | item    | (same as -SplitBy item -GroupBy none) |
        | source  | none    | 1 file per source path; in each file, sort ACEs by source path |
        | source  | account | 1 file per source path; in each file, group ACEs by account and sort by account name |
        | source  | item    | 1 file per source path; in each file, group ACEs by item and sort by item path |
        | source  | source  | (same as -SplitBy source -GroupBy none) |
        #>
        [ValidateSet('account', 'item', 'none', 'source')]
        [string]$GroupBy = 'item',

        [Hashtable]$HowToSplit,

        # Object output from Invoke-PermissionAnalyzer
        [PSCustomObject]$Analysis,

        # Properties of each Account to display on the report (left out: managedby)
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description')

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

                    'source' {

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

                    'source' {

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
                $StartingPermissions = $Permission.Values | Sort-Object -Property Item, Account -Debug:$false

                # Remove spaces from property titles
                $ObjProps = [ordered]@{}

                if ($StartingPermissions -is [System.Collections.IEnumerable]) {
                    $FirstInputObject = $StartingPermissions[0]
                } else {
                    $FirstInputObject = $StartingPermissions
                }

                $PropNames = $FirstInputObject.PSObject.Properties.GetEnumerator().Name

                ForEach ($Prop in $PropNames) {
                    $ObjProps[$Prop.Replace(' ', '')] = $Prop
                }

                $ObjectsForJsonData = ForEach ($Obj in $StartingPermissions) {

                    $Props = [ordered]@{}

                    ForEach ($PropName in $ObjProps.Keys) {
                        $Props[$PropName] = $Obj.$($ObjProps[$PropName])
                    }

                    if (-not $HowToSplit['Account']) {
                        ForEach ($PropName in $AccountProperty) {
                            $Props[$PropName] = $Obj.$PropName
                        }
                    }

                    [PSCustomObject]$Props

                }

                $TableId = 'Perms'
                $Table = ConvertTo-BootstrapJavaScriptTable -Id $TableId -InputObject $StartingPermissions -DataFilterControl -AllColumnsSearchable -PageSize 25
                if ($GroupBy -eq 'account') {
                    [string[]]$PropNames = @('Path', 'Access', 'Due to Membership In', 'Source of Access')
                } else {
                    [string[]]$PropNames = @('Path', 'Account', 'Access', 'Due to Membership In', 'Source of Access', 'Name') + $AccountProperty
                }

                [PSCustomObject]@{
                    PSTypeName = 'Permission.PermissionList'
                    Columns    = Get-ColumnJson -InputObject $StartingPermissions -PropNames $PropNames
                    Data       = ConvertTo-Json -Compress -InputObject @($ObjectsForJsonData)
                    Div        = New-BootstrapDiv -Text ($Heading + $Table) -Class 'h-100 p-1 bg-light border rounded-3 table-responsive'
                    PassThru   = $ObjectsForJsonData
                    Table      = $TableId
                }

            } else {

                switch ($GroupBy) {

                    'account' {

                        ForEach ($GroupID in ($Permission.Keys | Sort-Object)) {

                            $Heading = New-HtmlHeading "Items accessible to $GroupID" -Level 6
                            $StartingPermissions = $Permission[$GroupID]

                            # Remove spaces from property titles

                            $ObjProps = [ordered]@{}

                            if ($StartingPermissions -is [System.Collections.IEnumerable]) {
                                $FirstInputObject = $StartingPermissions[0]
                            } else {
                                $FirstInputObject = $StartingPermissions
                            }

                            $PropNames = $FirstInputObject.PSObject.Properties.GetEnumerator().Name

                            ForEach ($Prop in $PropNames) {
                                $ObjProps[$Prop.Replace(' ', '')] = $Prop
                            }

                            $ObjectsForJsonData = ForEach ($Obj in $StartingPermissions) {

                                $Props = [ordered]@{}

                                ForEach ($PropName in $ObjProps.Keys) {
                                    $Props[$PropName] = $Obj.$($ObjProps[$PropName])
                                }

                                if (-not $HowToSplit['Account']) {
                                    ForEach ($PropName in $AccountProperty) {
                                        $Props[$PropName] = $Obj.$PropName
                                    }
                                }

                                [PSCustomObject]$Props

                            }

                            $TableId = "Perms_$($GroupID -replace '[^A-Za-z0-9\-_]', '-')"
                            $Table = ConvertTo-BootstrapJavaScriptTable -Id $TableId -InputObject $StartingPermissions -DataFilterControl -AllColumnsSearchable
                            $DivId = $TableId.Replace('Perms', 'Div')

                            [PSCustomObject]@{
                                PSTypeName = 'Permission.AccountPermissionList'
                                Columns    = Get-ColumnJson -InputObject $StartingPermissions -PropNames $PropNames
                                Data       = ConvertTo-Json -Compress -InputObject @($ObjectsForJsonData)
                                Div        = New-BootstrapDiv -Id $DivId -Text ($Heading + $Table) -Class 'h-100 p-1 bg-light border rounded-3 table-responsive'
                                PassThru   = $ObjectsForJsonData
                                Grouping   = $GroupID
                                Table      = $TableId
                            }

                        }
                        break

                    }

                    'item' {

                        ForEach ($Group in $PermissionGrouping) {

                            if ($null -ne $Group.Account) {
                                [string[]]$PropNames = @('Access', 'Due to Membership In', 'Source of Access')
                                $GroupID = $Group.Access.Item.Path
                                $Heading = New-HtmlHeading "Access to $GroupID" -Level 6
                                $SubHeading = 'This account has the below access to this item and its children, except children with inheritance disabled.'
                            } else {
                                [string[]]$PropNames = @('Account', 'Access', 'Due to Membership In', 'Source of Access', 'Name') + $AccountProperty
                                $GroupID = $Group.Item.Path
                                $Heading = New-HtmlHeading "Accounts with access to $GroupID" -Level 6
                                $SubHeading = Get-FolderPermissionTableHeader -Group $Group -GroupID $GroupID -ShortestFolderPath $ShortestPath
                            }

                            $StartingPermissions = $Permission[$GroupID]

                            if ($StartingPermissions) {

                                # Remove spaces from property titles
                                $ObjProps = [ordered]@{}

                                ForEach ($Prop in $PropNames) {
                                    $ObjProps[$Prop.Replace(' ', '')] = $Prop
                                }

                                $ObjectsForJsonData = ForEach ($Obj in $StartingPermissions) {

                                    $Props = [ordered]@{}

                                    ForEach ($PropName in $ObjProps.Keys) {
                                        $Props[$PropName] = $Obj.$($ObjProps[$PropName])
                                    }

                                    [PSCustomObject]$Props

                                }

                                $TableId = "Perms_$($GroupID -replace '[^A-Za-z0-9\-_]', '-')"
                                $DivId = $TableId.Replace('Perms', 'Div')
                                $Table = ConvertTo-BootstrapJavaScriptTable -Id $TableId -InputObject $StartingPermissions -DataFilterControl -AllColumnsSearchable

                                [PSCustomObject]@{
                                    PSTypeName = 'Permission.ItemPermissionList'
                                    Columns    = Get-ColumnJson -InputObject $StartingPermissions -PropNames $PropNames
                                    Data       = ConvertTo-Json -Compress -InputObject @($ObjectsForJsonData)
                                    Div        = New-BootstrapDiv -Id $DivId -Text ($Heading + $SubHeading + $Table) -Class 'h-100 p-1 bg-light border rounded-3 table-responsive'
                                    Grouping   = $GroupID
                                    PassThru   = $ObjectsForJsonData
                                    Table      = $TableId
                                }

                            }

                        }
                        break

                    }

                    'source' {

                        ForEach ($Group in $PermissionGrouping) {

                            $GroupID = $Group.Path
                            $Heading = New-HtmlHeading "Permissions in $GroupID" -Level 5
                            $StartingPermissions = $Permission[$GroupID]

                            # Remove spaces from property titles
                            $ObjectsForJsonData = ForEach ($Obj in $StartingPermissions) {

                                $Props = [ordered]@{
                                    Item              = $Obj.Item
                                    Account           = $Obj.Account
                                    Access            = $Obj.Access
                                    DuetoMembershipIn = $Obj.'Due to Membership In'
                                    SourceofAccess    = $Obj.'Source of Access'
                                    Name              = $Obj.Name
                                }

                                ForEach ($PropName in $AccountProperty) {
                                    $Props[$PropName] = $Obj.$PropName
                                }

                                [PSCustomObject]$Props

                            }

                            $TableId = "Perms_$($GroupID -replace '[^A-Za-z0-9\-_]', '-')"
                            $DivId = $TableId.Replace('Perms', 'Div')
                            $Table = ConvertTo-BootstrapJavaScriptTable -Id $TableId -InputObject $StartingPermissions -DataFilterControl -AllColumnsSearchable -PageSize 25
                            [string[]]$PropNames = @('Path', 'Account', 'Access', 'Due to Membership In', 'Source of Access', 'Name') + $AccountProperty

                            [PSCustomObject]@{
                                PSTypeName = 'Permission.TargetPermissionList'
                                Columns    = Get-ColumnJson -InputObject $StartingPermissions -PropNames $PropNames
                                Data       = ConvertTo-Json -Compress -InputObject @($ObjectsForJsonData)
                                Div        = New-BootstrapDiv -Id $DivId -Text ($Heading + $Table) -Class 'h-100 p-1 bg-light border rounded-3 table-responsive'
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

                    'source' {

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
