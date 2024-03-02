function ConvertTo-PermissionList {

    param (

        # Permission object from Expand-Permission
        [hashtable]$Permission,

        [PSCustomObject[]]$PermissionGrouping,

        # Type of output returned to the output stream
        [ValidateSet('csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [string]$Format,

        [string]$ShortestPath,

        [string]$GroupBy

    )

    # TODO: Replace .Item.Path with GroupingProperty variable somehow
    #$GroupingProperty = @($PermissionGrouping[0] | Get-Member -Type NoteProperty)[0].Name

    switch ($Format) {

        'csv' {

            if ($GroupBy -eq 'none') {

                $OutputObject = @{}
                $OutputObject['Data'] = $Permission.Values | Sort-Object -Property Item, Account | ConvertTo-Csv
                [PSCustomObject]$OutputObject

            } else {

                ForEach ($Group in $PermissionGrouping) {
                    $OutputObject = @{}
                    $OutputObject['Data'] = $Permission[$Group.Item.Path] | ConvertTo-Csv
                    [PSCustomObject]$OutputObject
                }

            }

        }

        'html' {

            if ($GroupBy -eq 'none') {

                $OutputObject = @{}
                $Heading = New-HtmlHeading 'Permissions' -Level 5
                $Html = $Permission.Values | ConvertTo-Html -Fragment
                $OutputObject['Data'] = $Html
                $Table = $Html | New-BootstrapTable
                $OutputObject['Div'] = New-BootstrapDiv -Text ($Heading + $Table)
                [PSCustomObject]$OutputObject

            } else {

                ForEach ($Group in $PermissionGrouping) {

                    $OutputObject = @{}
                    $GroupID = $Group.Item.Path
                    $Heading = New-HtmlHeading "Accounts with access to $GroupID" -Level 5
                    $SubHeading = Get-FolderPermissionTableHeader -Group $Group -GroupID $GroupID -ShortestFolderPath $ShortestPath
                    $Perm = $Permission[$GroupID]
                    $Html = $Perm | ConvertTo-Html -Fragment
                    $OutputObject['Data'] = $Html
                    $Table = $Html | New-BootstrapTable
                    $OutputObject['Div'] = New-BootstrapDiv -Text ($Heading + $SubHeading + $Table)
                    [PSCustomObject]$OutputObject

                }

            }

        }

        'json' {

            if ($GroupBy -eq 'none') {

                $OutputObject = @{}
                $Heading = New-HtmlHeading 'Permissions' -Level 5

                # Remove spaces from property titles
                $ObjectsForJsonData = ForEach ($Obj in $Permission.Values) {
                    [PSCustomObject]@{
                        Item              = $Obj.ItemPath
                        Account           = $Obj.ResolvedAccountName
                        Access            = $Obj.Access
                        DuetoMembershipIn = $Obj.'Due to Membership In'
                        SourceofAccess    = $Obj.'Source of Access'
                        Name              = $Obj.Name
                        Department        = $Obj.Department
                        Title             = $Obj.Title
                    }

                }

                $OutputObject['Data'] = ConvertTo-Json -Compress -InputObject @($ObjectsForJsonData)
                $OutputObject['Columns'] = Get-FolderColumnJson -InputObject $Permission.Values -PropNames Item, Account, Access, 'Due to Membership In', 'Source of Access', Name, Department, Title
                $TableId = 'Perms'
                $OutputObject['Table'] = $TableId
                $Table = ConvertTo-BootstrapJavaScriptTable -Id $TableId -InputObject $Permission.Values -DataFilterControl -AllColumnsSearchable
                $OutputObject['Div'] = New-BootstrapDiv -Text ($Heading + $Table)
                [PSCustomObject]$OutputObject

            } else {

                ForEach ($Group in $PermissionGrouping) {

                    $OutputObject = @{}
                    $GroupID = $Group.Item.Path
                    $Heading = New-HtmlHeading "Accounts with access to $GroupID" -Level 5
                    $SubHeading = Get-FolderPermissionTableHeader -Group $Group -GroupID $GroupID -ShortestFolderPath $ShortestPath
                    $Perm = $Permission[$GroupID]

                    # Remove spaces from property titles
                    $ObjectsForJsonData = ForEach ($Obj in $Perm) {
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

                    $OutputObject['Data'] = ConvertTo-Json -Compress -InputObject @($ObjectsForJsonData)
                    $OutputObject['Columns'] = Get-FolderColumnJson -InputObject $Perm -PropNames Account, Access, 'Due to Membership In', 'Source of Access', Name, Department, Title
                    $TableId = "Perms_$($Group.Item.Path -replace '[^A-Za-z0-9\-_]', '-')"
                    $OutputObject['Table'] = $TableId
                    $Table = ConvertTo-BootstrapJavaScriptTable -Id $TableId -InputObject $Perm -DataFilterControl -AllColumnsSearchable
                    $OutputObject['Div'] = New-BootstrapDiv -Text ($Heading + $SubHeading + $Table)
                    [PSCustomObject]$OutputObject

                }

            }

        }

        'prtgxml' {

            <#

            # ToDo: Users with ownership
            $NtfsIssueParams = @{
                FolderPermissions = $Permission.ItemPermissions
                UserPermissions   = $Permission.AccountPermissions
                GroupNameRule     = $GroupNameRule
                TodaysHostname    = $ThisHostname
                WhoAmI            = $WhoAmI
                LogMsgCache       = $LogCache
            }

            Write-LogMsg @LogParams -Text 'New-NtfsAclIssueReport @NtfsIssueParams'
            $NtfsIssues = New-NtfsAclIssueReport @NtfsIssueParams

            # Format the issues as a custom XML sensor for Paessler PRTG Network Monitor
            Write-LogMsg @LogParams -Text "Get-PrtgXmlSensorOutput -NtfsIssues `$NtfsIssues"
            $OutputObject['Data'] = Get-PrtgXmlSensorOutput -NtfsIssues $NtfsIssues
            [PSCustomObject]$OutputObject
            #>

        }

        'xml' {

            if ($GroupBy -eq 'none') {

                $OutputObject = @{}
                $OutputObject['Data'] = ($Permission.Values | ConvertTo-Xml).InnerXml
                [PSCustomObject]$OutputObject

            } else {

                ForEach ($Group in $PermissionGrouping) {
                    $OutputObject = @{}
                    $OutputObject['Data'] = ($Permission[$Group.Item.Path] | ConvertTo-Xml).InnerXml
                    [PSCustomObject]$OutputObject
                }

            }

        }

        default {}

    }

    return

}
