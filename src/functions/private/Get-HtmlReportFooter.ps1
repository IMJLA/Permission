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

        [string[]]$UnitsToResolve = @('day', 'hour', 'minute', 'second')

    )

    $null = $StopWatch.Stop()
    $FinishTime = Get-Date
    $StartTime = $FinishTime.AddTicks(-$StopWatch.ElapsedTicks)
    $TimeZoneName = Get-TimeZoneName -Time $FinishTime
    $Duration = Format-TimeSpan -TimeSpan $StopWatch.Elapsed -UnitsToResolve $UnitsToResolve

    if ($TotalBytes) {
        $TiB = $TotalBytes / 1TB
        $Size = " ($TiB TiB"
    }

    $CompletionTime = @(
        @{
            'Name'              = 'Target paths'
            'Count'             = $TargetCount
            'Average Time Each' = Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $TargetCount ) ) -UnitsToResolve $UnitsToResolve
        },
        @{
            'Name'              = 'Parent paths'
            'Count'             = $ParentCount
            'Average Time Each' = Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $ParentCount ) ) -UnitsToResolve $UnitsToResolve
        },
        @{
            'Name'              = 'Child paths'
            'Count'             = $ChildCount
            'Average Time Each' = Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $ChildCount ) ) -UnitsToResolve $UnitsToResolve
        },
        @{
            'Name'              = 'Item paths (parents and children)'
            'Count'             = $ItemCount
            'Average Time Each' = Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $ItemCount ) ) -UnitsToResolve $UnitsToResolve
        },
        @{
            'Name'              = 'Item servers'
            'Count'             = $FqdnCount
            'Average Time Each' = Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $FqdnCount ) ) -UnitsToResolve $UnitsToResolve
        },
        @{
            'Name'              = 'ACLs'
            'Count'             = $AclCount
            'Average Time Each' = Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $AclCount ) ) -UnitsToResolve $UnitsToResolve
        },
        @{
            'Name'              = 'ACEs'
            'Count'             = $AceCount
            'Average Time Each' = Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $AceCount ) ) -UnitsToResolve $UnitsToResolve
        },
        @{
            'Name'              = 'IDs'
            'Count'             = $IdCount
            'Average Time Each' = Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $IdCount ) ) -UnitsToResolve $UnitsToResolve
        },
        @{
            'Name'              = 'Security Principals'
            'Count'             = $PrincipalCount
            'Average Time Each' = Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $PrincipalCount ) ) -UnitsToResolve $UnitsToResolve
        },
        @{
            'Name'              = 'Grouped and Expanded Permissions'
            'Count'             = $PrincipalCount
            'Average Time Each' = Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $PermissionCount ) ) -UnitsToResolve $UnitsToResolve
        },
        @{
            'Name'              = 'Formatted Permissions'
            'Count'             = $PrincipalCount
            'Average Time Each' = Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $FormattedPermissionCount ) ) -UnitsToResolve $UnitsToResolve
        },
        @{
            'Name'              = 'Data Size'
            'Count'             = $TiB
            'Average Time Each' = Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds / $TiB ) ) -UnitsToResolve $UnitsToResolve
        },
        @{
            'Name'              = 'TOTAL'
            'Count'             = 1
            'Average Time Each' = Format-TimeSpan -TimeSpan ( New-TimeSpan -Milliseconds ( $StopWatch.Elapsed.TotalMilliseconds ) ) -UnitsToResolve $UnitsToResolve
        }
    )

    $Heading = New-HtmlHeading 'Performance' -Level 6
    $Html = $CompletionTime | ConvertTo-Html -Fragment
    $Table = $Html | New-BootstrapTable
    New-BootstrapDiv -Text ($Heading + $Table) -Class 'h-100 p-1 bg-light border rounded-3 table-responsive'

    $Text = @"
Report generated by $WhoAmI on $ThisFQDN starting at $StartTime and ending at $FinishTime $TimeZoneName (elapsed: $Duration)<br />
Report instance: $ReportInstanceId
"@

    New-BootstrapAlert -Class Light -Text $Text -AdditionalClasses ' small'

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
