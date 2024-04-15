function Get-HtmlReportFooter {
    param (

        # Stopwatch that was started when report generation began
        [System.Diagnostics.Stopwatch]$StopWatch,

        # NT Account caption (CONTOSO\User) of the account running this function
        [string]$WhoAmI = (whoami.EXE),

        <#
        FQDN of the computer running this function

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        [uint64]$ItemCount,

        [uint64]$TotalBytes,

        [string]$ReportInstanceId,

        [UInt64]$PermissionCount,

        [UInt64]$PrincipalCount,

        [string[]]$UnitsToResolve = @('day', 'hour', 'minute', 'second'),

        [hashtable]$AceByGUID,

        [hashtable]$AclByPath
    )

    $null = $StopWatch.Stop()
    $FinishTime = Get-Date
    $StartTime = $FinishTime.AddTicks(-$StopWatch.ElapsedTicks)
    $TimeZoneName = Get-TimeZoneName -Time $FinishTime
    $Duration = Format-TimeSpan -TimeSpan $StopWatch.Elapsed -UnitsToResolve $UnitsToResolve

    if ($TotalBytes) {
        $Size = " ($($TotalBytes / 1TB) TiB"
    }

    $Text = @"
Report generated by $WhoAmI on $ThisFQDN starting at $StartTime and ending at $FinishTime $TimeZoneName<br />
Processed $($AclByPath.Keys.Count) ACLs containing $($AceByGUID.Keys.Count) ACEs with $PermissionCount permissions for $PrincipalCount accounts on $ItemCount items$Size in $Duration<br />
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
