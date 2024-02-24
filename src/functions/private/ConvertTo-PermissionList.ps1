function ConvertTo-PermissionList {

    param (

        # Permission object from Expand-Permission
        [PSCustomObject]$Permission,

        # Type of output returned to the output stream
        [ValidateSet('csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [string]$Format,

        <#
        Level of detail to export to file
            0   Item paths                                                                                  $TargetPath
            1   Resolved item paths (server names resolved, DFS targets resolved)                           $ACLsByPath.Keys after Resolve-PermissionTarget but before Expand-PermissionTarget
            2   Expanded resolved item paths (parent paths expanded into children)                          $ACLsByPath.Keys after Expand-PermissionTarget
            3   Access control entries                                                                      $ACLsByPath.Values after Get-FolderAcl
            4   Resolved access control entries                                                             $ACEsByGUID.Values
                                                                                                            $PrincipalsByResolvedID.Values
            5   Expanded resolved access control entries (expanded with info from ADSI security principals) $Permissions
            6   XML custom sensor output for Paessler PRTG Network Monitor
        #>
        [int[]]$Detail = @(0..6)

    )

    $OutputObject = @{}

    switch ($Format) {

        'csv' {
            $OutputObject['Data'] = ForEach ($Input in $Permission) {
                $Input | ConvertTo-Csv
            }
        }

        'html' {
            $Html = ForEach ($Input in $Permission) {
                $Input | ConvertTo-Html -Fragment
            }
            $OutputObject['Data'] = $Html
            $OutputObject['Table'] = $Html | New-BootstrapTable
        }

        'json' {

            $OutputObject['Data'] = ForEach ($Input in $Permission) {

                # Remove spaces from property titles
                $ObjectsForJsonData = ForEach ($Obj in $Input) {
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

                ConvertTo-Json -InputObject @($ObjectsForJsonData)

            }

            $OutputObject['Columns'] = Get-FolderColumnJson -InputObject $Permission -PropNames Account, Access,
            'Due to Membership In', 'Source of Access', Name, Department, Title

            $TableId = "Perms_$($ThisFolder.Item.Path -replace '[^A-Za-z0-9\-_]', '-')"
            $OutputObject['Table'] = ConvertTo-BootstrapJavaScriptTable -Id $TableId -InputObject $ObjectsForFolderPermissionTable -DataFilterControl -AllColumnsSearchable

        }

        'prtgxml' {

            # ToDo: Users with ownership
            $NtfsIssueParams = @{
                FolderPermissions = $Permission
                UserPermissions   = $Accounts
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

        }

        'xml' {
            $OutputObject['Data'] = ForEach ($Input in $Permission) {
                $Input | ConvertTo-Xml
            }
        }

        default {}

    }

    return

}
