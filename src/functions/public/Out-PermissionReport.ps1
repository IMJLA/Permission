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

    # Determine all formats specified by the parameters
    $Formats = Resolve-FormatParameter -FileFormat $FileFormat -OutputFormat $OutputFormat

    ForEach ($Split in $SplitBy) {

        $Subproperty = ''

        if ($Split -eq 'none') {
            $ReportFiles = @{
                NetworkPaths = $FormattedPermission['SplitByTarget'].NetworkPaths
                Path         = $FormattedPermission['SplitByTarget'].Path.FullName
            }
        } else {
            if ($Split -ne 'target') {
                $Subproperty = 'NetworkPaths.'
            }
            $ReportFiles = $FormattedPermission["SplitBy$Split"]
        }

        ForEach ($File in $ReportFiles) {

            [hashtable]$Params = $PSBoundParameters
            $Params['TargetPath'] = $File.Path
            $Params['NetworkPath'] = $File.NetworkPaths
            $HtmlElements = Get-HtmlReportElements @Params

            ForEach ($Format in $Formats) {

                # Convert the list of permission groupings list to an HTML table

                $PermissionGroupings = $File."$Subproperty$Format`Group"
                $Permissions = $File."$Subproperty$Format"

                $BodyParams = @{
                    HtmlFolderPermissions = $Permissions.Div
                    HtmlExclusions        = $HtmlElements.ExclusionsDiv
                    HtmlFileList          = $HtmlElements.HtmlDivOfFiles
                    ReportFooter          = $HtmlElements.ReportFooter
                    SummaryDivHeader      = $HtmlElements.SummaryDivHeader
                    DetailDivHeader       = $HtmlElements.DetailDivHeader
                    NetworkPathDiv        = $HtmlElements.NetworkPathDiv
                }

                # TODO: Can this move up out of the loop?
                $DetailScripts = @(
                    { $TargetPath },
                    { $Parent },
                    { $ACLsByPath.Keys },
                    { $ACLsByPath.Values },
                    { ForEach ($val in $ACEsByGUID.Values) { $val } },
                    { ForEach ($val in $PrincipalsByResolvedID.Values) { $val } },
                    {

                        switch ($GroupBy) {
                            'none' { $Permission.FlatPermissions }
                            'item' { $Permission.ItemPermissions }
                            default { $Permission.AccountPermissions } # 'account'
                        }

                    },
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
                    'Item paths',
                    'Resolved item paths (server names and DFS targets resolved)'
                    'Expanded resolved item paths (resolved target paths expanded into their children)',
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
                            { $Report | Export-Csv -NoTypeInformation -LiteralPath $ThisReportFile },
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

                            if ($Permission.FlatPermissions) {

                                # Combine all the elements into a single string which will be the innerHtml of the <body> element of the report
                                Write-LogMsg @LogParams -Text "Get-HtmlBody -HtmlFolderPermissions `$FormattedPermission.$Format.Div"
                                $Body = Get-HtmlBody @BodyParams

                                # Apply the report template to the generated HTML report body and description
                                $ReportParameters = $HtmlElements.ReportParameters
                                Write-LogMsg @LogParams -Text "New-BootstrapReport @ReportParameters"
                                New-BootstrapReport -Body $Body @ReportParameters

                            } else {

                                # Combine the header and table inside a Bootstrap div
                                Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText '$HtmlElements.SummaryTableHeader' -Content `$FormattedPermission.$Format`Group.Table"
                                $TableOfContents = New-BootstrapDivWithHeading -HeadingText $HtmlElements.SummaryTableHeader -Content $PermissionGroupings.Table -Class 'h-100 p-1 bg-light border rounded-3 table-responsive'

                                # Combine all the elements into a single string which will be the innerHtml of the <body> element of the report
                                Write-LogMsg @LogParams -Text "Get-HtmlBody -TableOfContents `$TableOfContents -HtmlFolderPermissions `$FormattedPermission.$Format.Div"
                                $Body = Get-HtmlBody -TableOfContents $TableOfContents @BodyParams

                            }

                            # Apply the report template to the generated HTML report body and description
                            Write-LogMsg @LogParams -Text "New-BootstrapReport @$HtmlElements.ReportParameters"
                            New-BootstrapReport -Body $Body @$HtmlElements.ReportParameters

                        }

                        $DetailExports = @(
                            { $Report | Out-File -LiteralPath $ThisReportFile },
                            { $Report | Out-File -LiteralPath $ThisReportFile },
                            { $Report -join "<br />`r`n" | Out-File -LiteralPath $ThisReportFile },
                            { $Report | ConvertTo-Html -Fragment | Out-File -LiteralPath $ThisReportFile },
                            { $Report | ConvertTo-Html -Fragment | Out-File -LiteralPath $ThisReportFile },
                            { $Report | ConvertTo-Html -Fragment | Out-File -LiteralPath $ThisReportFile },
                            { $Report | ConvertTo-Html -Fragment | Out-File -LiteralPath $ThisReportFile },
                            { $Report | Out-File -LiteralPath $ThisReportFile },
                            { <#$Report | ConvertTo-Html -Fragment | Out-File -LiteralPath $ThisReportFile#> },
                            { <#$Report | ConvertTo-Html -Fragment | Out-File -LiteralPath $ThisReportFile#> },
                            { $null = Set-Content -LiteralPath $ThisReportFile -Value $Report }
                        )

                        ForEach ($Level in $Detail) {

                            # Get shorter versions of the detail strings to use in file names
                            $ShortDetail = $DetailStrings[$Level] -replace '\([^\)]*\)', ''

                            # Convert the shorter strings to Title Case
                            $TitleCaseDetail = $Culture.TextInfo.ToTitleCase($ShortDetail)

                            # Remove spaces from the shorter strings
                            $SpacelessDetail = $TitleCaseDetail -replace '\s', ''

                            # Build the file path
                            $ThisReportFile = "$OutputDir\$Level`_$SpacelessDetail.htm"

                            # Generate the report
                            $Report = Invoke-Command -ScriptBlock $DetailScripts[$Level]

                            # Save the report
                            $null = Invoke-Command -ScriptBlock $DetailExports[$Level]

                            # Output the name of the report file to the Information stream
                            Write-Information $ThisReportFile

                        }

                    }

                    'json' {

                        $DetailScripts[10] = {

                            if ($Permission.FlatPermissions) {

                                # Combine all the elements into a single string which will be the innerHtml of the <body> element of the report
                                Write-LogMsg @LogParams -Text "Get-HtmlBody -HtmlFolderPermissions `$FormattedPermission.$Format.Div"
                                $Body = Get-HtmlBody @BodyParams

                            } else {

                                # Combine the header and table inside a Bootstrap div
                                Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText '$HtmlElements.SummaryTableHeader' -Content `$FormattedPermission.$Format`Group.Table"
                                $TableOfContents = New-BootstrapDivWithHeading -HeadingText $HtmlElements.SummaryTableHeader -Content $PermissionGroupings.Table -Class 'h-100 p-1 bg-light border rounded-3 table-responsive'

                                # Combine all the elements into a single string which will be the innerHtml of the <body> element of the report
                                Write-LogMsg @LogParams -Text "Get-HtmlBody -TableOfContents `$TableOfContents -HtmlFolderPermissions `$FormattedPermission.$Format.Div"
                                $Body = Get-HtmlBody -TableOfContents $TableOfContents @BodyParams

                            }

                            # Build the JavaScript scripts
                            Write-LogMsg @LogParams -Text "ConvertTo-ScriptHtml -Permission `$Permissions -PermissionGrouping `$PermissionGroupings"
                            $ScriptHtml = ConvertTo-ScriptHtml -Permission $Permissions -PermissionGrouping $PermissionGroupings -GroupBy $GroupBy

                            # Apply the report template to the generated HTML report body and description
                            Write-LogMsg @LogParams -Text "New-BootstrapReport -JavaScript @$HtmlElements.ReportParameters"
                            New-BootstrapReport -JavaScript -AdditionalScriptHtml $ScriptHtml -Body $Body @$HtmlElements.ReportParameters

                        }

                        $DetailExports = @(
                            { $Report | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $ThisReportFile },
                            { $Report | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $ThisReportFile },
                            { $Report | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $ThisReportFile },
                            { $Report | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $ThisReportFile },
                            { $Report | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $ThisReportFile },
                            { $Report | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $ThisReportFile },
                            { $Report | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $ThisReportFile },
                            { $Report | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $ThisReportFile },
                            { <#$Report | ConvertTo-Json -Compress | Out-File -LiteralPath $ThisReportFile#> },
                            { <#$Report | ConvertTo-Json -Compress | Out-File -LiteralPath $ThisReportFile#> },
                            { $null = Set-Content -LiteralPath $ThisReportFile -Value $Report }
                        )

                        ForEach ($Level in $Detail) {

                            # Get shorter versions of the detail strings to use in file names
                            $ShortDetail = $DetailStrings[$Level] -replace '\([^\)]*\)', ''

                            # Convert the shorter strings to Title Case
                            $TitleCaseDetail = $Culture.TextInfo.ToTitleCase($ShortDetail)

                            # Remove spaces from the shorter strings
                            $SpacelessDetail = $TitleCaseDetail -replace '\s', ''

                            # Build the file path
                            $ThisReportFile = "$OutputDir\$Level`_$SpacelessDetail`_$Format.htm"

                            # Generate the report
                            $Report = Invoke-Command -ScriptBlock $DetailScripts[$Level]

                            # Save the report
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

    }

}
