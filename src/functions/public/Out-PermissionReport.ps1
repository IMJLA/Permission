function Out-PermissionReport {

    # missing

    param (

        # Regular expressions matching names of security principals to exclude from the HTML report
        $ExcludeAccount,

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

        # Group members are not being exported (only the groups themselves)
        $NoGroupMembers,

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

        # Generate a report with only HTML and CSS but no JavaScript
        [switch]$NoJavaScript,

        $FormattedPermission,
        $LogParams,
        $RecurseDepth,
        $ReportFileList,
        $ReportFile,
        $LogFileList,
        $ReportInstanceId,
        $Subfolders,
        $ResolvedFolderTargets,
        $PrincipalsByResolvedID

    )

    Write-LogMsg @LogParams -Text "Get-ReportDescription -RecurseDepth $RecurseDepth"
    $ReportDescription = Get-ReportDescription -RecurseDepth $RecurseDepth

    Write-LogMsg @LogParams -Text "Get-FolderTableHeader -RecurseDepth $RecurseDepth"
    $FolderTableHeader = Get-FolderTableHeader -RecurseDepth $RecurseDepth

    # Convert the target path(s) to a Bootstrap alert
    $TargetPathString = $TargetPath -join '<br />'
    Write-LogMsg @LogParams -Text "New-BootstrapAlert -Class Dark -Text '$TargetPathString'"
    $ReportDescription = "$(New-BootstrapAlert -Class Dark -Text $TargetPathString) $ReportDescription"

    $ReportParameters = @{
        Title       = $Title
        Description = $ReportDescription
        Body        = $Body
    }

    $HeadingText = 'Accounts Excluded by Regular Expression'
    if ($ExcludeAccount) {
        $ListGroup = $ExcludeAccount |
        ConvertTo-HtmlList |
        ConvertTo-BootstrapListGroup

        $Description = 'Accounts matching these regular expressions were excluded from the report.'
        Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText '$HeadingText' -Content `"`$Description`$ListGroup`""
        $HtmlRegExExclusions = New-BootstrapDivWithHeading -HeadingText $HeadingText -Content "$Description$ListGroup"
    } else {
        $Description = 'No accounts were excluded based on regular expressions.'
        $HtmlRegExExclusions = New-BootstrapDivWithHeading -HeadingText $HeadingText -Content $Description
    }

    $HeadingText = 'Accounts Excluded by Class'
    if ($ExcludeClass) {
        $ListGroup = $ExcludeClass |
        ConvertTo-HtmlList |
        ConvertTo-BootstrapListGroup

        $Description = 'Accounts whose objectClass property is in this list were excluded from the report.'
        $HtmlClassExclusions = New-BootstrapDivWithHeading -HeadingText $HeadingText -Content "$Description$ListGroup"
    } else {
        $Description = 'No accounts were excluded based on objectClass.'
        $HtmlClassExclusions = New-BootstrapDivWithHeading -HeadingText $HeadingText -Content $Description
    }

    $HeadingText = 'Domains Ignored'
    if ($IgnoreDomain) {
        $ListGroup = $IgnoreDomain |
        ConvertTo-HtmlList |
        ConvertTo-BootstrapListGroup

        $Description = 'Accounts from these domains are listed in the report without their domain.'
        $HtmlIgnoredDomains = New-BootstrapDivWithHeading -HeadingText $HeadingText -Content "$Description$ListGroup"
    } else {
        $Description = 'No domains were ignored.  All accounts have their domain listed.'
        $HtmlIgnoredDomains = New-BootstrapDivWithHeading -HeadingText $HeadingText -Content $Description
    }

    $HeadingText = 'Group Members'
    if ($NoGroupMembers) {
        $Description = 'Group members were excluded from the report.<br />Only accounts directly from the ACLs are included in the report.'
    } else {
        $Description = 'No accounts were excluded based on group membership.<br />Members of groups from the ACLs are included in the report.'
    }
    $HtmlExcludedGroupMembers = New-BootstrapDivWithHeading -HeadingText $HeadingText -Content $Description

    # Arrange the exclusions in two Bootstrap columns
    Write-LogMsg @LogParams -Text "New-BootstrapColumn -Html '`$HtmlExcludedGroupMembers`$HtmlClassExclusions',`$HtmlIgnoredDomains`$HtmlRegExExclusions"
    $ExclusionsDiv = New-BootstrapColumn -Html "$HtmlExcludedGroupMembers$HtmlClassExclusions", "$HtmlIgnoredDomains$HtmlRegExExclusions" -Width 6

    # Convert the list of generated log files to a Bootstrap list group
    $HtmlListOfLogs = $LogFileList |
    Split-Path -Leaf |
    ConvertTo-HtmlList |
    ConvertTo-BootstrapListGroup

    # Prepare headings for 2 columns listing report and log files generated, respectively
    $HtmlReportsHeading = New-HtmlHeading -Text 'Reports' -Level 6
    $HtmlLogsHeading = New-HtmlHeading -Text 'Logs' -Level 6

    # Convert the output directory path to a Boostrap alert
    $HtmlOutputDir = New-BootstrapAlert -Text $OutputDir -Class 'secondary'

    $Formats = Resolve-FormatParameter -FileFormat $FileFormat -OutputFormat $OutputFormat

    ForEach ($Format in $Formats) {

        # Convert the list of permission groupings list to an HTML table
        $PermissionGroupings = $FormattedPermission."$Format`Group"
        $Permissions = $FormattedPermission.$Format
        $ReportFile = $ReportFile -replace 'PermissionsReport', "PermissionsReport_$Format"
        $ReportFileList += $ReportFile

        # Convert the list of generated report files to a Bootstrap list group
        $HtmlListOfReports = $ReportFileList |
        Split-Path -Leaf |
        ConvertTo-HtmlList |
        ConvertTo-BootstrapListGroup

        # Arrange the lists of generated files in two Bootstrap columns
        Write-LogMsg @LogParams -Text "New-BootstrapColumn -Html '`$HtmlReportsHeading`$HtmlListOfReports',`$HtmlLogsHeading`$HtmlListOfLogs"
        $FileListColumns = New-BootstrapColumn -Html "$HtmlReportsHeading$HtmlListOfReports", "$HtmlLogsHeading$HtmlListOfLogs" -Width 6

        # Combine the alert and the columns of generated files inside a Bootstrap div
        Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText 'Output Folder:' -Content '`$HtmlOutputDir`$FileListColumns'"
        $FileList = New-BootstrapDivWithHeading -HeadingText "Output Folder:" -Content "$HtmlOutputDir$FileListColumns"

        # Generate a footer to include at the bottom of the report
        Write-LogMsg @LogParams -Text "Get-ReportFooter -StopWatch `$StopWatch -ReportInstanceId '$ReportInstanceId' -WhoAmI '$WhoAmI' -ThisFqdn '$ThisFqdn'"
        $FooterParams = @{
            StopWatch        = $StopWatch
            ReportInstanceId = $ReportInstanceId
            WhoAmI           = $WhoAmI
            ThisFqdn         = $ThisFqdn
            ItemCount        = ($Subfolders.Count + $ResolvedFolderTargets.Count)
            PermissionCount  = $Permission.ItemPermissions.Access.Access.Count
            PrincipalCount   = $PrincipalsByResolvedID.Keys.Count
        }
        $ReportFooter = Get-HtmlReportFooter @FooterParams

        $BodyParams = @{
            HtmlFolderPermissions = $Permissions.Div
            HtmlExclusions        = $ExclusionsDiv
            HtmlFileList          = $FileList
            ReportFooter          = $ReportFooter
        }

        switch ($Format) {

            'html' {

                # Combine the header and table inside a Bootstrap div
                Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText '$FolderTableHeader' -Content `$FormattedPermission.$Format`Group.Table"
                $HtmlFolderList = New-BootstrapDivWithHeading -HeadingText $FolderTableHeader -Content $PermissionGroupings.Table

                # Combine all the elements into a single string which will be the innerHtml of the <body> element of the report
                Write-LogMsg @LogParams -Text "Get-HtmlBody -FolderList `$HtmlFolderList -HtmlFolderPermissions `$FormattedPermission.$Format.Div"
                [string]$Body = Get-HtmlBody -FolderList $HtmlFolderList @BodyParams

                # Apply the report template to the generated HTML report body and description
                Write-LogMsg @LogParams -Text "New-BootstrapReport @ReportParameters"
                $Report = New-BootstrapReport @ReportParameters

            }
            'json' {

                Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText '$FolderTableHeader' -Content `$FormattedPermission.$Format`Group.Table"
                $JsonFolderList = New-BootstrapDivWithHeading -HeadingText $FolderTableHeader -Content $PermissionGroupings.Table

                # Combine all the elements into a single string which will be the innerHtml of the <body> element of the report
                Write-LogMsg @LogParams -Text "Get-HtmlBody -FolderList `$JsonFolderList -HtmlFolderPermissions `$FormattedPermission.$Format.Div"
                [string]$Body = Get-HtmlBody -FolderList $JsonFolderList @BodyParams

                # Apply the report template to the generated HTML report body and description
                Write-LogMsg @LogParams -Text "New-BootstrapReport -JavaScript @ReportParameters"
                $Report = New-BootstrapReport -JavaScript -AdditionalScriptHtml $ScriptHtml -Body $Body @ReportParameters

                $ScriptHtml = ConvertTo-ScriptHtml -Permission $Permissions -PermissionGrouping $PermissionGroupings

            }

            default {}

        }

        # Save the report
        $null = Set-Content -LiteralPath $ReportFile -Value $Report

        # Output the name of the report file to the Information stream
        Write-Information $ReportFile

    }

}
