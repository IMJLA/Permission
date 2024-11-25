function Out-PermissionFile {

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

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        # Expects an NTAccount Name (e.g. DOMAIN\user)
        [String]$WhoAmI = (whoami.EXE),

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

        <#
        Level of detail to export to file
            0   Item paths                                                                                  $TargetPath
            1   Resolved item paths (server names resolved, DFS targets resolved)                           $Parents
            2   Expanded resolved item paths (parent paths expanded into children)                          $AclByPath.Keys
            3   Access rules                                                                                $AclByPath.Values
            4   Resolved access rules (server names resolved, inheritance flags resolved)                   $AceByGUID.Values | %{$_} | Sort Path,IdentityReferenceResolved
            5   Accounts with access                                                                        $PrincipalByID.Values | %{$_} | Sort ResolvedAccountName
            6   Expanded resolved access rules (expanded with account info)                                 $Permissions
            7   Formatted permissions                                                                       $FormattedPermissions
            8   Best Practice issues                                                                        $BestPracticeEval
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
        [String]$OutputFormat = 'passthru',

        <#
        How to group the permissions in the output stream and within each exported file

            SplitBy GroupBy
            none    none    $FlatPermissions all in 1 file per $TargetPath
            none    account $AccountPermissions all in 1 file per $TargetPath
            none    item    $ItemPermissions all in 1 file per $TargetPath (default behavior)

            item    none    1 file per item in $ItemPermissions.  In each file, $_.Access | sort account
            item    account 1 file per item in $ItemPermissions.  In each file, $_.Access | group account | sort name
            item    item    (same as -SplitBy item -GroupBy none)

            account none    1 file per item in $AccountPermissions.  In each file, $_.Access | sort path
            account account (same as -SplitBy account -GroupBy none)
            account item    1 file per item in $AccountPermissions.  In each file, $_.Access | group item | sort name
        #>
        [ValidateSet('account', 'item', 'none', 'target')]
        [String]$GroupBy = 'item',

        <#
        How to split up the exported files:
            none    generate 1 file with all permissions
            target  generate 1 file per target
            item    generate 1 file per item
            account generate 1 file per account
            all     generate 1 file per target and 1 file per item and 1 file per account and 1 file with all permissions.
        #>
        [ValidateSet('none', 'all', 'target', 'item', 'account')]
        [string[]]$SplitBy = 'target',

        [PSCustomObject]$BestPracticeEval,

        [uint64]$TargetCount,
        [uint64]$ParentCount,
        [uint64]$ChildCount,
        [uint64]$ItemCount,
        [uint64]$FqdnCount,
        [uint64]$AclCount,
        [uint64]$AceCount,
        [uint64]$IdCount,
        [UInt64]$PrincipalCount,

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $AceByGUID = $Cache.Value['AceByGUID']
    $AclByPath = $Cache.Value['AclByPath']
    $PrincipalByID = $Cache.Value['PrincipalByID']
    $Parent = $Cache.Value['ParentByTargetPath']

    # Determine all formats specified by the parameters
    $Formats = Resolve-FormatParameter -FileFormat $FileFormat -OutputFormat $OutputFormat

    # String translations indexed by value in the $Detail parameter
    # TODO: Move to i18n
    $DetailStrings = @(
        'Item paths',
        'Resolved item paths (server names and DFS targets resolved)',
        'Expanded resolved item paths (resolved target paths expanded into their children)',
        'Access lists',
        'Access rules (resolved identity references and inheritance flags)',
        'Accounts with access',
        'Expanded access rules (expanded with account info)', # #ToDo: Expand DirectoryEntry objects in the DirectoryEntry and Members properties
        'Formatted permissions',
        'Best Practice issues',
        'Custom sensor output for Paessler PRTG Network Monitor',
        'Permission report'
    )

    $UnsplitDetail = $Detail | Where-Object -FilterScript { $_ -le 5 -or $_ -in 8, 9 }
    $SplitDetail = $Detail | Where-Object -FilterScript { $_ -gt 5 -and $_ -notin 8, 9 }

    $DetailScripts = @(
        { $TargetPath },
        { ForEach ($Key in $Parent.Value.Keys) {
                [PSCustomObject]@{
                    OriginalTargetPath  = $Key
                    ResolvedNetworkPath = $Parent.Value[$Key]
                }
            }
        },
        { $AclByPath.Value.Keys },
        { $AclByPath.Value.Values },
        { ForEach ($val in $AceByGUID.Value.Values) { $val } },
        { ForEach ($val in $PrincipalByID.Value.Values) { $val } },
        {

            switch ($SplitBy) {
                'account' { $Permission.AccountPermissions ; break }
                'none' { $Permission.FlatPermissions ; break }
                'item' { $Permission.ItemPermissions ; break }
                'target' { $Permission.TargetPermissions ; break }
            }

        },
        { $Permissions.Data },
        { $BestPracticeEval },
        { ConvertTo-PermissionPrtgXml -Analysis $Analysis },
        {}
    )

    ForEach ($Split in $Permission.SplitBy.Keys) {

        switch ($Split) {

            'account' {
                $Subproperty = ''
                $FileNameProperty = $Split
                $FileNameSubproperty = 'ResolvedAccountName'
                $ReportFiles = $FormattedPermission["SplitBy$Split"]
                break
            }

            'item' {
                $Subproperty = ''
                $FileNameProperty = $Split
                $FileNameSubproperty = 'Path'
                $ReportFiles = $FormattedPermission["SplitBy$Split"]
                break
            }

            'none' {
                $Subproperty = 'NetworkPaths'
                $FileNameProperty = ''
                $FileNameSubproperty = 'Path'
                $ReportFiles = [PSCustomObject]@{
                    NetworkPaths = $FormattedPermission['SplitByTarget'].NetworkPaths
                    Path         = $FormattedPermission['SplitByTarget'].Path.FullName
                }
                break
            }

            'target' {
                $Subproperty = 'NetworkPaths'
                $FileNameProperty = ''
                $FileNameSubproperty = 'Path'
                $ReportFiles = $FormattedPermission["SplitBy$Split"]
                break
            }

        }

        ForEach ($Format in $Formats) {

            $FormatString = $Format
            $FormatDir = "$OutputDir\$Format"
            $null = New-Item -Path $FormatDir -ItemType Directory -ErrorAction SilentlyContinue

            switch ($Format) {

                'csv' {

                    $DetailExports = @(
                        { $args[0] | Out-File -LiteralPath $args[1] },
                        { $args[0] | Export-Csv -NoTypeInformation -LiteralPath $args[1] },
                        { $args[0] | Out-File -LiteralPath $args[1] },
                        { $args[0] | Export-Csv -NoTypeInformation -LiteralPath $args[1] },
                        { $args[0] | Export-Csv -NoTypeInformation -LiteralPath $args[1] },
                        { $args[0] | Export-Csv -NoTypeInformation -LiteralPath $args[1] },
                        { $args[0] | Export-Csv -NoTypeInformation -LiteralPath $args[1] },
                        { $args[0] | Out-File -LiteralPath $args[1] },
                        { },
                        { },
                        { }
                    )

                    $DetailScripts[10] = { }
                    break

                }

                'html' {

                    $DetailExports = @(
                        { $args[0] | Out-File -LiteralPath $args[1] },
                        { $args[0] | ConvertTo-Html -Fragment | Out-File -LiteralPath $args[1] },
                        { $args[0] -join "<br />`r`n" | Out-File -LiteralPath $args[1] },
                        { $args[0] | ConvertTo-Html -Fragment | Out-File -LiteralPath $args[1] },
                        { $args[0] | ConvertTo-Html -Fragment | Out-File -LiteralPath $args[1] },
                        { $args[0] | ConvertTo-Html -Fragment | Out-File -LiteralPath $args[1] },
                        { $args[0] | ConvertTo-Html -Fragment | Out-File -LiteralPath $args[1] },
                        { $args[0] | Out-File -LiteralPath $args[1] },
                        { },
                        { },
                        { $null = Set-Content -LiteralPath $args[1] -Value $args[0] }
                    )

                    $DetailScripts[10] = {

                        if (
                            $GroupBy -eq 'none' -or
                            $GroupBy -eq $Split
                        ) {

                            # Combine all the elements into a single string which will be the innerHtml of the <body> element of the report
                            Write-LogMsg @LogParams -Text "Get-HtmlBody -HtmlFolderPermissions `$FormattedPermission.$Format.Div"
                            $Body = Get-HtmlBody @BodyParams

                            # Apply the report template to the generated HTML report body and description
                            $ReportParameters = $HtmlElements.ReportParameters

                            Write-LogMsg @LogParams -Text 'New-BootstrapReport @ReportParameters'
                            New-BootstrapReport -Body $Body @ReportParameters

                        } else {

                            # Combine the header and table inside a Bootstrap div
                            Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText '$HtmlElements.SummaryTableHeader' -Content `$FormattedPermission.$Format`Group.Table"
                            $TableOfContents = New-BootstrapDivWithHeading -HeadingText $HtmlElements.SummaryTableHeader -Content $PermissionGroupings.Table -Class 'h-100 p-1 bg-light border rounded-3 table-responsive' -HeadingLevel 6

                            # Combine all the elements into a single string which will be the innerHtml of the <body> element of the report
                            Write-LogMsg @LogParams -Text "Get-HtmlBody -TableOfContents `$TableOfContents -HtmlFolderPermissions `$FormattedPermission.$Format.Div"
                            $Body = Get-HtmlBody -TableOfContents $TableOfContents @BodyParams

                        }

                        $ReportParameters = $HtmlElements.ReportParameters

                        # Apply the report template to the generated HTML report body and description
                        Write-LogMsg @LogParams -Text "New-BootstrapReport @$HtmlElements.ReportParameters"
                        New-BootstrapReport -Body $Body @ReportParameters

                    }
                    break

                }

                'js' {

                    $DetailExports = @(
                        { $args[0] | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $args[1] },
                        { $args[0] | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $args[1] },
                        { $args[0] | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $args[1] },
                        { $args[0] | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $args[1] },
                        { $args[0] | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $args[1] },
                        { $args[0] | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $args[1] },
                        { $args[0] | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $args[1] },
                        { $args[0] | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $args[1] },
                        { },
                        { },
                        { $null = Set-Content -LiteralPath $args[1] -Value $args[0] }
                    )

                    $DetailScripts[10] = {

                        #if ($Permission.FlatPermissions) {
                        if (
                            $GroupBy -eq 'none' -or
                            $GroupBy -eq $Split
                        ) {

                            # Combine all the elements into a single string which will be the innerHtml of the <body> element of the report
                            Write-LogMsg @LogParams -Text "Get-HtmlBody -HtmlFolderPermissions `$FormattedPermission.$Format.Div"
                            $Body = Get-HtmlBody @BodyParams

                        } else {

                            # Combine the header and table inside a Bootstrap div
                            Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText '$HtmlElements.SummaryTableHeader' -Content `$FormattedPermission.$Format`Group.Table"
                            $TableOfContents = New-BootstrapDivWithHeading -HeadingText $HtmlElements.SummaryTableHeader -Content $PermissionGroupings.Table -Class 'h-100 p-1 bg-light border rounded-3 table-responsive' -HeadingLevel 6

                            # Combine all the elements into a single string which will be the innerHtml of the <body> element of the report
                            Write-LogMsg @LogParams -Text "Get-HtmlBody -TableOfContents `$TableOfContents -HtmlFolderPermissions `$FormattedPermission.$Format.Div"
                            $Body = Get-HtmlBody -TableOfContents $TableOfContents @BodyParams

                        }

                        # Build the JavaScript scripts
                        Write-LogMsg @LogParams -Text "ConvertTo-ScriptHtml -Permission `$Permissions -PermissionGrouping `$PermissionGroupings"
                        $ScriptHtml = ConvertTo-ScriptHtml -Permission $Permissions -PermissionGrouping $PermissionGroupings -GroupBy $GroupBy -Split $Split
                        $ReportParameters = $HtmlElements.ReportParameters

                        # Apply the report template to the generated HTML report body and description
                        Write-LogMsg @LogParams -Text "New-BootstrapReport -JavaScript @$HtmlElements.ReportParameters"
                        New-BootstrapReport -JavaScript -AdditionalScriptHtml $ScriptHtml -Body $Body @ReportParameters

                    }

                    $FormatString = 'json'
                    break

                }

                'json' {

                    $DetailExports = @(
                        { $args[0] | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $args[1] },
                        { $args[0] | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $args[1] },
                        { $args[0] | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $args[1] },
                        { $args[0] | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $args[1] },
                        { $args[0] | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $args[1] },
                        { $args[0] | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $args[1] },
                        { $args[0] | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $args[1] },
                        { $args[0] | ConvertTo-Json -Compress -WarningAction SilentlyContinue | Out-File -LiteralPath $args[1] },
                        { },
                        { },
                        { }
                    )

                    $DetailScripts[10] = { }
                    break

                }

                'prtgxml' {

                    $DetailExports = @( { }, { }, { }, { }, { }, { }, { }, { }, { }, { $args[0] | Out-File -LiteralPath $args[1] } )
                    break

                }

                'xml' {

                    $DetailExports = @(
                        { ($args[0] | ConvertTo-Xml).InnerXml | Out-File -LiteralPath $args[1] },
                        { ($args[0] | ConvertTo-Xml).InnerXml | Out-File -LiteralPath $args[1] },
                        { ($args[0] | ConvertTo-Xml).InnerXml | Out-File -LiteralPath $args[1] },
                        { ($args[0] | ConvertTo-Xml).InnerXml | Out-File -LiteralPath $args[1] },
                        { ($args[0] | ConvertTo-Xml).InnerXml | Out-File -LiteralPath $args[1] },
                        { ($args[0] | ConvertTo-Xml).InnerXml | Out-File -LiteralPath $args[1] },
                        { ($args[0] | ConvertTo-Xml).InnerXml | Out-File -LiteralPath $args[1] },
                        { ($args[0] | ConvertTo-Xml).InnerXml | Out-File -LiteralPath $args[1] },
                        { }, { }, { }
                    )

                    $DetailScripts[10] = { }
                    break

                }

            }

            $ReportObjects = @{}

            ForEach ($Level in $UnsplitDetail) {

                # Save the report
                $ReportObjects[$Level] = Invoke-Command -ScriptBlock $DetailScripts[$Level]

                Out-PermissionDetailReport -Detail $Level -ReportObject $ReportObjects -DetailExport $DetailExports -Format $Format -OutputDir $FormatDir -Culture $Culture -DetailString $DetailStrings

            }

            ForEach ($File in $ReportFiles) {

                if ($Subproperty -eq '') {
                    $Subfile = $File
                } else {
                    $Subfile = $File.$Subproperty
                }

                if ($FileNameProperty -eq '') {
                    $FileName = $File.$FileNameSubproperty
                } else {
                    $FileName = $File.$FileNameProperty.$FileNameSubproperty
                }

                $FileName = $FileName -replace '\\\\', '' -replace '\\', '_' -replace '\:', ''

                # Convert the list of permission groupings list to an HTML table
                $PermissionGroupings = $Subfile."$FormatString`Group"
                $Permissions = $Subfile.$FormatString

                $ReportObjects = @{}

                [Hashtable]$Params = $PSBoundParameters
                $Params['TargetPath'] = $File.Path
                $Params['NetworkPath'] = $File.NetworkPaths
                $Params['Split'] = $Split
                $Params['FileName'] = $FileName
                $HtmlElements = Get-HtmlReportElements @Params

                $BodyParams = @{
                    HtmlFolderPermissions = $Permissions.Div
                    HtmlExclusions        = $HtmlElements.ExclusionsDiv
                    HtmlFileList          = $HtmlElements.HtmlDivOfFiles
                    ReportFooter          = $HtmlElements.ReportFooter
                    SummaryDivHeader      = $HtmlElements.SummaryDivHeader
                    DetailDivHeader       = $HtmlElements.DetailDivHeader
                    NetworkPathDiv        = $HtmlElements.NetworkPathDiv
                }

                ForEach ($Level in $SplitDetail) {

                    # Save the report
                    $ReportObjects[$Level] = Invoke-Command -ScriptBlock $DetailScripts[$Level]

                }

                switch ($Format) {

                    'csv' {

                        Out-PermissionDetailReport -Detail $SplitDetail -ReportObject $ReportObjects -DetailExport $DetailExports -Format $Format -OutputDir $FormatDir -Culture $Culture -DetailString $DetailStrings
                        break

                    }

                    'html' {

                        Out-PermissionDetailReport -Detail $SplitDetail -ReportObject $ReportObjects -DetailExport $DetailExports -Format $Format -OutputDir $FormatDir -FileName $FileName -Culture $Culture -DetailString $DetailStrings
                        break

                    }

                    'js' {

                        Out-PermissionDetailReport -Detail $SplitDetail -ReportObject $ReportObjects -DetailExport $DetailExports -Format $Format -OutputDir $FormatDir -FileName $FileName -Culture $Culture -DetailString $DetailStrings
                        break

                    }

                    # Nothing for 'prtgxml' because it is an Unsplit detail level only

                    'xml' {

                        Out-PermissionDetailReport -Detail $SplitDetail -ReportObject $ReportObjects -DetailExport $DetailExports -Format $Format -OutputDir $FormatDir -Culture $Culture -DetailString $DetailStrings
                        break

                    }

                }

            }

        }

    }

}
