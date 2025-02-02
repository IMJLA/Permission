function Get-HtmlReportElements {

    # missing

    param (

        # Path to the NTFS folder whose permissions are being exported
        [string[]]$SourcePath,

        # Network Path to the NTFS folder whose permissions are being exported
        $NetworkPath,

        # Path to the folder to save the logs and reports generated by this script
        $OutputDir,

        # Timer to measure progress and performance
        $StopWatch,

        # Unused.  Here so that the @PSBoundParameters hashtable in Out-PermissionReport can be used as a splat for this function.
        [ValidateSet('account', 'item', 'none', 'source')]
        [string]$GroupBy = 'item',

        # Unused.  Here so that the @PSBoundParameters hashtable in Out-PermissionReport can be used as a splat for this function.
        $FormattedPermission,

        # Unused.  Here so that the @PSBoundParameters hashtable in Out-PermissionReport can be used as a splat for this function.
        $Analysis,

        # Unused.  Here so that the @PSBoundParameters hashtable in Out-PermissionReport can be used as a splat for this function.
        [string[]]$FileFormat,

        # Unused.  Here so that the @PSBoundParameters hashtable in Out-PermissionReport can be used as a splat for this function.
        [String]$OutputFormat,

        $Permission,
        $LogFileList,
        $ReportInstanceId,
        [Hashtable]$AceByGUID,
        [String]$Split,
        [String]$FileName,
        [uint64]$SourceCount,
        [uint64]$ParentCount,
        [uint64]$ChildCount,
        [uint64]$ItemCount,
        [uint64]$FqdnCount,
        [uint64]$AclCount,
        [uint64]$AceCount,
        [uint64]$IdCount,
        [UInt64]$PrincipalCount,
        [pscustomobject[]]$Account,
        [string[]]$FileList,

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache,

        # $PSBoundParameters from Export-Permission
        [hashtable]$ParameterDict

    )

    $AccountProperty = $ParameterDict['AccountProperty']
    $Detail = $ParameterDict['Detail']
    $ExcludeAccount = $ParameterDict['ExcludeAccount']
    $ExcludeClass = $ParameterDict['ExcludeClass']
    $GroupBy = $ParameterDict['GroupBy']
    $IgnoreDomain = $ParameterDict['IgnoreDomain']
    $Title = $ParameterDict['Title']
    $NoMembers = $ParameterDict['NoMembers']
    $RecurseDepth = $ParameterDict['RecurseDepth']

    <#
    Information about the current culture settings.
    This includes information about the current language settings on the system, such as the keyboard layout, and the
    display format of items such as numbers, currency, and dates.
    #>
    $Culture = $Cache.Value['Culture'].Value
    $ThisFqdn = $Cache.Value['ThisFqdn'].Value
    $WhoAmI = $Cache.Value['WhoAmI'].Value
    $Log = @{
        'Cache'        = $Cache
        'ExpansionMap' = $Cache.Value['LogEmptyMap'].Value
    }

    Write-LogMsg @Log -Text "Get-ReportDescription -RecurseDepth $RecurseDepth"
    $ReportDescription = Get-ReportDescription -RecurseDepth $RecurseDepth

    $ErrorDiv = Get-ReportErrorDiv -Cache $Cache

    $NetworkPathTable = Select-ItemTableProperty -InputObject $NetworkPath -Culture $Culture -SkipFilterCheck |
    ConvertTo-Html -Fragment |
    New-BootstrapTable

    $NetworkPathDivHeader = 'Local source paths were resolved to UNC paths, and UNC source paths were resolved to DFS folder targets'
    Write-LogMsg @Log -Text "New-BootstrapDivWithHeading -HeadingText '$NetworkPathDivHeader' -Content `$NetworkPathTable"
    $NetworkPathDiv = New-BootstrapDivWithHeading -HeadingText $NetworkPathDivHeader -Content $NetworkPathTable -Class 'h-100 p-1 bg-light border rounded-3 table-responsive' -HeadingLevel 6

    Write-LogMsg @Log -Text "Get-SummaryDivHeader -GroupBy $GroupBy"
    $SummaryDivHeader = Get-SummaryDivHeader -GroupBy $GroupBy -Split $Split

    Write-LogMsg @Log -Text "Get-SummaryTableHeader -RecurseDepth $RecurseDepth -GroupBy $GroupBy"
    $SummaryTableHeader = Get-SummaryTableHeader -RecurseDepth $RecurseDepth -GroupBy $GroupBy

    Write-LogMsg @Log -Text "Get-DetailDivHeader -GroupBy '$GroupBy' -Split '$Split'"
    $DetailDivHeader = Get-DetailDivHeader -GroupBy $GroupBy -Split $Split

    if ($Account) {

        $AccountObj = [pscustomobject]@{'Account' = $Account }
        $AccountTable = Select-AccountTableProperty -InputObject $AccountObj -Culture $Culture -ShortNameByID $Cache.Value['ShortNameById'].Value -AccountProperty $AccountProperty |
        ConvertTo-Html -Fragment |
        New-BootstrapTable

        $AccountDivHeader = 'The report only includes permissions for this account (option was used to generate a file per account)'
        Write-LogMsg @Log -Text "New-BootstrapDivWithHeading -HeadingText '$AccountDivHeader' -Content `$AccountTable"
        $AccountDiv = New-BootstrapDivWithHeading -HeadingText $AccountDivHeader -Content $AccountTable -Class 'h-100 p-1 bg-light border rounded-3 table-responsive' -HeadingLevel 6

    }

    Write-LogMsg @Log -Text "New-HtmlHeading 'Source Paths' -Level 5"
    $SourceHeading = New-HtmlHeading 'Source Paths' -Level 5

    # Convert the source path(s) to a Bootstrap alert div
    $SourcePathString = $SourcePath -join '<br />'
    Write-LogMsg @Log -Text "New-BootstrapAlert -Class Dark -Text '$SourcePathString'"
    $SourceAlert = New-BootstrapAlert -Class Dark -Text $SourcePathString -AdditionalClasses ' small'

    # Add the source path div to the parameter splat for New-BootstrapReport
    $ReportParameters = @{
        Title       = $Title
        Description = "$SourceHeading $SourceAlert $ReportDescription"
    }

    # Build the divs showing the exclusions specified in the report parameters
    $ExcludedNames = ConvertTo-NameExclusionDiv -ExcludeAccount $ExcludeAccount -Cache $Cache
    $ExcludedClasses = ConvertTo-ClassExclusionDiv -ExcludeClass $ExcludeClass -Cache $Cache
    $IgnoredDomains = ConvertTo-IgnoredDomainDiv -IgnoreDomain $IgnoreDomain -Cache $Cache
    $ExcludedMembers = ConvertTo-MemberExclusionDiv -NoMembers:$NoMembers -Cache $Cache

    # Arrange the exclusion divs into two Bootstrap columns
    Write-LogMsg @Log -Text "New-BootstrapColumn -Html '`$ExcludedMembers`$ExcludedClasses',`$IgnoredDomains`$ExcludedNames"
    $ExclusionsDiv = New-BootstrapColumn -Html "$ExcludedMembers$ExcludedClasses", "$IgnoredDomains$ExcludedNames" -Width 6

    # Convert the list of generated log files to a Bootstrap list group
    $HtmlListOfLogs = $LogFileList |
    Split-Path -Leaf | # the output directory will already be shown in a Bootstrap alert above the list, so this row removes the path from the file names
    ConvertTo-HtmlList |
    ConvertTo-BootstrapListGroup

    # Prepare headings for 2 columns listing report and log files generated, respectively
    $HtmlReportsHeading = New-HtmlHeading -Text 'Reports' -Level 6
    $HtmlLogsHeading = New-HtmlHeading -Text 'Logs' -Level 6

    # Convert the output directory path to a Boostrap alert
    $HtmlOutputDir = New-BootstrapAlert -Text $OutputDir -Class 'secondary' -AdditionalClasses ' small'

    # Convert the list of detail levels and file formats to a hashtable of report files that will be generated
    $ReportFileList = ConvertTo-FileList -Detail $Detail -Format $Formats -FileName $FileName -FileList $FileList

    # Convert the hashtable of generated report files to a Bootstrap list group
    $HtmlReportsDiv = (ConvertTo-FileListDiv -FileList $ReportFileList) -join "`r`n"

    # Arrange the lists of generated files in two Bootstrap columns
    Write-LogMsg @Log -Text "New-BootstrapColumn -Html '`$HtmlReportsHeading`$HtmlReportsDiv',`$HtmlLogsHeading`$HtmlListOfLogs"
    $HtmlDivOfFileColumns = New-BootstrapColumn -Html "$HtmlReportsHeading$HtmlReportsDiv", "$HtmlLogsHeading$HtmlListOfLogs" -Width 6

    # Combine the alert and the columns of generated files inside a Bootstrap div
    Write-LogMsg @Log -Text "New-BootstrapDivWithHeading -HeadingText 'Output Folder:' -Content '`$HtmlOutputDir`$HtmlDivOfFileColumns'"
    $HtmlDivOfFiles = New-BootstrapDivWithHeading -HeadingText 'Output Folder:' -Content "$HtmlOutputDir$HtmlDivOfFileColumns" -HeadingLevel 6

    # Generate a footer to include at the bottom of the report
    Write-LogMsg @Log -Text "Get-HtmlReportFooter -StopWatch `$StopWatch -ReportInstanceId '$ReportInstanceId' -WhoAmI '$WhoAmI' -ThisFqdn '$ThisFqdn'"
    $FooterParams = @{
        'ItemCount'                = $ItemCount
        'FormattedPermissionCount' = (
            @('csv', 'html', 'js', 'json', 'prtgxml', 'xml') |
            ForEach-Object { $FormattedPermission.Values.NetworkPaths.$_.PassThru.Count } |
            Measure-Object -Sum
        ).Sum
        'PermissionCount'          = (
            @(
                $Permission.AccountPermissions.NetworkPaths.Access.Count, # SplitBy Account GroupBy Account/None
                $Permission.ItemPermissions.Access.Access.Count,
                $Permission.SourcePermissions.NetworkPaths.Accounts.NetworkPaths.Access.Count, # SplitBy Source GroupBy Account
                ($Permission.SourcePermissions.NetworkPaths.Items.Access.Access.Count + $Permission.SourcePermissions.NetworkPaths.Access.Access.Count), # SplitBy Source GroupBy Item
                $Permission.SourcePermissions.NetworkPaths.Access.Count, # SplitBy Source GroupBy Source/None
                $AceByGUID.Keys.Count
            ) |
            Measure-Object -Maximum
        ).Maximum
        'ReportInstanceId'         = $ReportInstanceId
        'StopWatch'                = $StopWatch
        'ThisFqdn'                 = $ThisFqdn
        'WhoAmI'                   = $WhoAmI
        'SourceCount'              = $SourceCount
        'ParentCount'              = $ParentCount
        'ChildCount'               = $ChildCount
        'FqdnCount'                = $FqdnCount
        'AclCount'                 = $AclCount
        'AceCount'                 = $AceCount
        'PrincipalCount'           = $PrincipalCount
        'IdCount'                  = $IdCount
        'ParameterDict'            = $ParameterDict
    }
    $ReportFooter = Get-HtmlReportFooter @FooterParams

    [PSCustomObject]@{
        'AccountDiv'         = $AccountDiv
        'ErrorDiv'           = $ErrorDiv
        'ReportFooter'       = $ReportFooter
        'HtmlDivOfFiles'     = $HtmlDivOfFiles
        'ExclusionsDiv'      = $ExclusionsDiv
        'ReportParameters'   = $ReportParameters
        'DetailDivHeader'    = $DetailDivHeader
        'SummaryTableHeader' = $SummaryTableHeader
        'SummaryDivHeader'   = $SummaryDivHeader
        'NetworkPathDiv'     = $NetworkPathDiv
    }

}
