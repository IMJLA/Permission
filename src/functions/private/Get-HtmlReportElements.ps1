function Get-HtmlReportElements {

    # missing

    param (

        # Regular expressions matching names of security principals to exclude from the HTML report
        [string[]]$ExcludeAccount,

        # Accounts whose objectClass property is in this list are excluded from the HTML report
        [string[]]$ExcludeClass = @('group', 'computer'),

        <#
        Domain(s) to ignore (they will be removed from the username)

        Intended when a user has matching SamAccountNames in multiple domains but you only want them to appear once on the report.

        Can also be used to remove all domains simply for brevity in the report.
        #>
        $IgnoreDomain,

        # Path to the NTFS folder whose permissions are being exported
        [string[]]$TargetPath,

        # Network Path to the NTFS folder whose permissions are being exported
        $NetworkPath,

        # Group members are not being exported (only the groups themselves)
        [switch]$NoMembers,

        # Path to the folder to save the logs and reports generated by this script
        $OutputDir,

        # NTAccount caption of the user running the script
        $WhoAmI,

        # FQDN of the computer running the script
        $ThisFqdn,

        # Timer to measure progress and performance
        $StopWatch,

        # Title at the top of the HTML report
        $Title,

        $Permission,
        $FormattedPermission,
        $LogParams,
        $RecurseDepth,
        $LogFileList,
        $ReportInstanceId,
        [hashtable]$ACEsByGUID,
        [hashtable]$ACLsByPath,
        $PrincipalsByResolvedID,
        $BestPracticeIssue,
        [string[]]$Parent,

        <#
        Level of detail to export to file
            0   Item paths                                                                                  $TargetPath
            1   Resolved item paths (server names resolved, DFS targets resolved)                           $Parents
            2   Expanded resolved item paths (parent paths expanded into children)                          $ACLsByPath.Keys
            3   Access rules                                                                                $ACLsByPath.Values
            4   Resolved access rules (server names resolved, inheritance flags resolved)                   $ACEsByGUID.Values | %{$_} | Sort Path,IdentityReferenceResolved
            5   Accounts with access                                                                        $PrincipalsByResolvedID.Values | %{$_} | Sort ResolvedAccountName
            6   Expanded resolved access rules (expanded with account info)                                 $Permissions
            7   Formatted permissions                                                                       $FormattedPermissions
            8   Best Practice issues                                                                        $BestPracticeIssues
            9   XML custom sensor output for Paessler PRTG Network Monitor                                  $PrtgXml
            10  Permission Report
        #>
        [int[]]$Detail = @(0..10),

        <#
        Information about the current culture settings.
        This includes information about the current language settings on the system, such as the keyboard layout, and the
        display format of items such as numbers, currency, and dates.
        #>
        [cultureinfo]$Culture = (Get-Culture),

        # File format(s) to export
        [ValidateSet('csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [string[]]$FileFormat = @('csv', 'html', 'js', 'json', 'prtgxml', 'xml'),

        # Type of output returned to the output stream
        [ValidateSet('passthru', 'none', 'csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [string]$OutputFormat = 'passthru',

        <#
        How to group the permissions in the output stream and within each exported file

            SplitBy	GroupBy
            none	none	$FlatPermissions all in 1 file per $TargetPath
            none	account	$AccountPermissions all in 1 file per $TargetPath
            none	item	$ItemPermissions all in 1 file per $TargetPath (default behavior)

            item	none	1 file per item in $ItemPermissions.  In each file, $_.Access | sort account
            item	account	1 file per item in $ItemPermissions.  In each file, $_.Access | group account | sort name
            item	item	(same as -SplitBy item -GroupBy none)

            account	none	1 file per item in $AccountPermissions.  In each file, $_.Access | sort path
            account	account	(same as -SplitBy account -GroupBy none)
            account	item	1 file per item in $AccountPermissions.  In each file, $_.Access | group item | sort name
        #>
        [ValidateSet('none', 'item', 'account')]
        [string]$GroupBy = 'item'

    )

    Write-LogMsg @LogParams -Text "Get-ReportDescription -RecurseDepth $RecurseDepth"
    $ReportDescription = Get-ReportDescription -RecurseDepth $RecurseDepth

    $NetworkPathTable = $NetworkPath.Item |
    ConvertTo-Html -Fragment |
    New-BootstrapTable

    $NetworkPathDivHeader = 'Local paths were resolved to UNC paths, and UNC paths were resolved to all DFS folder targets'
    Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText '$NetworkPathDivHeader' -Content `$NetworkPathTable"
    $NetworkPathDiv = New-BootstrapDivWithHeading -HeadingText $NetworkPathDivHeader -Content $NetworkPathTable -Class 'h-100 p-1 bg-light border rounded-3 table-responsive' -HeadingLevel 6

    Write-LogMsg @LogParams -Text "Get-SummaryDivHeader -GroupBy $GroupBy"
    $SummaryDivHeader = Get-SummaryDivHeader -GroupBy $GroupBy

    Write-LogMsg @LogParams -Text "Get-SummaryTableHeader -RecurseDepth $RecurseDepth -GroupBy $GroupBy"
    $SummaryTableHeader = Get-SummaryTableHeader -RecurseDepth $RecurseDepth -GroupBy $GroupBy

    Write-LogMsg @LogParams -Text "Get-DetailDivHeader -GroupBy $GroupBy"
    $DetailDivHeader = Get-DetailDivHeader -GroupBy $GroupBy

    Write-LogMsg @LogParams -Text "New-HtmlHeading 'Target Paths' -Level 5"
    $TargetHeading = New-HtmlHeading 'Target Paths' -Level 5

    # Convert the target path(s) to a Bootstrap alert div
    $TargetPathString = $TargetPath -join '<br />'
    Write-LogMsg @LogParams -Text "New-BootstrapAlert -Class Dark -Text '$TargetPathString'"
    $TargetAlert = New-BootstrapAlert -Class Dark -Text $TargetPathString -AdditionalClasses ' small'

    # Add the target path div to the parameter splat for New-BootstrapReport
    $ReportParameters = @{
        Title       = $Title
        Description = "$TargetHeading $TargetAlert $ReportDescription"
    }

    # Build the divs showing the exclusions specified in the report parameters
    $ExcludedNames = ConvertTo-NameExclusionDiv -ExcludeAccount $ExcludeAccount
    $ExcludedClasses = ConvertTo-ClassExclusionDiv -ExcludeClass $ExcludeClass
    $IgnoredDomains = ConvertTo-IgnoredDomainDiv -IgnoreDomain $IgnoreDomain
    $ExcludedMembers = ConvertTo-MemberExclusionDiv -NoMembers:$NoMembers

    # Arrange the exclusion divs into two Bootstrap columns
    Write-LogMsg @LogParams -Text "New-BootstrapColumn -Html '`$ExcludedMembers`$ExcludedClasses',`$IgnoredDomains`$ExcludedNames"
    $ExclusionsDiv = New-BootstrapColumn -Html "$ExcludedMembers$ExcludedClasses", "$IgnoredDomains$ExcludedNames" -Width 6

    # Convert the list of generated log files to a Bootstrap list group
    $HtmlListOfLogs = $LogFileList |
    Split-Path -Leaf | # the output directory will be shown in a Bootstrap alert so this row removes the path from the file names
    ConvertTo-HtmlList |
    ConvertTo-BootstrapListGroup

    # Prepare headings for 2 columns listing report and log files generated, respectively
    $HtmlReportsHeading = New-HtmlHeading -Text 'Reports' -Level 6
    $HtmlLogsHeading = New-HtmlHeading -Text 'Logs' -Level 6

    # Convert the output directory path to a Boostrap alert
    $HtmlOutputDir = New-BootstrapAlert -Text $OutputDir -Class 'secondary' -AdditionalClasses ' small'

    $ListOfReports = ConvertTo-FileList -Detail $Detail -Format $Formats

    # Convert the list of generated report files to a Bootstrap list group
    $HtmlListOfReports = $ListOfReports |
    Split-Path -Leaf |
    ConvertTo-HtmlList |
    ConvertTo-BootstrapListGroup

    # Arrange the lists of generated files in two Bootstrap columns
    Write-LogMsg @LogParams -Text "New-BootstrapColumn -Html '`$HtmlReportsHeading`$HtmlListOfReports',`$HtmlLogsHeading`$HtmlListOfLogs"
    $HtmlDivOfFileColumns = New-BootstrapColumn -Html "$HtmlReportsHeading$HtmlListOfReports", "$HtmlLogsHeading$HtmlListOfLogs" -Width 6

    # Combine the alert and the columns of generated files inside a Bootstrap div
    Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText 'Output Folder:' -Content '`$HtmlOutputDir`$HtmlDivOfFileColumns'"
    $HtmlDivOfFiles = New-BootstrapDivWithHeading -HeadingText "Output Folder:" -Content "$HtmlOutputDir$HtmlDivOfFileColumns"

    # Generate a footer to include at the bottom of the report
    Write-LogMsg @LogParams -Text "Get-ReportFooter -StopWatch `$StopWatch -ReportInstanceId '$ReportInstanceId' -WhoAmI '$WhoAmI' -ThisFqdn '$ThisFqdn'"
    $FooterParams = @{
        ItemCount        = $ACLsByPath.Keys.Count
        PermissionCount  = $Permission.ItemPermissions.Access.Access.Count
        PrincipalCount   = $PrincipalsByResolvedID.Keys.Count
        ReportInstanceId = $ReportInstanceId
        StopWatch        = $StopWatch
        ThisFqdn         = $ThisFqdn
        WhoAmI           = $WhoAmI
    }
    $ReportFooter = Get-HtmlReportFooter @FooterParams

    [PSCustomObject]@{
        ReportFooter       = $ReportFooter
        HtmlDivOfFiles     = $HtmlDivOfFiles
        ExclusionsDiv      = $ExclusionsDiv
        ReportParameters   = $ReportParameters
        DetailDivHeader    = $DetailDivHeader
        SummaryTableHeader = $SummaryTableHeader
        SummaryDivHeader   = $SummaryDivHeader
        NetworkPathDiv     = $NetworkPathDiv
    }

}
