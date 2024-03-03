function Out-PermissionReport {

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
        [string[]]$ReportFileList = @(),
        $ReportFile,
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

        $Culture = (Get-Culture)

    )

    Write-LogMsg @LogParams -Text "Get-ReportDescription -RecurseDepth $RecurseDepth"
    $ReportDescription = Get-ReportDescription -RecurseDepth $RecurseDepth

    Write-LogMsg @LogParams -Text "Get-SummaryTableHeader -RecurseDepth $RecurseDepth"
    $SummaryTableHeader = Get-SummaryTableHeader -RecurseDepth $RecurseDepth

    # Convert the target path(s) to a Bootstrap alert
    $TargetPathString = $TargetPath -join '<br />'
    Write-LogMsg @LogParams -Text "New-BootstrapAlert -Class Dark -Text '$TargetPathString'"
    $TargetAlert = New-BootstrapAlert -Class Dark -Text $TargetPathString

    $ReportParameters = @{
        Title       = $Title
        Description = "$TargetAlert $ReportDescription"
    }

    $ExcludedNames = ConvertTo-NameExclusionDiv -ExcludeAccount $ExcludeAccount
    $ExcludedClasses = ConvertTo-ClassExclusionDiv -ExcludeClass $ExcludeClass
    $IgnoredDomains = ConvertTo-IgnoredDomainDiv -IgnoreDomain $IgnoreDomain
    $ExcludedMembers = ConvertTo-MemberExclusionDiv -NoMembers:$NoMembers

    # Arrange the exclusions in two Bootstrap columns
    Write-LogMsg @LogParams -Text "New-BootstrapColumn -Html '`$ExcludedMembers`$ExcludedClasses',`$IgnoredDomains`$ExcludedNames"
    $ExclusionsDiv = New-BootstrapColumn -Html "$ExcludedMembers$ExcludedClasses", "$IgnoredDomains$ExcludedNames" -Width 6

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

    # Determine all formats specified by the parameters
    $Formats = Resolve-FormatParameter -FileFormat $FileFormat -OutputFormat $OutputFormat

    ForEach ($Format in $Formats) {

        # Convert the list of permission groupings list to an HTML table
        $PermissionGroupings = $FormattedPermission."$Format`Group"
        $Permissions = $FormattedPermission.$Format

        $DetailScripts = @(
            { $TargetPath },
            { $Parent },
            { $ACLsByPath.Keys },
            { $ACLsByPath.Values },
            { ForEach ($val in $ACEsByGUID.Values) { $val } },
            { ForEach ($val in $PrincipalsByResolvedID.Values) { $val } },
            { $Permission },
            { $Permissions.Data },
            { $BestPracticeIssues },
            { $PrtgXml },
            {}
        )

        $ReportObjects = @{}

        ForEach ($Level in $Detail) {

            # Save the report
            $ReportObjects[$Level] = Invoke-Command -ScriptBlock $DetailScripts[$Level]

        }

        # String translations indexed by value in the $Detail parameter
        # TODO: Move to i18n
        $DetailStrings = @(
            'Target paths',
            'Resolved target paths (server names and DFS targets resolved)'
            'Item paths (resolved target paths expanded into their children)',
            'Access lists',
            'Access rules (resolved identity references and inheritance flags)',
            'Accounts with access',
            'Expanded access rules (expanded with account info)', # #ToDo: Expand DirectoryEntry objects in the DirectoryEntry and Members properties
            'Formatted permissions',
            'Best Practice issues',
            'Custom sensor output for Paessler PRTG Network Monitor'
            'Permission report'
        )

        switch ($Format) {

            'csv' {

                $DetailExports = @(
                    { $Report | Out-File -LiteralPath $ThisReportFile },
                    { $Report | Out-File -LiteralPath $ThisReportFile },
                    { $Report | Out-File -LiteralPath $ThisReportFile },
                    { $Report | Export-Csv -NoTypeInformation -LiteralPath $ThisReportFile },
                    { $Report | Export-Csv -NoTypeInformation -LiteralPath $ThisReportFile },
                    { $Report | Export-Csv -NoTypeInformation -LiteralPath $ThisReportFile },
                    { <# $Report | Export-Csv -NoTypeInformation -LiteralPath $ThisReportFile#> },
                    { $Report | Out-File -LiteralPath $ThisReportFile },
                    { <# $Report | Export-Csv -NoTypeInformation -LiteralPath $ThisReportFile#> },
                    { <# $Report | Export-Csv -NoTypeInformation -LiteralPath $ThisReportFile#> },
                    { <# $Report | Export-Csv -NoTypeInformation -LiteralPath $ThisReportFile#> }
                )

                ForEach ($Level in $Detail) {

                    # Get shorter versions of the detail strings to use in file names
                    $ShortDetail = $DetailStrings[$Level] -replace '\([^\)]*\)', ''

                    # Convert the shorter strings to Title Case
                    $TitleCaseDetail = $Culture.TextInfo.ToTitleCase($ShortDetail)

                    # Remove spaces from the shorter strings
                    $SpacelessDetail = $TitleCaseDetail -replace '\s', ''

                    # Build the file path
                    $ThisReportFile = "$OutputDir\$Level`_$SpacelessDetail.$Format"

                    # Add the file path to the list of created files
                    $ReportFileList += $ThisReportFile

                    # Generate the report
                    $Report = $ReportObjects[$Level]

                    # Save the report
                    $null = Invoke-Command -ScriptBlock $DetailExports[$Level]

                    # Output the name of the report file to the Information stream
                    Write-Information $ThisReportFile

                }

            }

            'html' {

                $DetailScripts[10] = {

                    # Convert the list of generated report files to a Bootstrap list group
                    $HtmlListOfReports = $ReportFileList |
                    Split-Path -Leaf |
                    #Sort-Object |
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
                        ItemCount        = $ACLsByPath.Keys.Count
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

                    if ($Permission.FlatPermissions) {

                        # Combine all the elements into a single string which will be the innerHtml of the <body> element of the report
                        Write-LogMsg @LogParams -Text "Get-HtmlBody -HtmlFolderPermissions `$FormattedPermission.$Format.Div"
                        $Body = Get-HtmlBody @BodyParams

                        # Apply the report template to the generated HTML report body and description
                        Write-LogMsg @LogParams -Text "New-BootstrapReport @ReportParameters"
                        New-BootstrapReport -Body $Body @ReportParameters

                    } else {

                        # Combine the header and table inside a Bootstrap div
                        Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText '$SummaryTableHeader' -Content `$FormattedPermission.$Format`Group.Table"
                        $TableOfContents = New-BootstrapDivWithHeading -HeadingText $SummaryTableHeader -Content $PermissionGroupings.Table -Class 'h-100 p-1 bg-light border rounded-3 table-responsive'

                        # Combine all the elements into a single string which will be the innerHtml of the <body> element of the report
                        Write-LogMsg @LogParams -Text "Get-HtmlBody -TableOfContents `$TableOfContents -HtmlFolderPermissions `$FormattedPermission.$Format.Div"
                        $Body = Get-HtmlBody -TableOfContents $TableOfContents @BodyParams

                        # Apply the report template to the generated HTML report body and description
                        Write-LogMsg @LogParams -Text "New-BootstrapReport @ReportParameters"
                        New-BootstrapReport -Body $Body @ReportParameters

                    }

                }

                $DetailExports = @(
                    { $Report | Out-File -LiteralPath $ThisReportFile },
                    { $Report | Out-File -LiteralPath $ThisReportFile },
                    { $Report -join "<br />`r`n" | Out-File -LiteralPath $ThisReportFile },
                    { $Report | ConvertTo-Html -Fragment | Out-File -LiteralPath $ThisReportFile },
                    { $Report | ConvertTo-Html -Fragment | Out-File -LiteralPath $ThisReportFile },
                    { $Report | ConvertTo-Html -Fragment | Out-File -LiteralPath $ThisReportFile },
                    { <#$Report | ConvertTo-Html -Fragment | Out-File -LiteralPath $ThisReportFile#> },
                    { $Report | Out-File -LiteralPath $ThisReportFile },
                    { <#$Report | ConvertTo-Html -Fragment | Out-File -LiteralPath $ThisReportFile#> },
                    { <#$Report | ConvertTo-Html -Fragment | Out-File -LiteralPath $ThisReportFile#> },
                    { $null = Set-Content -LiteralPath $ThisReportFile -Value $Report }
                )

                ForEach ($Level in $Detail) {

                    $ShortDetail = $DetailStrings[$Level] -replace '\([^\)]*\)', ''
                    $TitleCaseDetail = $Culture.TextInfo.ToTitleCase($ShortDetail)
                    $SpacelessDetail = $TitleCaseDetail -replace '\s', ''
                    $ThisReportFile = "$OutputDir\$Level`_$SpacelessDetail.htm"
                    $ReportFileList += $ThisReportFile

                    # Save the report
                    $Report = Invoke-Command -ScriptBlock $DetailScripts[$Level]
                    $null = Invoke-Command -ScriptBlock $DetailExports[$Level]

                    # Output the name of the report file to the Information stream
                    Write-Information $ThisReportFile

                }

            }

            'json' {

                $DetailScripts[10] = {

                    # Convert the list of generated report files to a Bootstrap list group
                    $HtmlListOfReports = $ReportFileList |
                    Split-Path -Leaf |
                    #Sort-Object |
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
                        ItemCount        = $ACLsByPath.Keys.Count
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

                    if ($Permission.FlatPermissions) {

                        # Combine all the elements into a single string which will be the innerHtml of the <body> element of the report
                        Write-LogMsg @LogParams -Text "Get-HtmlBody -HtmlFolderPermissions `$FormattedPermission.$Format.Div"
                        $Body = Get-HtmlBody @BodyParams

                        $GroupBy = 'none'

                    } else {

                        # Combine the header and table inside a Bootstrap div
                        Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText '$SummaryTableHeader' -Content `$FormattedPermission.$Format`Group.Table"
                        $TableOfContents = New-BootstrapDivWithHeading -HeadingText $SummaryTableHeader -Content $PermissionGroupings.Table -Class 'h-100 p-1 bg-light border rounded-3 table-responsive'

                        # Combine all the elements into a single string which will be the innerHtml of the <body> element of the report
                        Write-LogMsg @LogParams -Text "Get-HtmlBody -TableOfContents `$TableOfContents -HtmlFolderPermissions `$FormattedPermission.$Format.Div"
                        $Body = Get-HtmlBody -TableOfContents $TableOfContents @BodyParams

                    }

                    # Build the JavaScript scripts
                    Write-LogMsg @LogParams -Text "ConvertTo-ScriptHtml -Permission `$Permissions -PermissionGrouping `$PermissionGroupings"
                    $ScriptHtml = ConvertTo-ScriptHtml -Permission $Permissions -PermissionGrouping $PermissionGroupings -GroupBy $GroupBy

                    # Apply the report template to the generated HTML report body and description
                    Write-LogMsg @LogParams -Text "New-BootstrapReport -JavaScript @ReportParameters"
                    New-BootstrapReport -JavaScript -AdditionalScriptHtml $ScriptHtml -Body $Body @ReportParameters

                }

                $DetailExports = @(
                    { $Report | ConvertTo-Json -Compress | Out-File -LiteralPath $ThisReportFile },
                    { $Report | ConvertTo-Json -Compress | Out-File -LiteralPath $ThisReportFile },
                    { $Report | ConvertTo-Json -Compress | Out-File -LiteralPath $ThisReportFile },
                    { $Report | ConvertTo-Json -Compress | Out-File -LiteralPath $ThisReportFile },
                    { $Report | ConvertTo-Json -Compress | Out-File -LiteralPath $ThisReportFile },
                    { $Report | ConvertTo-Json -Compress | Out-File -LiteralPath $ThisReportFile },
                    { <#$Report | ConvertTo-Json -Compress | Out-File -LiteralPath $ThisReportFile#> },
                    { $Report | ConvertTo-Json -Compress | Out-File -LiteralPath $ThisReportFile },
                    { <#$Report | ConvertTo-Json -Compress | Out-File -LiteralPath $ThisReportFile#> },
                    { <#$Report | ConvertTo-Json -Compress | Out-File -LiteralPath $ThisReportFile#> },
                    { $null = Set-Content -LiteralPath $ThisReportFile -Value $Report }
                )

                ForEach ($Level in $Detail) {

                    $ShortDetail = $DetailStrings[$Level] -replace '\([^\)]*\)', ''
                    $TitleCaseDetail = $Culture.TextInfo.ToTitleCase($ShortDetail)
                    $SpacelessDetail = $TitleCaseDetail -replace '\s', ''
                    $ThisReportFile = "$OutputDir\$Level`_$SpacelessDetail`_$Format.htm"
                    $ReportFileList += $ThisReportFile

                    # Save the report
                    $Report = Invoke-Command -ScriptBlock $DetailScripts[$Level]
                    $null = Invoke-Command -ScriptBlock $DetailExports[$Level]

                    # Output the name of the report file to the Information stream
                    Write-Information $ThisReportFile

                    # Return the report file path of the highest level for the Interactive switch of Export-Permission
                    if ($Level -eq 10) {
                        $ThisReportFile
                    }

                }

            }

            'prtgxml' {

                # Output the full path of the XML file (result of the custom XML sensor for Paessler PRTG Network Monitor) to the Information stream
                #Write-Information $XmlFile

                # Save the XML file to disk
                #$null = Set-Content -LiteralPath $XmlFile -Value $XMLOutput

            }

            default {}

        }

    }

}
