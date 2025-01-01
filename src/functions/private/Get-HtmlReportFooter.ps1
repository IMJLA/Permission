function Get-HtmlReportFooter {

    param (

        # Stopwatch that was started when report generation began
        [System.Diagnostics.Stopwatch]$StopWatch,

        # NT Account caption (CONTOSO\User) of the account running this function
        [String]$WhoAmI = (whoami.EXE),

        <#
        FQDN of the computer running this function

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [String]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        [uint64]$TargetCount,
        [uint64]$ParentCount,
        [uint64]$ChildCount,
        [uint64]$ItemCount,
        [uint64]$FqdnCount,
        [uint64]$AclCount,
        [uint64]$AceCount,
        [uint64]$IdCount,
        [UInt64]$PrincipalCount,
        [UInt64]$PermissionCount,
        [uint64]$FormattedPermissionCount,

        [uint64]$TotalBytes,

        [String]$ReportInstanceId,

        [string[]]$UnitsToResolve = @('day', 'hour', 'minute', 'second', 'millisecond')

    )

    $null = $StopWatch.Stop()
    $FinishTime = Get-Date
    $StartTime = $FinishTime.AddTicks(-$StopWatch.ElapsedTicks)
    $TimeZoneName = Get-TimeZoneName -Time $FinishTime
    $Duration = Format-TimeSpan -TimeSpan $StopWatch.Elapsed -UnitsToResolve $UnitsToResolve

    if ($TotalBytes) {
        $TiB = $TotalBytes / 1TB
        $Size = " ($TiB TiB)"
    }

    $AllUnits = @('day', 'hour', 'minute', 'second', 'millisecond')
    $CompletionTime = @(
        @{
            'Name'              = 'Source paths (specified in report parameters)'
            'Count'             = $TargetCount
            'Average Time Each' = if ($TargetCount -gt 0) { Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $TargetCount ) ) -UnitsToResolve $AllUnits }
        },
        @{
            'Name'              = 'Parents (resolved from source paths)'
            'Count'             = $ParentCount
            'Average Time Each' = if ($ParentCount -gt 0) { Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $ParentCount ) ) -UnitsToResolve $AllUnits }
        },
        @{
            'Name'              = 'Children (found in parents)'
            'Count'             = $ChildCount
            'Average Time Each' = if ($ChildCount -gt 0) { Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $ChildCount ) ) -UnitsToResolve $AllUnits }
        },
        @{
            'Name'              = 'Items (parents and children)'
            'Count'             = $ItemCount
            'Average Time Each' = if ($ItemCount -gt 0) { Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $ItemCount ) ) -UnitsToResolve $AllUnits }
        },
        @{
            'Name'              = 'Servers (hosting items)'
            'Count'             = $FqdnCount
            'Average Time Each' = if ($FqdnCount -gt 0) { Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $FqdnCount ) ) -UnitsToResolve $AllUnits }
        },
        @{
            'Name'              = 'ACLs (found on items)'
            'Count'             = $AclCount
            'Average Time Each' = if ($AclCount -gt 0) { Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $AclCount ) ) -UnitsToResolve $AllUnits }
        },
        @{
            'Name'              = 'ACEs (in ACLs)'
            'Count'             = $AceCount
            'Average Time Each' = if ($AceCount -gt 0) { Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $AceCount ) ) -UnitsToResolve $AllUnits }
        },
        @{
            'Name'              = 'IDs (in ACEs)'
            'Count'             = $IdCount
            'Average Time Each' = if ($IdCount -gt 0) { Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $IdCount ) ) -UnitsToResolve $AllUnits }
        },
        @{
            'Name'              = 'Security Principals (represented by IDs, including group members)'
            'Count'             = $PrincipalCount
            'Average Time Each' = if ($PrincipalCount -gt 0) { Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $PrincipalCount ) ) -UnitsToResolve $AllUnits }
        },
        @{
            'Name'              = 'Unique Permissions for those security principals (non-inherited)'
            'Count'             = $PermissionCount
            'Average Time Each' = if ($PermissionCount -gt 0) { Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $PermissionCount ) ) -UnitsToResolve $AllUnits }
        },
        @{
            'Name'              = 'Formatted Permissions (according to report parameters)'
            'Count'             = $FormattedPermissionCount
            'Average Time Each' = if ($FormattedPermissionCount -gt 0) { Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $FormattedPermissionCount ) ) -UnitsToResolve $AllUnits }
        },
        #@{
        #    'Name'              = 'Data Size'
        #    'Count'             = $TiB
        #    'Average Time Each' = Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $TiB ) ) -UnitsToResolve $AllUnits
        #},
        @{
            'Name'              = 'TOTAL REPORT TIME'
            'Count'             = 1
            'Average Time Each' = Format-TimeSpan -TimeSpan $StopWatch.Elapsed -UnitsToResolve $AllUnits
        }
    )

    $Heading = New-HtmlHeading 'Performance' -Level 6
    $Html = $CompletionTime | Select-Object -Property Name, Count, 'Average Time Each' | ConvertTo-Html -Fragment
    $Table = $Html | New-BootstrapTable
    $Div = New-BootstrapDiv -Text ($Heading + $Table) -Class 'h-100 p-1 bg-light border rounded-3 table-responsive'

    $Text = @"
Report generated by $WhoAmI on $ThisFQDN starting at $StartTime and ending at $FinishTime $TimeZoneName (elapsed: $Duration)<br />
Report instance: $ReportInstanceId
"@

    $Alert = New-BootstrapAlert -Class Light -Text $Text -AdditionalClasses ' small'
    "$Div<br />$Alert"

}
<#
$TagetPath.Count parent folders
$ItemCount total folders including children
$FolderPermissions folders with unique permissions
$Permissions.Count access control entries on those folders
$Identities.Count identities in those access control entries
$FormattedSecurityPrincipals principals represented by those identities
$UniqueAccountPermissions.Count unique accounts after filtering out any specified domain names
$ExpandedAccountPermissions.Count effective permissions belonging to those principals and applying to those folders
#>
