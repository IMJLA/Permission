
function Add-CacheItem {

    # Use a key to get a generic list from a hashtable
    # If it does not exist, create an empty list
    # Add the new item

    param (

        [hashtable]$Cache,

        $Key,

        $Value,

        [type]$Type

    )

    $CacheResult = $Cache[$Key]

    if (-not $CacheResult) {
        $Command = "`$CacheResult = [System.Collections.Generic.List[$($Type.ToString())]]::new()"
        Invoke-Expression $Command
    }

    $CacheResult.Add($Value)
    $Cache[$Key] = $CacheResult

}
function ConvertTo-ItemBlock {

    param (

        $ItemPermissions

    )

    $Culture = Get-Culture

    Write-LogMsg @LogParams -Text "`$ObjectsForTable = Select-ItemTableProperty -InputObject `$ItemPermissions -Culture '$Culture'"
    $ObjectsForTable = Select-ItemTableProperty -InputObject $ItemPermissions -Culture $Culture

    Write-LogMsg @LogParams -Text "`$ObjectsForTable | ConvertTo-Html -Fragment | New-BootstrapTable"
    $HtmlTable = $ObjectsForTable |
    ConvertTo-Html -Fragment |
    New-BootstrapTable

    $JsonData = $ObjectsForTable |
    ConvertTo-Json

    Write-LogMsg @LogParams -Text "Get-FolderColumnJson -InputObject `$ObjectsForTable"
    $JsonColumns = Get-FolderColumnJson -InputObject $ObjectsForTable

    Write-LogMsg @LogParams -Text "ConvertTo-BootstrapJavaScriptTable -Id 'Folders' -InputObject `$ObjectsForTable -DataFilterControl -SearchableColumn 'Folder' -DropdownColumn 'Inheritance'"
    $JsonTable = ConvertTo-BootstrapJavaScriptTable -Id 'Folders' -InputObject $ObjectsForTable -DataFilterControl -SearchableColumn 'Folder' -DropdownColumn 'Inheritance'

    return [pscustomobject]@{
        HtmlDiv     = $HtmlTable
        JsonDiv     = $JsonTable
        JsonData    = $JsonData
        JsonColumns = $JsonColumns
    }

}
function Expand-AcctPermission {

    param (

        # Permission objects from Get-FolderAccessList whose IdentityReference to resolve
        [Parameter(ValueFromPipeline)]
        [object[]]$SecurityPrincipal,

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Maximum number of concurrent threads to allow
        [int]$ThreadCount = (Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum,

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId

    )

    $Progress = @{
        Activity = 'Expand-AcctPermission'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }

    $Count = $SecurityPrincipal.Count
    Write-Progress @Progress -Status "0% (account 0 of $Count)" -CurrentOperation 'Initializing' -PercentComplete 0

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    if ($ThreadCount -eq 1) {

        [int]$ProgressInterval = [math]::max(($Count / 100), 1)
        $IntervalCounter = 0
        $i = 0

        ForEach ($ThisPrinc in $SecurityPrincipal) {

            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {

                [int]$PercentComplete = $i / $Count * 100
                Write-Progress @Progress -Status "$PercentComplete% (account $($i+1) of $Count)" -CurrentOperation "Expand-AccountPermission '$($ThisPrinc.Name)'" -PercentComplete $PercentComplete
                $IntervalCounter = 0

            }

            $i++
            Write-LogMsg @LogParams -Text "Expand-AccountPermission -AccountPermission $($ThisPrinc.Name)"
            Expand-AccountPermission -AccountPermission $ThisPrinc

        }

    } else {

        $ExpandAccountPermissionParams = @{
            Command              = 'Expand-AccountPermission'
            InputObject          = $SecurityPrincipal
            InputParameter       = 'AccountPermission'
            TodaysHostname       = $ThisHostname
            ObjectStringProperty = 'Name'
            Timeout              = 1200
            Threads              = $ThreadCount
        }

        Write-LogMsg @LogParams -Text "Split-Thread -Command 'Expand-AccountPermission' -InputParameter 'AccountPermission' -InputObject `$SecurityPrincipal -ObjectStringProperty 'Name'"
        Split-Thread @ExpandAccountPermissionParams

    }

    Write-Progress @Progress -Completed

}
function Expand-PermissionPrincipal {

    # Expand ADSI security principals into their group members

    param (

        # Thread-safe hashtable to use for caching directory entries and avoiding duplicate directory queries
        [hashtable]$PrincipalsByResolvedID = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Maximum number of concurrent threads to allow
        [int]$ThreadCount = (Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum,

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId

    )

    $Progress = @{
        Activity = 'Expand-PermissionPrincipal'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }

    Write-Progress @Progress -Status "0% (principal 0 of $Count)" -CurrentOperation 'Initializing' -PercentComplete 0

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $ResolvedIDs = $PrincipalsByResolvedID.Keys
    $Count = $ResolvedIDs.Count

    $FormatSecurityPrincipalParams = @{
        PrincipalsByResolvedID = $PrincipalsByResolvedID
    }

    if ($ThreadCount -eq 1) {

        [int]$ProgressInterval = [math]::max(($Count / 100), 1)
        $IntervalCounter = 0
        $i = 0

        ForEach ($ThisID in $ResolvedIDs) {

            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {

                [int]$PercentComplete = $i / $Count * 100
                Write-Progress @Progress -Status "$PercentComplete% (principal $($i + 1) of $Count) Format-SecurityPrincipal" -CurrentOperation $ThisID -PercentComplete $PercentComplete
                $IntervalCounter = 0

            }

            $i++
            Write-LogMsg @LogParams -Text "Format-SecurityPrincipal -ResolvedID '$ThisID'"
            Format-SecurityPrincipal -ResolvedID $ThisID @FormatSecurityPrincipalParams

        }

    } else {

        $SplitThreadParams = @{
            Command              = 'Format-SecurityPrincipal'
            InputObject          = $ResolvedIDs
            InputParameter       = 'ResolvedID'
            Timeout              = 1200
            ObjectStringProperty = 'Name'
            TodaysHostname       = $ThisHostname
            WhoAmI               = $WhoAmI
            LogMsgCache          = $LogMsgCache
            Threads              = $ThreadCount
            AddParam             = $FormatSecurityPrincipalParams
        }

        Write-LogMsg @LogParams -Text "Split-Thread -Command 'Format-SecurityPrincipal' -InputParameter 'SecurityPrincipal' -InputObject `$SecurityPrincipal -ObjectStringProperty 'Name'"
        Split-Thread @SplitThreadParams

    }

    Write-Progress @Progress -Completed

}
function Expand-PermissionTarget {

    # Expand a folder path into the paths of its subfolders

    param (

        <#
        How many levels of subfolder to enumerate

            Set to 0 to ignore all subfolders

            Set to -1 (default) to recurse infinitely

            Set to any whole number to enumerate that many levels
        #>
        $RecurseDepth,

        # Number of asynchronous threads to use
        [uint16]$ThreadCount = ((Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum),

        # Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module
        [string]$DebugOutputStream = 'Silent',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$ThisHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId,

        # Cache of access control lists keyed by path
        [hashtable]$ACLsByPath = [hashtable]::Synchronized(@{})

    )

    $Progress = @{
        Activity = 'Expand-PermissionTarget'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }

    $Targets = $ACLsByPath.Keys
    $TargetCount = $Targets.Count
    Write-Progress @Progress -Status "0% (item 0 of $TargetCount)" -CurrentOperation "Initializing..." -PercentComplete 0

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $GetSubfolderParams = @{
        LogMsgCache       = $LogMsgCache
        ThisHostname      = $ThisHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
    }

    if ($ThreadCount -eq 1 -or $TargetCount -eq 1) {

        [int]$ProgressInterval = [math]::max(($TargetCount / 100), 1)
        $IntervalCounter = 0
        $i = 0

        ForEach ($ThisFolder in $Targets) {

            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {
                [int]$PercentComplete = $i / $TargetCount * 100
                Write-Progress @Progress -Status "$PercentComplete% (item $($i + 1) of $TargetCount))" -CurrentOperation "Get-Subfolder '$($ThisFolder)'" -PercentComplete $PercentComplete
                $IntervalCounter = 0
            }

            $i++ # increment $i after the progress to show progress conservatively rather than optimistically
            $Subfolders = $null
            $Subfolders = Get-Subfolder -TargetPath $ThisFolder -FolderRecursionDepth $RecurseDepth -ErrorAction Continue @GetSubfolderParams
            Write-LogMsg @LogParams -Text "# Folders (including parent): $($Subfolders.Count + 1) for '$ThisFolder'"
            $Subfolders

        }

    } else {

        $SplitThreadParams = @{
            Command           = 'Get-Subfolder'
            InputObject       = $Targets
            InputParameter    = 'TargetPath'
            DebugOutputStream = $DebugOutputStream
            TodaysHostname    = $ThisHostname
            WhoAmI            = $WhoAmI
            LogMsgCache       = $LogMsgCache
            Threads           = $ThreadCount
            AddParam          = $GetSubfolderParams
        }

        $Subfolders = Split-Thread @SplitThreadParams
        Write-LogMsg @LogParams -Text "# Folders (including parent): $($Subfolders.Count + 1) for all targets"
        $Subfolders

    }

    Write-Progress @Progress -Completed

}
function Export-FolderPermissionHtml {

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

        $ItemPermissions,
        $LogParams,
        $ReportDescription,
        $FolderTableHeader,
        $ReportFileList,
        $ReportFile,
        $LogFileList,
        $ReportInstanceId,
        $Subfolders,
        $ResolvedFolderTargets,
        $PrincipalsByResolvedID,
        $ShortestPath
    )

    # Convert the target path(s) to a Bootstrap alert
    $TargetPathString = $TargetPath -join '<br />'
    Write-LogMsg @LogParams -Text "New-BootstrapAlert -Class Dark -Text '$TargetPathString'"
    $ReportDescription = "$(New-BootstrapAlert -Class Dark -Text $TargetPathString) $ReportDescription"

    # Convert the folder list to an HTML table
    $FormattedFolders = ConvertTo-ItemBlock -ItemPermissions $ItemPermissions

    # Convert the folder permissions to an HTML table
    $GetFolderPermissionsBlock = @{
        FolderPermissions = $ItemPermissions
        ExcludeAccount    = $ExcludeAccount
        ExcludeClass      = $ExcludeClass
        IgnoreDomain      = $IgnoreDomain
        ShortestPath      = $ShortestPath
    }
    Write-LogMsg @LogParams -Text "Get-FolderPermissionsBlock @GetFolderPermissionsBlock"
    $FormattedFolderPermissions = Get-FolderPermissionsBlock @GetFolderPermissionsBlock

    ##Commented the three lines below because actually keeping semicolons means it copy/pastes better into Excel
    ### Convert-ToHtml will not expand in-line HTML
    ### So replace the placeholders (semicolons) with HTML line breaks now, after Convert-ToHtml has already run
    ##$FormattedFolderPermissions.HtmlDiv = $FormattedFolderPermissions.HtmlDiv -replace ' ; ','<br>'

    # Combine the header and table inside a Bootstrap div
    Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText '$FolderTableHeader' -Content `$FormattedFolders.HtmlDiv"
    $HtmlFolderList = New-BootstrapDivWithHeading -HeadingText $FolderTableHeader -Content $FormattedFolders.HtmlDiv
    $JsonFolderList = New-BootstrapDivWithHeading -HeadingText $FolderTableHeader -Content $FormattedFolders.JsonDiv

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

    if ($NoJavaScript) {
        $NoJavaScriptReportFile = $ReportFile -replace 'PermissionsReport', 'PermissionsReport_NoJavaScript'
        $ReportFileList += $NoJavaScriptReportFile
    }

    # Convert the list of generated report files to a Bootstrap list group
    $HtmlListOfReports = $ReportFileList + $ReportFile |
    Split-Path -Leaf |
    ConvertTo-HtmlList |
    ConvertTo-BootstrapListGroup

    # Convert the list of generated log files to a Bootstrap list group
    $HtmlListOfLogs = $LogFileList |
    Split-Path -Leaf |
    ConvertTo-HtmlList |
    ConvertTo-BootstrapListGroup

    # Arrange the lists of generated files in two Bootstrap columns
    $HtmlReportsHeading = New-HtmlHeading -Text 'Reports' -Level 6
    $HtmlLogsHeading = New-HtmlHeading -Text 'Logs' -Level 6
    Write-LogMsg @LogParams -Text "New-BootstrapColumn -Html '`$HtmlReportsHeading`$HtmlListOfReports',`$HtmlLogsHeading`$HtmlListOfLogs"
    $FileListColumns = New-BootstrapColumn -Html "$HtmlReportsHeading$HtmlListOfReports", "$HtmlLogsHeading$HtmlListOfLogs" -Width 6

    # Convert the output directory path to a Boostrap alert
    #$HtmlOutputDir = New-HtmlHeading -Text $OutputDir -Level 6
    $HtmlOutputDir = New-BootstrapAlert -Text $OutputDir -Class 'secondary'

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
        PermissionCount  = $ItemPermissions.Access.Access.Count
        PrincipalCount   = $PrincipalsByResolvedID.Keys.Count
    }
    $ReportFooter = Get-HtmlReportFooter @FooterParams

    # Combine all the elements into a single string which will be the innerHtml of the <body> element of the report
    Write-LogMsg @LogParams -Text "Get-HtmlBody -FolderList `$HtmlFolderList -HtmlFolderPermissions `$FormattedFolderPermissions.HtmlDiv"
    $BodyParams = @{
        FolderList            = $HtmlFolderList
        HtmlFolderPermissions = $FormattedFolderPermissions.HtmlDiv
        HtmlExclusions        = $ExclusionsDiv
        HtmlFileList          = $FileList
        ReportFooter          = $ReportFooter
    }
    [string]$Body = Get-HtmlBody @BodyParams

    # Apply the report template to the generated HTML report body and description
    $ReportParameters = @{
        Title       = $Title
        Description = $ReportDescription
        Body        = $Body
    }
    Write-LogMsg @LogParams -Text "New-BootstrapReport @ReportParameters"
    $Report = New-BootstrapReport @ReportParameters

    if ($NoJavaScript) {
        # Save the Html report
        $null = Set-Content -LiteralPath $NoJavaScriptReportFile -Value $Report

        # Output the name of the report file to the Information stream
        Write-Information $NoJavaScriptReportFile
    }


    Write-LogMsg @LogParams -Text "Get-HtmlBody -FolderList `$JsonFolderList -HtmlFolderPermissions `$FormattedFolderPermissions.JsonDiv"
    $BodyParams = @{
        FolderList            = $JsonFolderList
        HtmlFolderPermissions = $FormattedFolderPermissions.JsonDiv
        HtmlExclusions        = $ExclusionsDiv
        HtmlFileList          = $FileList
        ReportFooter          = $ReportFooter
    }
    [string]$Body = Get-HtmlBody @BodyParams

    $ScriptHtmlBuilder = [System.Text.StringBuilder]::new()

    ForEach ($Folder in $FormattedFolderPermissions) {
        $null = $ScriptHtmlBuilder.AppendLine((ConvertTo-BootstrapTableScript -TableId "#$($Folder.JsonTable)" -ColumnJson $Folder.JsonColumns -DataJson $Folder.JsonData))
    }

    $null = $ScriptHtmlBuilder.AppendLine((ConvertTo-BootstrapTableScript -TableId '#Folders' -ColumnJson $FormattedFolders.JsonColumns -DataJson $FormattedFolders.JsonData))
    $ScriptHtml = $ScriptHtmlBuilder.ToString()

    # Apply the report template to the generated HTML report body and description
    $ReportParameters = @{
        Title                = $Title
        Description          = $ReportDescription
        Body                 = $Body
        JavaScript           = $true
        AdditionalScriptHtml = $ScriptHtml
    }
    Write-LogMsg @LogParams -Text "New-BootstrapReport @ReportParameters"
    $Report = New-BootstrapReport @ReportParameters

    # Save the Html report
    $null = Set-Content -LiteralPath $ReportFile -Value $Report

    # Output the name of the report file to the Information stream
    Write-Information $ReportFile

}
function Export-RawPermissionCsv {

    # Export permissions to CSV

    param (

        # Permission objects from Get-FolderAccessList to export to CSV
        [Object[]]$Permission,

        # Path to the CSV file to create
        # Will be passed to the LiteralPath parameter of Export-Csv
        [string]$LiteralPath,

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Hostname to use in the log messages and/or output object
        [string]$ThisHostname = (HOSTNAME.EXE),

        # Hostname to use in the log messages and/or output object
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId

    )

    $Progress = @{
        Activity = 'Export-RawPermissionCsv'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $ProgressId = $ProgressParentId + 1
    } else {
        $ProgressId = 0
    }
    $Progress['Id'] = $ProgressId
    $ChildProgress = @{
        Activity = 'Flatten the raw access control entries for CSV export'
        Id       = $ProgressId + 1
        ParentId = $ProgressId
    }

    Write-Progress @Progress -Status '0% (step 1 of 2)' -CurrentOperation 'Flattening the raw access control entries for CSV export' -PercentComplete 0

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    Write-LogMsg @LogParams -Text "`$Formatted = ForEach (`$Obj in $`Permissions) {`[PSCustomObject]@{Path=`$Obj.SourceAccessList.Path;IdentityReference=`$Obj.IdentityReference;AccessControlType=`$Obj.AccessControlType;FileSystemRights=`$Obj.FileSystemRights;IsInherited=`$Obj.IsInherited;PropagationFlags=`$Obj.PropagationFlags;InheritanceFlags=`$Obj.InheritanceFlags;Source=`$Obj.Source}"

    # Prepare to show the progress bar, but no more often than every 1%
    $Count = $Permission.Count
    [int]$ProgressInterval = [math]::max(($Count / 100), 1)
    $IntervalCounter = 0
    $i = 0

    # 'Flatten the access control entries for CSV export'
    $Formatted = ForEach ($Obj in $Permission) {

        $IntervalCounter = 0

        if ($IntervalCounter -eq $ProgressInterval) {

            [int]$PercentComplete = $i / $Count * 100
            Write-Progress @ChildProgress -Status "$PercentComplete% (access control entry $($i + 1) of $Count)" -CurrentOperation "'$($Obj.IdentityReference)' on '$($Obj.SourceAccessList.Path)'" -PercentComplete $PercentComplete
            $IntervalCounter = 0

        }

        $i++ # increment $i after the progress to show progress conservatively rather than optimistically

        [PSCustomObject]@{
            Path              = $Obj.SourceAccessList.Path
            IdentityReference = $Obj.IdentityReference
            AccessControlType = $Obj.AccessControlType
            FileSystemRights  = $Obj.FileSystemRights
            IsInherited       = $Obj.IsInherited
            PropagationFlags  = $Obj.PropagationFlags
            InheritanceFlags  = $Obj.InheritanceFlags
            Source            = $Obj.Source
        }

    }

        Write-Progress @ChildProgress -Completed
        Write-Progress @Progress -Status '50% (step 2 of 2)' -CurrentOperation "Saving '$LiteralPath'" -PercentComplete 50
        Write-LogMsg @LogParams -Text "`$Formatted | Export-Csv -NoTypeInformation -LiteralPath '$LiteralPath'"

    $Formatted |
    Export-Csv -NoTypeInformation -LiteralPath $LiteralPath

    Write-Information $LiteralPath
    Write-Progress @Progress -Completed

}
function Export-ResolvedPermissionCsv {

    param (

        # Permission objects from Get-FolderAccessList to export to CSV
        [Object[]]$Permission,

        # Path to the CSV file to create
        # Will be passed to the LiteralPath parameter of Export-Csv
        [string]$LiteralPath,

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Hostname to use in the log messages and/or output object
        [string]$ThisHostname = (HOSTNAME.EXE),

        # Hostname to use in the log messages and/or output object
        [string]$WhoAmI = (whoami.EXE),

        [hashtable]$LogMsgCache = $Global:LogMessages,

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId

    )

    $Progress = @{
        Activity = 'Export-RawPermissionCsv'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    Write-LogMsg @LogParams -Text "`$PermissionsWithResolvedIdentityReferences | `Select-Object -Property @{ Label = 'Path'; Expression = { `$_.SourceAccessList.Path } }, * | Export-Csv -NoTypeInformation -LiteralPath '$LiteralPath'"
    Write-Progress @Progress -Status '0% (step 1 of 1)' -CurrentOperation "Export-Csv '$LiteralPath'" -PercentComplete 50

    $Permission |
    Select-Object -Property @{
        Label      = 'Path'
        Expression = { $_.SourceAccessList.Path }
    }, * |
    Export-Csv -NoTypeInformation -LiteralPath $LiteralPath

    Write-Progress @Progress -Completed
        Write-Information $LiteralPath

}
function Format-FolderPermission {

    <#
     Format the objects

     * SchemaClassName
     * Name,Dept,Title (TODO: Param to work with any specified props)
     * InheritanceFlags
     * Access Rights
    #>

    Param (

        # Expects ACEs grouped using Group-Object
        $UserPermission,

        # Ignore these FileSystemRights
        [string[]]$FileSystemRightsToIgnore = @('Synchronize'),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId

    )

    $Progress = @{
        Activity = 'Format-FolderPermission'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }

    $Count = ($UserPermission | Measure-Object).Count
    Write-Progress @Progress -Status "0% (item 0 of $Count)" -CurrentOperation 'Initializing' -PercentComplete 0
    $i = 0
    $IntervalCounter = 0
    [int]$ProgressInterval = [math]::max(($Count / 100), 1)

    ForEach ($ThisUser in $UserPermission) {

        $IntervalCounter++

        if ($IntervalCounter -eq $ProgressInterval) {

            [int]$PercentComplete = $i / $Count * 100
            Write-Progress @Progress -Status "$PercentComplete% (item $($i+1) of $Count)" -CurrentOperation "Formatting user permission group $($ThisUser.Name)" -PercentComplete $PercentComplete
            $IntervalCounter = 0

        }

        $i++

        if ($ThisUser.Group.DirectoryEntry.Properties) {

            if (

                (
                    $ThisUser.Group.DirectoryEntry |
                    ForEach-Object {
                        if ($null -ne $_) {
                            $_.GetType().FullName 2>$null
                        }
                    }
                ) -contains 'System.Management.Automation.PSCustomObject'

            ) {

                $Names = $ThisUser.Group.DirectoryEntry.Properties.Name
                $Depts = $ThisUser.Group.DirectoryEntry.Properties.Department
                $Titles = $ThisUser.Group.DirectoryEntry.Properties.Title

            } else {

                $Names = $ThisUser.Group.DirectoryEntry |
                ForEach-Object {
                    if ($_.Properties) {
                        $_.Properties['name']
                    }
                }

                $Depts = $ThisUser.Group.DirectoryEntry |
                ForEach-Object {
                    if ($_.Properties) {
                        $_.Properties['department']
                    }
                }

                $Titles = $ThisUser.Group.DirectoryEntry |
                ForEach-Object {
                    if ($_.Properties) {
                        $_.Properties['title']
                    }
                }

                if ($ThisUser.Group.DirectoryEntry.Properties['objectclass'] -contains 'group' -or
                    "$($ThisUser.Group.DirectoryEntry.Properties['groupType'])" -ne ''
                ) {
                    $SchemaClassName = 'group'
                } else {
                    $SchemaClassName = 'user'
                }

            }

            $Name = @($Names)[0]
            $Dept = @($Depts)[0]
            $Title = @($Titles)[0]

        } else {

            $Name = @($ThisUser.Group.name)[0]
            $Dept = @($ThisUser.Group.department)[0]
            $Title = @($ThisUser.Group.title)[0]

            if ($ThisUser.Group.Properties) {

                if (
                    $ThisUser.Group.Properties['objectclass'] -contains 'group' -or
                    "$($ThisUser.Group.Properties['groupType'])" -ne ''
                ) {
                    $SchemaClassName = 'group'
                } else {
                    $SchemaClassName = 'user'
                }

            } else {

                if ($ThisUser.Group.DirectoryEntry.SchemaClassName) {
                    $SchemaClassName = @($ThisUser.Group.DirectoryEntry.SchemaClassName)[0]
                } else {
                    $SchemaClassName = @($ThisUser.Group.SchemaClassName)[0]
                }

            }

        }

        if ("$Name" -eq '') {
            $Name = $ThisUser.Name
        }

        ForEach ($ThisACE in $ThisUser.Group) {

            switch ($ThisACE.ACEInheritanceFlags) {
                'ContainerInherit, ObjectInherit' { $Scope = 'this folder, subfolders, and files' }
                'ContainerInherit' { $Scope = 'this folder and subfolders' }
                'ObjectInherit' { $Scope = 'this folder and files, but not subfolders' }
                default { $Scope = 'this folder but not subfolders' }
            }

            if ($null -eq $ThisUser.Group.IdentityReference) {
                $IdentityReference = $null
            } else {
                $IdentityReference = $ThisACE.ACEIdentityReferenceResolved
            }

            $FileSystemRights = $ThisACE.ACEFileSystemRights
            ForEach ($Ignore in $FileSystemRightsToIgnore) {
                $FileSystemRights = $FileSystemRights -replace ", $Ignore\Z", '' -replace "$Ignore,", ''
            }

            [pscustomobject]@{
                Folder                   = $ThisACE.ACESourceAccessList.Path
                FolderInheritanceEnabled = !($ThisACE.ACESourceAccessList.AreAccessRulesProtected)
                Access                   = "$($ThisACE.ACEAccessControlType) $FileSystemRights $Scope"
                Account                  = $ThisUser.Name
                Name                     = $Name
                Department               = $Dept
                Title                    = $Title
                IdentityReference        = $IdentityReference
                AccessControlEntry       = $ThisACE
                SchemaClassName          = $SchemaClassName
                PSTypeName               = 'Permission.PassThruPermission'
            }

        }

    }

    Write-Progress @Progress -Completed

}
function Format-TimeSpan {
    param (
        [timespan]$TimeSpan,
        [string[]]$UnitsToResolve = @('day', 'hour', 'minute', 'second', 'millisecond')
    )
    $StringBuilder = [System.Text.StringBuilder]::new()
    $aUnitWithAValueHasBeenFound = $false
    foreach ($Unit in $UnitsToResolve) {
        if ($TimeSpan."$Unit`s") {
            if ($aUnitWithAValueHasBeenFound) {
                $null = $StringBuilder.Append(", ")
            }
            $aUnitWithAValueHasBeenFound = $true

            if ($TimeSpan."$Unit`s" -eq 1) {
                $null = $StringBuilder.Append("$($TimeSpan."$Unit`s") $Unit")
            } else {
                $null = $StringBuilder.Append("$($TimeSpan."$Unit`s") $Unit`s")
            }
        }
    }
    $StringBuilder.ToString()
}
function Get-CachedCimInstance {

    param (

        # Name of the computer to query via CIM
        [string]$ComputerName,

        # Name of the CIM class whose instances to return
        [string]$ClassName,

        # CIM query to run. Overrides ClassName if used (but not efficiently, so don't use both)
        [string]$Query,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        [Parameter(Mandatory)]
        [string]$KeyProperty

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    if ($PSBoundParameters.ContainsKey('ClassName')) {
        $CacheKey = $ClassName
    }

    if ($PSBoundParameters.ContainsKey('Query')) {
        $CacheKey = $Query
    }

    $CimCacheResult = $CimCache[$ComputerName]

    if ($CimCacheResult) {

        Write-LogMsg @LogParams -Text " # CIM cache hit for '$ComputerName'"
        $CimCacheSubresult = $CimCacheResult[$CacheKey]

        if ($CimCacheSubresult) {
            Write-LogMsg @LogParams -Text " # CIM instance cache hit for '$CacheKey' on '$ComputerName'"
            return $CimCacheSubresult.Values
        } else {
            Write-LogMsg @LogParams -Text " # CIM instance cache miss for '$CacheKey' on '$ComputerName'"
        }

    } else {
        Write-LogMsg @LogParams -Text " # CIM cache miss for '$ComputerName'"
    }

    $CimSession = Get-CachedCimSession -ComputerName $ComputerName -CimCache $CimCache -ThisFqdn $ThisFqdn @LogParams

    if ($CimSession) {

        if ($PSBoundParameters.ContainsKey('ClassName')) {
            Write-LogMsg @LogParams -Text "Get-CimInstance -ClassName $ClassName -CimSession `$CimSession"
            $CimInstance = Get-CimInstance -ClassName $ClassName -CimSession $CimSession -ErrorAction SilentlyContinue
        }

        if ($PSBoundParameters.ContainsKey('Query')) {
            Write-LogMsg @LogParams -Text "Get-CimInstance -Query '$Query' -CimSession `$CimSession"
            $CimInstance = Get-CimInstance -Query $Query -CimSession $CimSession -ErrorAction SilentlyContinue
        }

        $InstanceCache = @{}

        ForEach ($Instance in $CimInstance) {
            $InstanceCache[$Instance.$KeyProperty] = $Instance
        }

        if ($CimInstance) {
            $CimCache[$ComputerName][$CacheKey] = $InstanceCache
            return $CimInstance.Values
        }

    }

}
function Get-CachedCimSession {

    param (

        # Name of the computer to query via CIM
        [string]$ComputerName,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages
    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    $CimCacheResult = $CimCache[$ComputerName]

    if ($CimCacheResult) {

        Write-LogMsg @LogParams -Text " # CIM cache hit for '$ComputerName'"
        $CimCacheSubresult = $CimCacheResult['CimSession']

        if ($CimCacheSubresult) {
            Write-LogMsg @LogParams -Text " # CIM session cache hit for '$ComputerName'"
            return $CimCacheSubresult
        } else {
            Write-LogMsg @LogParams -Text " # CIM session cache miss for '$ComputerName'"
        }

    } else {

        Write-LogMsg @LogParams -Text " # CIM cache miss for '$ComputerName'"
        $CimCache[$ComputerName] = [hashtable]::Synchronized(@{})

    }

    if (
        $ComputerName -eq $ThisHostname -or
        $ComputerName -eq "$ThisHostname." -or
        $ComputerName -eq $ThisFqdn -or
        $ComputerName -eq "$ThisFqdn." -or
        $ComputerName -eq 'localhost' -or
        $ComputerName -eq '127.0.0.1' -or
        [string]::IsNullOrEmpty($ComputerName)
    ) {
        Write-LogMsg @LogParams -Text '$CimSession = New-CimSession'
        $CimSession = New-CimSession
    } else {
        # If an Active Directory domain is targeted there are no local accounts and CIM connectivity is not expected
        # Suppress errors and return nothing in that case
        Write-LogMsg @LogParams -Text "`$CimSession = New-CimSession -ComputerName $ComputerName"
        $CimSession = New-CimSession -ComputerName $ComputerName -ErrorAction SilentlyContinue
    }

    if ($CimSession) {
        $CimCache[$ComputerName]['CimSession'] = $CimSession
        return $CimSession
    }

}
function Get-FolderAcl {

    # Get folder access control lists
    # Returns an object representing each effective permission on a folder
    # This includes each Access Control Entry in the Discretionary Access List, as well as the folder's Owner

    param (

        # Path to the item whose permissions to export (inherited ACEs will be included)
        $Folder,

        # Path to the subfolders whose permissions to report (inherited ACEs will be skipped)
        $Subfolder,

        # Number of asynchronous threads to use
        [uint16]$ThreadCount = ((Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum),

        # Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module
        [string]$DebugOutputStream = 'Debug',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$TodaysHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # Thread-safe cache of items and their owners
        [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]$OwnerCache = [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]::new(),

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId,

        # Cache of access control lists keyed by path
        [hashtable]$ACLsByPath = [hashtable]::Synchronized(@{})

    )

    $Progress = @{
        Activity = 'Get-FolderAcl'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $ProgressId = $ProgressParentId + 1
    } else {
        $ProgressId = 0
    }
    $Progress['Id'] = $ProgressId
    $ChildProgress = @{
        Activity = 'Get folder access control lists'
        Id       = $ProgressId + 1
        ParentId = $ProgressId
    }

    Write-Progress @Progress -Status '0% (step 1 of 2)' -CurrentOperation 'Get parent folder access control lists' -PercentComplete 0

    $GetDirectorySecurity = @{
        LogMsgCache       = $LogMsgCache
        ThisHostname      = $TodaysHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
        OwnerCache        = $OwnerCache
        ACLsByPath        = $ACLsByPath
    }

    # We expect a small number of folders and a large number of subfolders
    # We will multithread the subfolders but not the folders
    # Multithreading overhead actually hurts performance for such a fast operation (Get-FolderAcl) on a small number of items
    $i = 0
    $Count = $Folder.Count

    ForEach ($ThisFolder in $Folder) {

        [int]$PercentComplete = $i / $Count * 100
        Write-Progress @ChildProgress -Status "$PercentComplete% (parent $($i + 1) of $Count) Get-DirectorySecurity -IncludeInherited" -CurrentOperation $ThisFolder -PercentComplete $PercentComplete
        $i++
        Get-DirectorySecurity -LiteralPath $ThisFolder -IncludeInherited @GetDirectorySecurity

    }

    Write-Progress @ChildProgress -Completed
    $ChildProgress['Activity'] = 'Get-FolderAcl (subfolders)'
    Write-Progress @Progress -Status '25% (step 2 of 4)' -CurrentOperation 'Get subfolder access control lists' -PercentComplete 25
    $SubfolderCount = $Subfolder.Count

    if ($ThreadCount -eq 1) {

        Write-Progress @ChildProgress -Status "0% (subfolder 0 of $SubfolderCount)" -CurrentOperation 'Initializing' -PercentComplete 0
        [int]$ProgressInterval = [math]::max(($SubfolderCount / 100), 1)
        $IntervalCounter = 0
        $i = 0

        ForEach ($ThisFolder in $Subfolder) {

            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {

                [int]$PercentComplete = $i / $SubfolderCount * 100
                Write-Progress @ChildProgress -Status "$PercentComplete% (subfolder $($i + 1) of $SubfolderCount) Get-DirectorySecurity" -CurrentOperation $ThisFolder -PercentComplete $PercentComplete
                $IntervalCounter = 0

            }

            $i++ # increment $i after the progress to show progress conservatively rather than optimistically
            Get-DirectorySecurity -LiteralPath $ThisFolder @GetDirectorySecurity

        }

        Write-Progress @ChildProgress -Completed

    } else {

        $SplitThread = @{
            Command           = 'Get-DirectorySecurity'
            InputObject       = $Subfolder
            InputParameter    = 'LiteralPath'
            DebugOutputStream = $DebugOutputStream
            TodaysHostname    = $TodaysHostname
            WhoAmI            = $WhoAmI
            LogMsgCache       = $LogMsgCache
            Threads           = $ThreadCount
            AddParam          = $GetDirectorySecurity

        }

        Split-Thread @SplitThread

    }

    # Update the cache with ACEs for the item owners (if they do not match the owner of the item's parent folder)
    # First return the owner of the parent item
    Write-Progress @Progress -Status '50% (step 3 of 4) Get-OwnerAce (parent folders)' -CurrentOperation 'Get parent folder owners' -PercentComplete 50
    $ChildProgress['Activity'] = 'Get-FolderAcl (parent owners)'
    $i = 0

    $GetOwnerAce = @{
        OwnerCache = $OwnerCache
        ACLsByPath = $ACLsByPath
    }

    ForEach ($ThisFolder in $Folder) {

        [int]$PercentComplete = $i / $Count * 100
        $i++
        Write-Progress @ChildProgress -Status "$PercentComplete% (parent $i of $Count) Get-OwnerAce" -CurrentOperation $ThisFolder -PercentComplete $PercentComplete
        Get-OwnerAce -Item $ThisFolder @GetOwnerAce

    }

    Write-Progress @ChildProgress -Completed
    Write-Progress @Progress -Status '75% (step 4 of 4) Get-OwnerAce (subfolders)' -CurrentOperation 'Get subfolder owners' -PercentComplete 75
    $ChildProgress['Activity'] = 'Get-FolderAcl (subfolder owners)'

    # Then return the owners of any items that differ from their parents' owners
    if ($ThreadCount -eq 1) {

        $IntervalCounter = 0
        $i = 0

        ForEach ($ThisFolder in $Subfolder) {

            Write-Progress @ChildProgress -Status '0%' -CurrentOperation 'Initializing'
            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {

                [int]$PercentComplete = $i / $SubfolderCount * 100
                Write-Progress @ChildProgress -Status "$PercentComplete% (subfolder $($i + 1) of $SubfolderCount)) Get-OwnerAce" -CurrentOperation $ThisFolder -PercentComplete $PercentComplete
                $IntervalCounter = 0

            }

            $i++
            Get-OwnerAce -Item $ThisFolder @GetOwnerAce

        }

        Write-Progress @ChildProgress -Completed

    } else {

        $SplitThread = @{
            Command           = 'Get-OwnerAce'
            InputObject       = $Subfolder
            InputParameter    = 'Item'
            DebugOutputStream = $DebugOutputStream
            TodaysHostname    = $TodaysHostname
            WhoAmI            = $WhoAmI
            LogMsgCache       = $LogMsgCache
            Threads           = $ThreadCount
            AddParam          = $GetOwnerAce
        }

        Split-Thread @SplitThread

    }

    Write-Progress @Progress -Completed

}
function Get-FolderColumnJson {
    # For the JSON that will be used by JavaScript to generate the table
    param (
        $InputObject,
        [string[]]$PropNames
    )

    if (-not $PSBoundParameters.ContainsKey('PropNames')) {
        $PropNames = ($InputObject | Get-Member -MemberType noteproperty).Name
    }

    $Columns = ForEach ($Prop in $PropNames) {
        $Props = @{
            'field' = $Prop -replace '\s', ''
            'title' = $Prop
        }
        if ($Prop -eq 'Inheritance') {
            $Props['width'] = '1'
        }
        [PSCustomObject]$Props
    }

    $Columns |
    ConvertTo-Json
}
function Get-FolderPermissionsBlock {
    param (

        # Output from Format-FolderPermission in the PsNtfsModule which has already been piped to Group-Object using the Folder property
        $FolderPermissions,

        # Regular expressions matching names of Users or Groups to exclude from the Html report
        [string[]]$ExcludeAccount,

        # Accounts whose objectClass property is in this list are excluded from the HTML report
        [string[]]$ExcludeClass = @('group', 'computer'),

        <#
        Domain(s) to ignore (they will be removed from the username)

        Intended when a user has matching SamAccountNames in multiple domains but you only want them to appear once on the report.

        Can also be used to remove all domains simply for brevity in the report.
        #>
        [string[]]$IgnoreDomain,

        $ShortestPath

    )

    # Convert the $ExcludeClass array into a dictionary for fast lookups
    $ClassExclusions = @{}
    ForEach ($ThisClass in $ExcludeClass) {
        $ClassExclusions[$ThisClass] = $true
    }

    ForEach ($ThisFolder in $FolderPermissions) {

        $ThisHeading = New-HtmlHeading "Accounts with access to $($ThisFolder.Item.Path)" -Level 5

        $ThisSubHeading = Get-FolderPermissionTableHeader -ThisFolder $ThisFolder -ShortestFolderPath $ShortestPath

        #$FilterContents = @{}

        $FilteredPermissions = $ThisFolder.Access |
        Where-Object -FilterScript {

            # On built-in groups like 'Authenticated Users' or 'Administrators' the SchemaClassName is null but we have an ObjectType instead.
            # TODO: Research where this difference came from, should these be normalized earlier in the process?
            # A user who was found by being a member of a local group not have an ObjectType (because they are not directly part of the AccessControlEntry)
            # They should have their parent group's AccessControlEntry there...do they?  Doesn't it have a Group ObjectType there?

            ###if ($_.Group.AccessControlEntry.ObjectType) {
            ###    $Schema = @($_.Group.AccessControlEntry.ObjectType)[0]
            ###    $Schema = @($_.Group.SchemaClassName)[0]
            # ToDo: SchemaClassName is a real property but may not exist on all objects.  ObjectType is my own property.  Need to verify+test all usage of both for accuracy.
            # ToDo: Why is $_.Group.SchemaClassName 'user' for the local Administrators group and Authenticated Users group, and it is 'Group' for the TestPC\Owner user?
            ###}

            # Exclude the object whose classes were specified in the parameters
            $SchemaExclusionResult = if ($ExcludeClass.Count -gt 0) {
                ###$ClassExclusions[$Schema]
                $ClassExclusions[$_.Account.SchemaClassName]
            }
            -not $SchemaExclusionResult -and

            # Exclude the objects whose names match the regular expressions specified in the parameters
            ![bool]$(
                ForEach ($RegEx in $ExcludeAccount) {
                    if ($_.Account.ResolvedAccountName -match $RegEx) {
                        #$FilterContents[$_.Account.ResolvedAccountName] += $_ #TODO: IMPLEMENT IN FUTURE WITH HASHTABLE, NOT += which is demonstrative only for now
                        $true
                    }
                }
            )

        }

        # Bugfix #48 https://github.com/IMJLA/Export-Permission/issues/48
        # Sending a dummy object down the line to avoid errors
        # TODO: More elegant solution needed. Downstream code should be able to handle null input.
        # TODO: Why does this suppress errors, but the object never appears in the tables? NOTE: Suspect this is now resolved by using -AsArray on ConvertTo-Json (lack of this was causing single objects to not be an array therefore not be displayed)
        if ($null -eq $FilteredPermissions) {
            $FilteredPermissions = [pscustomobject]@{
                'Account' = 'NoAccountsMatchingCriteria'
                'Access'  = [pscustomobject]@{
                    'IdentityReferenceResolved' = '.'
                    'FileSystemRights'          = '.'
                    'SourceOfAccess'            = '.'
                    'Name'                      = '.'
                    'Department'                = '.'
                    'Title'                     = '.'
                }
            }
        }

        $ObjectsForFolderPermissionTable = Select-FolderPermissionTableProperty -InputObject $FilteredPermissions -IgnoreDomain $IgnoreDomain |
        Sort-Object -Property Account

        $ThisTable = $ObjectsForFolderPermissionTable |
        ConvertTo-Html -Fragment |
        New-BootstrapTable

        $TableId = "Perms_$($ThisFolder.Item.Path -replace '[^A-Za-z0-9\-_]', '-')"

        $ThisJsonTable = ConvertTo-BootstrapJavaScriptTable -Id $TableId -InputObject $ObjectsForFolderPermissionTable -DataFilterControl -AllColumnsSearchable

        # Remove spaces from property titles
        $ObjectsForJsonData = ForEach ($Obj in $ObjectsForFolderPermissionTable) {
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

        [pscustomobject]@{
            HtmlDiv     = New-BootstrapDiv -Text ($ThisHeading + $ThisSubHeading + $ThisTable)
            JsonDiv     = New-BootstrapDiv -Text ($ThisHeading + $ThisSubHeading + $ThisJsonTable)
            JsonColumns = Get-FolderColumnJson -InputObject $ObjectsForFolderPermissionTable -PropNames Account, Access,
            'Due to Membership In', 'Source of Access', Name, Department, Title
            #JsonData    = $ObjectsForJsonData | ConvertTo-Json -AsArray # requires PS6+ , unknown if any performance benefit compared to wrapping in @()
            JsonData    = ConvertTo-Json -InputObject @($ObjectsForJsonData)
            JsonTable   = $TableId
            Path        = $ThisFolder.Item.Path
        }
    }
}
function Get-FolderPermissionTableHeader {
    [OutputType([System.String])]
    param (
        $ThisFolder,
        [string]$ShortestFolderPath
    )
    $Leaf = $ThisFolder.Item.Path | Split-Path -Parent | Split-Path -Leaf -ErrorAction SilentlyContinue
    if ($Leaf) {
        $ParentLeaf = $Leaf
    } else {
        $ParentLeaf = $ThisFolder.Item.Path | Split-Path -Parent
    }
    if ('' -ne $ParentLeaf) {
        if ($InputObject.Item.AreAccessRulesProtected) {
            return "Inheritance is disabled on this folder. Accounts with access to the parent folder and subfolders ($ParentLeaf) cannot access this folder unless they are listed below:"
        } else {
            if ($ThisFolder.Item.Path -eq $ShortestFolderPath) {
                return "Inherited permissions from the parent folder ($ParentLeaf) are included. This folder can only be accessed by the accounts listed below:"
            } else {
                return "Inheritance is enabled on this folder. Accounts with access to the parent folder and subfolders ($ParentLeaf) can access this folder. So can any accounts listed below:"
            }
        }
    } else {
        return "This is the top-level folder. It can only be accessed by the accounts listed below:"
    }
}
function Get-FolderTableHeader {
    param ($RecurseDepth)

    switch ($RecurseDepth ) {
        0 {
            'Includes the target folder only (option to report on subfolders was declined)'
        }
        -1 {
            'Includes the target folder and all subfolders with unique permissions'
        }
        default {
            "Includes the target folder and $RecurseDepth levels of subfolders with unique permissions"
        }
    }
}
function Get-HtmlBody {
    param (
        $FolderList,
        $HtmlFolderPermissions,
        $ReportFooter,
        $HtmlFileList,
        $LogDir,
        $HtmlExclusions
    )
    $StringBuilder = [System.Text.StringBuilder]::new()
    $null = $StringBuilder.Append((New-HtmlHeading "Folders with Permissions in This Report" -Level 3))
    $null = $StringBuilder.Append($FolderList)
    $null = $StringBuilder.Append((New-HtmlHeading "Accounts Included in Those Permissions" -Level 3))
    $HtmlFolderPermissions |
    ForEach-Object {
        $null = $StringBuilder.Append($_)
    }
    if ($HtmlExclusions) {
        $null = $StringBuilder.Append((New-HtmlHeading "Exclusions from This Report" -Level 3))
        $null = $StringBuilder.Append($HtmlExclusions)
    }
    $null = $StringBuilder.Append((New-HtmlHeading "Files Generated" -Level 3))
    $null = $StringBuilder.Append($HtmlFileList)
    $null = $StringBuilder.Append($ReportFooter)
    $StringBuilder.ToString()
}
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

        [UInt64]$PrincipalCount

    )
    $null = $StopWatch.Stop()
    $FinishTime = Get-Date
    $StartTime = $FinishTime.AddTicks(-$StopWatch.ElapsedTicks)
    $TimeZoneName = Get-TimeZoneName -Time $FinishTime
    $Duration = Format-TimeSpan -TimeSpan $StopWatch.Elapsed
    if ($TotalBytes) {
        $Size = " ($($TotalBytes / 1TB) TiB"
    }
    $Text = @"
Report generated by $WhoAmI on $ThisFQDN starting at $StartTime and ending at $FinishTime $TimeZoneName<br />
Processed $PermissionCount permissions for $PrincipalCount users on $ItemCount items$Size in $Duration<br />
Report instance: $ReportInstanceId
"@
    New-BootstrapAlert -Class Light -Text $Text
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
function Get-Permission {

  # Get detailed info about permissions and the accounts with them

  <#
    Get-FolderAccessList
      Get-FolderAce
    Resolve-AccessList (foreach AccessControlEntry)
      Resolve-PermissionIdentity
        Resolve-Ace
          Resolve-IdentityReference
      Get-PermissionPrincipal
        ConvertFrom-IdentityReferenceResolved
      Format-PermissionAccount
        Format-SecurityPrincipal
      Select-UniqueAccountPermission
      Format-FolderPermission
    #>

  param (

    # Path to the item whose permissions to export (inherited ACEs will be included)
    $Folder,

    # Path to the subfolders whose permissions to report (inherited ACEs will be skipped)
    $Subfolder,

    # Number of asynchronous threads to use
    [uint16]$ThreadCount = ((Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum),

    # Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module
    [string]$DebugOutputStream = 'Debug',

    # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
    [string]$ThisHostname = (HOSTNAME.EXE),

    <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
    [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

    # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
    [string]$WhoAmI = (whoami.EXE),

    # Cache of CIM sessions and instances to reduce connections and queries
    [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

    # Cache of known Win32_Account instances keyed by domain and SID
    [hashtable]$Win32AccountsBySID = ([hashtable]::Synchronized(@{})),

    # Cache of known Win32_Account instances keyed by domain (e.g. CONTOSO) and Caption (NTAccount name e.g. CONTOSO\User1)
    [hashtable]$Win32AccountsByCaption = ([hashtable]::Synchronized(@{})),

    <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
    [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

    # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
    [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

    # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
    [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

    # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName,AdsiProvider,Win32Accounts properties as values
    [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

    # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
    [hashtable]$LogMsgCache = $Global:LogMessages,

    # Thread-safe cache of items and their owners
    [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]$OwnerCache = [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]::new(),

    # ID of the parent progress bar under which to show progres
    [int]$ProgressParentId,

    [string[]]$KnownFqdn,

    # String translations indexed by value in the [System.Security.AccessControl.InheritanceFlags] enum
    # Parameter default value is on a single line as a workaround to a PlatyPS bug
    [string[]]$InheritanceFlagResolved = @('this folder but not subfolders', 'this folder and subfolders', 'this folder and files, but not subfolders', 'this folder, subfolders, and files')

  )

  # Create a splat of the progress parameters for code readability
  $Progress = @{
    Activity = 'Get-Permission'
  }
  if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
    $Progress['ParentId'] = $ProgressParentId
    $ProgressId = $ProgressParentId + 1
  } else {
    $ProgressId = 0
  }
  $Progress['Id'] = $ProgressId

  # Start the progress bar for this function
  Write-Progress -Status '0% (step 1 of 4)' -CurrentOperation 'Initialize' -PercentComplete 0 @Progress

  # Create a splat of the child progress bar ID to pass to various functions for code readability
  $ChildProgress = @{
    ProgressParentId = $ProgressId
  }

  # Create a splat of the ThreadCount parameter to pass to various functions for code readability
  $Threads = @{
    ThreadCount = $ThreadCount
  }

  # Create a splat of log-related parameters to pass to various functions for code readability
  $LoggingParams = @{
    ThisHostname = $ThisHostname
    LogMsgCache  = $LogCache
    WhoAmI       = $WhoAmI
  }

  # Create a splat of caching-related parameters to pass to various functions for code readability
  $CacheParams = @{
    Win32AccountsBySID     = $Win32AccountsBySID
    Win32AccountsByCaption = $Win32AccountsByCaption
    DirectoryEntryCache    = $DirectoryEntryCache
    DomainsByFqdn          = $DomainsByFqdn
    DomainsByNetbios       = $DomainsByNetbios
    DomainsBySid           = $DomainsBySid
    ThisFqdn               = $ThisFqdn
    ThreadCount            = $ThreadCount
  }

  Write-Progress -Status '25% (step 2 of 4)' -CurrentOperation 'Get folder access control lists' -PercentComplete 15 @Progress
  Write-LogMsg @LogParams -Text "`$AccessLists = Get-FolderAccessList -Folder @('$($Folder -join "','")') -Subfolder @('$($Subfolder -join "','")')"
  $AccessLists = Get-FolderAccessList -Folder $Folder -Subfolder $Subfolder @Threads @ChildProgress @LoggingParams

  # Without this step, threads that start simulataneously would all find the cache empty and would all perform queries to populate it
  Write-Progress -Status '50% (step 3 of 4)' -CurrentOperation 'Pre-populate caches in memory to avoid redundant ADSI and CIM queries' -PercentComplete 30 @Progress
  Write-LogMsg @LogParams -Text "Initialize-Cache -Fqdn @('$($KnownFqdn -join "',")')"
  Initialize-Cache -Fqdn $KnownFqdn -CimCache $CimCache @ProgressParent @LoggingParams @CacheParams

  Write-Progress -Status '75% (step 4 of 4)' -CurrentOperation 'Resolve and expand the identities in access control lists to the accounts they represent' -PercentComplete 30 @Progress
  Write-LogMsg @LogParams -Text "Resolve-AccessList -AccessList `$AccessLists"
  Resolve-AccessList -AccessList $AccessLists -InheritanceFlagResolved $InheritanceFlagResolved @Threads @ChildProgress @LoggingParams

  Write-Progress @Progress -Completed

}
function Get-PermissionPrincipal {

    param (

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Maximum number of concurrent threads to allow
        [int]$ThreadCount = (Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum,

        # Cache of security principals keyed by resolved identity reference. END STATE
        [hashtable]$PrincipalsByResolvedID = ([hashtable]::Synchronized(@{})),

        # Cache of access control entries keyed by their resolved identities. STARTING STATE
        [hashtable]$ACEsByResolvedID = ([hashtable]::Synchronized(@{})),

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName,AdsiProvider,Win32Accounts properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        # Cache of known Win32_Account instances keyed by domain (e.g. CONTOSO) and Caption (NTAccount name e.g. CONTOSO\User1)
        [hashtable]$Win32AccountsByCaption = ([hashtable]::Synchronized(@{})),

        # Cache of known Win32_Account instances keyed by domain and SID
        [hashtable]$Win32AccountsBySID = ([hashtable]::Synchronized(@{})),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        <#
        Do not get group members (only report the groups themselves)

        Note: By default, the -ExcludeClass parameter will exclude groups from the report.
          If using -NoGroupMembers, you most likely want to modify the value of -ExcludeClass.
          Remove the 'group' class from ExcludeClass in order to see groups on the report.
        #>
        [switch]$NoGroupMembers,

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId,

        # The current domain
        # Can be passed as a parameter to reduce calls to Get-CurrentDomain
        [string]$CurrentDomain = (Get-CurrentDomain)

    )

    $Progress = @{
        Activity = 'Get-PermissionPrincipal'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }

    [string[]]$IDs = $ACEsByResolvedID.Keys
    $Count = $IDs.Count
    Write-Progress @Progress -Status "0% (identity 0 of $Count)" -CurrentOperation 'Initialize' -PercentComplete 0

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $ADSIConversionParams = @{
        DirectoryEntryCache    = $DirectoryEntryCache
        DomainsBySID           = $DomainsBySID
        DomainsByNetbios       = $DomainsByNetbios
        DomainsByFqdn          = $DomainsByFqdn
        ThisHostName           = $ThisHostName
        ThisFqdn               = $ThisFqdn
        WhoAmI                 = $WhoAmI
        LogMsgCache            = $LogMsgCache
        CimCache               = $CimCache
        DebugOutputStream      = $DebugOutputStream
        PrincipalsByResolvedID = $PrincipalsByResolvedID # end state
        ACEsByResolvedID       = $ACEsByResolvedID # start state
        CurrentDomain          = $CurrentDomain
    }

    if ($ThreadCount -eq 1) {

        if ($NoGroupMembers) {
            $ADSIConversionParams['NoGroupMembers'] = $true
        }

        [int]$ProgressInterval = [math]::max(($Count / 100), 1)
        $IntervalCounter = 0
        $i = 0

        ForEach ($ThisID in $IDs) {

            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {

                [int]$PercentComplete = $i / $Count * 100
                Write-Progress @Progress -Status "$PercentComplete% (identity $($i + 1) of $Count) ConvertFrom-IdentityReferenceResolved" -CurrentOperation $ThisID -PercentComplete $PercentComplete
                $IntervalCounter = 0

            }

            $i++
            Write-LogMsg @LogParams -Text "ConvertFrom-IdentityReferenceResolved -IdentityReference '$ThisID'"
            ConvertFrom-IdentityReferenceResolved -IdentityReference $ThisID @ADSIConversionParams

        }

    } else {

        if ($NoGroupMembers) {
            $ADSIConversionParams['AddSwitch'] = 'NoGroupMembers'
        }

        $SplitThreadParams = @{
            Command              = 'ConvertFrom-IdentityReferenceResolved'
            InputObject          = $IDs
            InputParameter       = 'IdentityReference'
            ObjectStringProperty = 'Name'
            TodaysHostname       = $ThisHostname
            WhoAmI               = $WhoAmI
            LogMsgCache          = $LogMsgCache
            Threads              = $ThreadCount
            AddParam             = $ADSIConversionParams
        }

        Write-LogMsg @LogParams -Text "Split-Thread -Command 'ConvertFrom-IdentityReferenceResolved' -InputParameter 'IdentityReference' -InputObject `$IDs"
        Split-Thread @SplitThreadParams

    }

    Write-Progress @Progress -Completed

}
function Get-PrtgXmlSensorOutput {
    param (
        $NtfsIssues
    )

    $Channels = [System.Collections.Generic.List[string]]::new()


    # Build our XML output formatted for PRTG.
    $ChannelParams = @{
        MaxError   = 0.5
        Channel    = 'Folders with inheritance disabled'
        Value      = ($NtfsIssues.FoldersWithBrokenInheritance | Measure-Object).Count
        CustomUnit = 'folders'
    }
    Format-PrtgXmlResult @ChannelParams |
    ForEach-Object { $null = $Channels.Add($_) }

    $ChannelParams = @{
        MaxError   = 0.5
        Channel    = 'ACEs for groups breaking naming convention'
        Value      = ($NtfsIssues.NonCompliantGroups | Measure-Object).Count
        CustomUnit = 'ACEs'
    }
    Format-PrtgXmlResult @ChannelParams |
    ForEach-Object { $null = $Channels.Add($_) }

    $ChannelParams = @{
        MaxError   = 0.5
        Channel    = 'ACEs for users instead of groups'
        Value      = ($NtfsIssues.UserACEs | Measure-Object).Count
        CustomUnit = 'ACEs'
    }
    Format-PrtgXmlResult @ChannelParams |
    ForEach-Object { $null = $Channels.Add($_) }


    $ChannelParams = @{
        MaxError   = 0.5
        Channel    = 'ACEs for unresolvable SIDs'
        Value      = ($NtfsIssues.SIDsToCleanup | Measure-Object).Count
        CustomUnit = 'ACEs'
    }
    Format-PrtgXmlResult @ChannelParams |
    ForEach-Object { $null = $Channels.Add($_) }


    $ChannelParams = @{
        MaxError   = 0.5
        Channel    = "Folders with 'CREATOR OWNER' access"
        Value      = ($NtfsIssues.FoldersWithCreatorOwner | Measure-Object).Count
        CustomUnit = 'folders'
    }
    Format-PrtgXmlResult @ChannelParams |
    ForEach-Object { $null = $Channels.Add($_) }

    Format-PrtgXmlSensorOutput -PrtgXmlResult $Channels -IssueDetected:$($NtfsIssues.IssueDetected)

}
function Get-ReportDescription {
    param ($RecurseDepth)

    switch ($RecurseDepth ) {
        0 {
            'Does not include permissions on subfolders (option was declined)'
        }
        -1 {
            'Includes all subfolders with unique permissions (including ∞ levels of subfolders)'
        }
        default {
            "Includes all subfolders with unique permissions (down to $RecurseDepth levels of subfolders)"
        }
    }
}
function Get-TimeZoneName {
    param (
        [datetime]$Time,
        [Microsoft.Management.Infrastructure.CimInstance]$TimeZone = (Get-CimInstance -ClassName Win32_TimeZone)
    )
    if ($Time.IsDaylightSavingTime()) {
        return $TimeZone.DaylightName
    } else {
        return $TimeZone.StandardName
    }
}

# Build a list of known ADSI server names to use to populate the caches
# Include the FQDN of the current computer and the known trusted domains
function Get-UniqueServerFqdn {

    param (

        # Known server FQDNs to include in the output
        [string[]]$Known,

        # File paths whose server FQDNs to include in the output
        [string[]]$FilePath,

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId

    )

    $Progress = @{
        Activity = 'Get-UniqueServerFqdn'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }
    $Count = $FilePath.Count
    Write-Progress @Progress -Status "0% (path 0 of $Count)" -CurrentOperation 'Initializing' -PercentComplete 0

    $UniqueValues = @{
        $ThisFqdn = $null
    }

    ForEach ($Value in $Known) {
        $UniqueValues[$Value] = $null
    }

    # Add server names from the ACL paths
    [int]$ProgressInterval = [math]::max(($Count / 100), 1)
    $IntervalCounter = 0
    $i = 0

    ForEach ($ThisPath in $FilePath) {
        $IntervalCounter++
        if ($IntervalCounter -eq $ProgressInterval) {
            [int]$PercentComplete = $i / $Count * 100
            Write-Progress @Progress -Status "$PercentComplete% (path $($i + 1) of $Count)" -CurrentOperation "Find-ServerNameInPath '$ThisPath'" -PercentComplete $PercentComplete
            $IntervalCounter = 0
        }
        $i++ # increment $i after Write-Progress to show progress conservatively rather than optimistically
        $UniqueValues[(Find-ServerNameInPath -LiteralPath $ThisPath -ThisFqdn $ThisFqdn)] = $null
    }

    Write-Progress @Progress -Completed

    return $UniqueValues.Keys

}
function Group-Permission {

    param (

        [object[]]$InputObject,

        [string]$Property

    )

    $Cache = @{}

    ForEach ($Permission in $InputObject) {

        $Key = $Permission.$Property
        $CacheResult = $Cache[$Key]
        if (-not $CacheResult) {
            $CacheResult = [System.Collections.Generic.List[object]]::new()
        }
        $CacheResult.Add($Permission)
        $Cache[$Key] = $CacheResult

    }

    ForEach ($Key in $Cache.Keys) {

        $CacheResult = $Cache[$Key]
        [pscustomobject]@{
            PSTypeName = "Permission.$Property`Permission"
            Group      = $CacheResult
            Name       = $Key
            Count      = $CacheResult.Count
        }

    }

}
function Initialize-Cache {

    <#
    Pre-populate caches in memory to avoid redundant ADSI and CIM queries
    Use known ADSI and CIM server FQDNs to populate six caches:
       Three caches of known ADSI directory servers
         The first cache is keyed on domain SID (e.g. S-1-5-2)
         The second cache is keyed on domain FQDN (e.g. ad.contoso.com)
         The first cache is keyed on domain NetBIOS name (e.g. CONTOSO)
       Two caches of known Win32_Account instances
         The first cache is keyed on SID (e.g. S-1-5-2)
         The second cache is keyed on the Caption (NT Account name e.g. CONTOSO\user1)
       Also populate a cache of DirectoryEntry objects for any domains that have them
     This prevents threads that start near the same time from finding the cache empty and attempting costly operations to populate it
     This prevents repetitive queries to the same directory servers
    #>

    param (

        # FQDNs of the ADSI servers to use to populate the cache
        [Parameter(ValueFromPipeline)]
        [string[]]$Fqdn,

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Maximum number of concurrent threads to allow
        [int]$ThreadCount = (Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Cache of known Win32_Account instances keyed by domain and SID
        [hashtable]$Win32AccountsBySID = ([hashtable]::Synchronized(@{})),

        # Cache of known Win32_Account instances keyed by domain (e.g. CONTOSO) and Caption (NTAccount name e.g. CONTOSO\User1)
        [hashtable]$Win32AccountsByCaption = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName,AdsiProvider,Win32Accounts properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId

    )

    $Progress = @{
        Activity = 'Initialize-Cache'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }
    $Count = $ServerFqdns.Count
    Write-Progress -Status "0% (FQDN 0 of $Count)" -CurrentOperation 'Initializing' -PercentComplete 0 @Progress

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $GetAdsiServerParams = @{
        Win32AccountsBySID     = $Win32AccountsBySID
        Win32AccountsByCaption = $Win32AccountsByCaption
        DirectoryEntryCache    = $DirectoryEntryCache
        DomainsByFqdn          = $DomainsByFqdn
        DomainsByNetbios       = $DomainsByNetbios
        DomainsBySid           = $DomainsBySid
        ThisHostName           = $ThisHostName
        ThisFqdn               = $ThisFqdn
        WhoAmI                 = $WhoAmI
        LogMsgCache            = $LogMsgCache
        CimCache               = $CimCache
    }

    if ($ThreadCount -eq 1) {

        [int]$ProgressInterval = [math]::max(($Count / 100), 1)
        $IntervalCounter = 0
        $i = 0

        ForEach ($ThisServerName in $ServerFqdns) {

            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {
                [int]$PercentComplete = $i / $Count * 100
                Write-Progress @Progress -Status "$PercentComplete% (FQDN $($i + 1) of $Count) Get-AdsiServer" -CurrentOperation "Get-AdsiServer '$ThisServerName'" -PercentComplete $PercentComplete
                $IntervalCounter = 0
            }

            $i++ # increment $i after Write-Progress to show progress conservatively rather than optimistically
            Write-LogMsg @LogParams -Text "Get-AdsiServer -Fqdn '$ThisServerName'"
            $null = Get-AdsiServer -Fqdn $ThisServerName @GetAdsiServerParams

        }

    } else {

        $GetAdsiServerParams = @{
            Command        = 'Get-AdsiServer'
            InputObject    = $ServerFqdns
            InputParameter = 'Fqdn'
            TodaysHostname = $ThisHostname
            WhoAmI         = $WhoAmI
            LogMsgCache    = $LogMsgCache
            Timeout        = 600
            Threads        = $ThreadCount
            AddParam       = $GetAdsiServerParams
        }

        Write-LogMsg @LogParams -Text "Split-Thread -Command 'Get-AdsiServer' -InputParameter AdsiServer -InputObject @('$($ServerFqdns -join "',")')"
        $null = Split-Thread @GetAdsiServerParams

    }

    Write-Progress @Progress -Completed

}
function Invoke-PermissionCommand {

    param (

        [string]$Command

    )

    $Steps = [System.Collections.Specialized.OrderedDictionary]::New()
    $Steps.Add(
        'Get the NTAccount caption of the user running the script, with the correct capitalization',
        { HOSTNAME.EXE }
    )
    $Steps.Add(
        'Get the hostname of the computer running the script',
        { Get-CurrentWhoAmI -LogMsgCache $LogMsgCache -ThisHostName $ThisHostname }
    )

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        #Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $StepCount = $Steps.Count
    Write-LogMsg @LogParams -Type Verbose -Text $Command
    $ScriptBlock = $Steps[$Command]
    Write-LogMsg @LogParams -Type Debug -Text $ScriptBlock
    Invoke-Command -ScriptBlock $ScriptBlock

}
function Remove-CachedCimSession {

    param (

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{}))

    )

    ForEach ($CacheResult in $CimCache.Values) {

        if ($CacheResult) {

            $CimSession = $CacheResult['CimSession']

            if ($CimSession) {
                $null = Remove-CimSession -CimSession $CimSession
            }

        }

    }

}
function Resolve-AccessControlList {

    # Wrapper to multithread Resolve-Acl
    # Resolve identities in access control lists to their SIDs and NTAccount names

    param (

        # Cache of access control lists keyed by path
        [hashtable]$ACLsByPath = [hashtable]::Synchronized(@{}),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Maximum number of concurrent threads to allow
        [int]$ThreadCount = (Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum,

        # Cache of access control entries keyed by GUID generated in this function
        [hashtable]$ACEsByGUID = ([hashtable]::Synchronized(@{})),

        # Cache of access control entry GUIDs keyed by their resolved identities
        [hashtable]$AceGUIDsByResolvedID = ([hashtable]::Synchronized(@{})),

        # Cache of access control entry GUIDs keyed by their paths
        [hashtable]$AceGUIDsByPath = ([hashtable]::Synchronized(@{})),

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName,AdsiProvider,Win32Accounts properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Cache of known Win32_Account instances keyed by domain (e.g. CONTOSO) and Caption (NTAccount name e.g. CONTOSO\User1)
        [hashtable]$Win32AccountsByCaption = ([hashtable]::Synchronized(@{})),

        # Cache of known Win32_Account instances keyed by domain and SID
        [hashtable]$Win32AccountsBySID = ([hashtable]::Synchronized(@{})),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId,

        # String translations indexed by value in the [System.Security.AccessControl.InheritanceFlags] enum
        # Parameter default value is on a single line as a workaround to a PlatyPS bug
        [string[]]$InheritanceFlagResolved = @('this folder but not subfolders', 'this folder and subfolders', 'this folder and files, but not subfolders', 'this folder, subfolders, and files')

    )

    $Progress = @{
        Activity = 'Resolve-AccessControlList'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }

    $Paths = $ACLsByPath.Keys
    $Count = $Paths.Count
    Write-Progress @Progress -Status "0% (ACL 0 of $Count)" -CurrentOperation 'Initializing' -PercentComplete 0

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $ACEPropertyName = (Get-Member -InputObject $ACLsByPath.Values.Access[0] -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name

    $ResolveAclParams = @{
        DirectoryEntryCache     = $DirectoryEntryCache
        Win32AccountsBySID      = $Win32AccountsBySID
        Win32AccountsByCaption  = $Win32AccountsByCaption
        DomainsBySID            = $DomainsBySID
        DomainsByNetbios        = $DomainsByNetbios
        DomainsByFqdn           = $DomainsByFqdn
        ThisHostName            = $ThisHostName
        ThisFqdn                = $ThisFqdn
        WhoAmI                  = $WhoAmI
        LogMsgCache             = $LogMsgCache
        CimCache                = $CimCache
        ACEsByGuid              = $ACEsByGUID
        AceGUIDsByPath          = $AceGUIDsByPath
        AceGUIDsByResolvedID    = $AceGUIDsByResolvedID
        ACLsByPath              = $ACLsByPath
        ACEPropertyName         = $ACEPropertyName
        InheritanceFlagResolved = $InheritanceFlagResolved
    }

    if ($ThreadCount -eq 1) {

        [int]$ProgressInterval = [math]::max(($Count / 100), 1)
        $IntervalCounter = 0
        $i = 0

        ForEach ($ThisPath in $Paths) {

            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {

                [int]$PercentComplete = $i / $Count * 100
                Write-Progress @Progress -Status "$PercentComplete% (ACL $($i + 1) of $Count) Resolve-Acl" -CurrentOperation $ThisPath -PercentComplete $PercentComplete
                $IntervalCounter = 0

            }

            $i++ # increment $i after Write-Progress to show progress conservatively rather than optimistically
            Write-LogMsg @LogParams -Text "Resolve-Acl -InputObject '$ThisPath' -ACLsByPath `$ACLsByPath -ACEsByGUID `$ACEsByGUID"
            Resolve-Acl -ItemPath $ThisPath @ResolveAclParams

        }

    } else {

        $SplitThreadParams = @{
            Command        = 'Resolve-Acl'
            InputObject    = $Paths
            InputParameter = 'ItemPath'
            TodaysHostname = $ThisHostname
            WhoAmI         = $WhoAmI
            LogMsgCache    = $LogMsgCache
            Threads        = $ThreadCount
            AddParam       = $ResolveAclParams
            #DebugOutputStream    = 'Debug'
        }

        Write-LogMsg @LogParams -Text "Split-Thread -Command 'Resolve-Acl' -InputParameter InputObject -InputObject @('$($ACLsByPath.Keys -join "','")') -AddParam @{ACLsByPath=`$ACLsByPath;ACEsByGUID=`$ACEsByGUID}"
        Split-Thread @SplitThreadParams

    }

    Write-Progress @Progress -Completed

}
function Resolve-Ace {
    <#
    .SYNOPSIS
    Use ADSI to lookup info about IdentityReferences from Authorization Rule Collections that came from Discretionary Access Control Lists
    .DESCRIPTION
    Based on the IdentityReference proprety of each Access Control Entry:
    Resolve SID to NT account name and vise-versa
    Resolve well-known SIDs
    Resolve generic defaults like 'NT AUTHORITY' and 'BUILTIN' to the applicable computer or domain name
    Add these properties (IdentityReferenceSID,IdentityReferenceResolved) to the object and return it
    .INPUTS
    [System.Security.AccessControl.AuthorizationRuleCollection]$ACE
    .OUTPUTS
    [PSCustomObject] Original object plus IdentityReferenceSID,IdentityReferenceResolved, and AdsiProvider properties
    .EXAMPLE
    Get-Acl |
    Expand-Acl |
    Resolve-Ace

    Use Get-Acl from the Microsoft.PowerShell.Security module as the source of the access list
    This works in either Windows Powershell or in Powershell
    Get-Acl does not support long paths (>256 characters)
    That was why I originally used the .Net Framework method
    .EXAMPLE
    Get-FolderAce -LiteralPath C:\Test -IncludeInherited |
    Resolve-Ace
    .EXAMPLE
    [System.String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor [System.Security.AccessControl.AccessControlSections]::Owner
    $FileSecurity = [System.Security.AccessControl.FileSecurity]::new($DirectoryInfo,$Sections)
    $IncludeExplicitRules = $true
    $IncludeInheritedRules = $true
    $AccountType = [System.Security.Principal.SecurityIdentifier]
    $FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
    Resolve-Ace

    This uses .Net Core as the source of the access list
    It uses the GetAccessRules method on the [System.Security.AccessControl.FileSecurity] class
    The targetType parameter of the method is used to specify that the accounts in the ACL are returned as SIDs
    .EXAMPLE
    [System.String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor
    [System.Security.AccessControl.AccessControlSections]::Owner -bor
    [System.Security.AccessControl.AccessControlSections]::Group
    $DirectorySecurity = [System.Security.AccessControl.DirectorySecurity]::new($DirectoryInfo,$Sections)
    $IncludeExplicitRules = $true
    $IncludeInheritedRules = $true
    $AccountType = [System.Security.Principal.NTAccount]
    $FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
    Resolve-Ace

    This uses .Net Core as the source of the access list
    It uses the GetAccessRules method on the [System.Security.AccessControl.FileSecurity] class
    The targetType parameter of the method is used to specify that the accounts in the ACL are returned as NT account names (DOMAIN\User)
    .EXAMPLE
    [System.String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    [System.Security.AccessControl.DirectorySecurity]$DirectorySecurity = $DirectoryInfo.GetAccessControl('Access')
    [System.Security.AccessControl.AuthorizationRuleCollection]$AuthRules = $DirectorySecurity.Access
    $AuthRules | Resolve-Ace

    Use the .Net Framework (or legacy .Net Core up to 2.2) as the source of the access list
    Only works in Windows PowerShell
    Those versions of .Net had a GetAccessControl method on the [System.IO.DirectoryInfo] class
    This method is removed in modern versions of .Net Core

    .EXAMPLE
    [System.String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor [System.Security.AccessControl.AccessControlSections]::Owner
    $FileSecurity = [System.IO.FileSystemAclExtensions]::GetAccessControl($DirectoryInfo,$Sections)

    The [System.IO.FileSystemAclExtensions] class is a Windows-specific implementation
    It provides no known benefit over the cross-platform equivalent [System.Security.AccessControl.FileSecurity]

    .NOTES
    Dependencies:
        Get-DirectoryEntry
        Add-SidInfo
        Get-TrustedDomain
        Find-AdsiProvider

    if ($FolderPath.Length -gt 255) {
        $FolderPath = "\\?\$FolderPath"
    }
#>
    [OutputType([void])]
    param (

        # Authorization Rule Collection of Access Control Entries from Discretionary Access Control Lists
        [Parameter(
            ValueFromPipeline
        )]
        [object]$ACE,

        # Cache of access control lists keyed by path
        [hashtable]$ACLsByPath = [hashtable]::Synchronized(@{}),

        [Parameter(
            ValueFromPipeline
        )]
        [object]$ItemPath,

        # Cache of access control entries keyed by GUID generated in this function
        [hashtable]$ACEsByGUID = ([hashtable]::Synchronized(@{})),

        # Cache of access control entry GUIDs keyed by their resolved identities
        [hashtable]$AceGUIDsByResolvedID = ([hashtable]::Synchronized(@{})),

        # Cache of access control entry GUIDs keyed by their paths
        [hashtable]$AceGUIDsByPath = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        [hashtable]$Win32AccountsBySID = ([hashtable]::Synchronized(@{})),

        [hashtable]$Win32AccountsByCaption = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        <#
    Hostname of the computer running this function.

    Can be provided as a string to avoid calls to HOSTNAME.EXE
    #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
    FQDN of the computer running this function.

    Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
    #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        [string[]]$ACEPropertyName = (Get-Member -InputObject $ACE -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name,

        # Will be set as the Source property of the output object.
        # Intended to reflect permissions resulting from Ownership rather than Discretionary Access Lists
        [string]$Source,

        # String translations indexed by value in the [System.Security.AccessControl.InheritanceFlags] enum
        # Parameter default value is on a single line as a workaround to a PlatyPS bug
        [string[]]$InheritanceFlagResolved = @('this folder but not subfolders', 'this folder and subfolders', 'this folder and files, but not subfolders', 'this folder, subfolders, and files')

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    $Log = @{
        ThisHostname = $ThisHostname
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    $Cache1 = @{
        DirectoryEntryCache    = $DirectoryEntryCache
        DomainsByFqdn          = $DomainsByFqdn
        Win32AccountsBySID     = $Win32AccountsBySID
        Win32AccountsByCaption = $Win32AccountsByCaption
    }

    $Cache2 = @{
        DomainsByNetBIOS = $DomainsByNetbios
        DomainsBySid     = $DomainsBySid
        CimCache         = $CimCache
    }

    Write-LogMsg @LogParams -Text "Resolve-IdentityReferenceDomainDNS -IdentityReference '$($ACE.IdentityReference)' -ItemPath '$ItemPath' -ThisFqdn '$ThisFqdn' @Cache2 @Log"
    $DomainDNS = Resolve-IdentityReferenceDomainDNS -IdentityReference $ACE.IdentityReference -ItemPath $ItemPath -ThisFqdn $ThisFqdn @Cache2 @Log

    Write-LogMsg @LogParams -Text "`$AdsiServer = Get-AdsiServer -Fqdn '$DomainDNS' -ThisFqdn '$ThisFqdn'"
    $AdsiServer = Get-AdsiServer -Fqdn $DomainDNS -ThisFqdn $ThisFqdn @GetAdsiServerParams @Cache1 @Cache2 @Log

    Write-LogMsg @LogParams -Text "Resolve-IdentityReference -IdentityReference '$($ACE.IdentityReference)' -AdsiServer `$AdsiServer -ThisFqdn '$ThisFqdn' # ADSI server '$($AdsiServer.AdsiProvider)://$($AdsiServer.Dns)'"
    $ResolvedIdentityReference = Resolve-IdentityReference -IdentityReference $ACE.IdentityReference -AdsiServer $AdsiServer -ThisFqdn $ThisFqdn @Cache1 @Cache2 @Log

    # TODO: add a param to offer DNS instead of or in addition to NetBIOS

    $ObjectProperties = @{
        Access                    = "$($ACE.AccessControlType) $($ACE.FileSystemRights) $($InheritanceFlagResolved[$ACE.InheritanceFlags])"
        AdsiProvider              = $AdsiServer.AdsiProvider
        AdsiServer                = $AdsiServer.Dns
        IdentityReferenceSID      = $ResolvedIdentityReference.SIDString
        IdentityReferenceResolved = $ResolvedIdentityReference.IdentityReferenceNetBios
        Path                      = $ItemPath
        SourceOfAccess            = $Source
        PSTypeName                = 'Permission.AccessControlEntry'
    }

    ForEach ($ThisProperty in $ACEPropertyName) {
        $ObjectProperties[$ThisProperty] = $ACE.$ThisProperty
    }

    $OutputObject = [PSCustomObject]$ObjectProperties
    $Guid = [guid]::NewGuid()
    Add-CacheItem -Cache $ACEsByGUID -Key $Guid -Value $OutputObject -Type ([object])
    $Type = [guid]
    Add-CacheItem -Cache $AceGUIDsByResolvedID -Key $OutputObject.IdentityReferenceResolved -Value $Guid -Type $Type
    Add-CacheItem -Cache $AceGUIDsByPath -Key $OutputObject.Path -Value $Guid -Type $Type

}
function Resolve-Acl {
    <#
    .SYNOPSIS
    Use ADSI to lookup info about IdentityReferences from Authorization Rule Collections that came from Discretionary Access Control Lists
    .DESCRIPTION
    Based on the IdentityReference proprety of each Access Control Entry:
    Resolve SID to NT account name and vise-versa
    Resolve well-known SIDs
    Resolve generic defaults like 'NT AUTHORITY' and 'BUILTIN' to the applicable computer or domain name
    Add these properties (IdentityReferenceSID,IdentityReferenceName,IdentityReferenceResolved) to the object and return it
    .INPUTS
    [System.Security.AccessControl.AuthorizationRuleCollection]$ItemPath
    .OUTPUTS
    [PSCustomObject] Original object plus IdentityReferenceSID,IdentityReferenceName,IdentityReferenceResolved, and AdsiProvider properties
    .EXAMPLE
    Get-Acl |
    Expand-Acl |
    Resolve-Ace

    Use Get-Acl from the Microsoft.PowerShell.Security module as the source of the access list
    This works in either Windows Powershell or in Powershell
    Get-Acl does not support long paths (>256 characters)
    That was why I originally used the .Net Framework method
    .EXAMPLE
    Get-FolderAce -LiteralPath C:\Test -IncludeInherited |
    Resolve-Ace
    .EXAMPLE
    [System.String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor [System.Security.AccessControl.AccessControlSections]::Owner
    $FileSecurity = [System.Security.AccessControl.FileSecurity]::new($DirectoryInfo,$Sections)
    $IncludeExplicitRules = $true
    $IncludeInheritedRules = $true
    $AccountType = [System.Security.Principal.SecurityIdentifier]
    $FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
    Resolve-Ace

    This uses .Net Core as the source of the access list
    It uses the GetAccessRules method on the [System.Security.AccessControl.FileSecurity] class
    The targetType parameter of the method is used to specify that the accounts in the ACL are returned as SIDs
    .EXAMPLE
    [System.String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor
    [System.Security.AccessControl.AccessControlSections]::Owner -bor
    [System.Security.AccessControl.AccessControlSections]::Group
    $DirectorySecurity = [System.Security.AccessControl.DirectorySecurity]::new($DirectoryInfo,$Sections)
    $IncludeExplicitRules = $true
    $IncludeInheritedRules = $true
    $AccountType = [System.Security.Principal.NTAccount]
    $FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
    Resolve-Ace

    This uses .Net Core as the source of the access list
    It uses the GetAccessRules method on the [System.Security.AccessControl.FileSecurity] class
    The targetType parameter of the method is used to specify that the accounts in the ACL are returned as NT account names (DOMAIN\User)
    .EXAMPLE
    [System.String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    [System.Security.AccessControl.DirectorySecurity]$DirectorySecurity = $DirectoryInfo.GetAccessControl('Access')
    [System.Security.AccessControl.AuthorizationRuleCollection]$AuthRules = $DirectorySecurity.Access
    $AuthRules | Resolve-Ace

    Use the .Net Framework (or legacy .Net Core up to 2.2) as the source of the access list
    Only works in Windows PowerShell
    Those versions of .Net had a GetAccessControl method on the [System.IO.DirectoryInfo] class
    This method is removed in modern versions of .Net Core

    .EXAMPLE
    [System.String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor [System.Security.AccessControl.AccessControlSections]::Owner
    $FileSecurity = [System.IO.FileSystemAclExtensions]::GetAccessControl($DirectoryInfo,$Sections)

    The [System.IO.FileSystemAclExtensions] class is a Windows-specific implementation
    It provides no known benefit over the cross-platform equivalent [System.Security.AccessControl.FileSecurity]

    .NOTES
    Dependencies:
        Get-DirectoryEntry
        Add-SidInfo
        Get-TrustedDomain
        Find-AdsiProvider

    if ($FolderPath.Length -gt 255) {
        $FolderPath = "\\?\$FolderPath"
    }
#>
    [OutputType([PSCustomObject])]
    param (

        # Authorization Rule Collection of Access Control Entries from Discretionary Access Control Lists
        [Parameter(
            ValueFromPipeline
        )]
        [object]$ItemPath,

        # Cache of access control lists keyed by path
        [hashtable]$ACLsByPath = [hashtable]::Synchronized(@{}),

        # Cache of access control entries keyed by GUID generated in this function
        [hashtable]$ACEsByGUID = ([hashtable]::Synchronized(@{})),

        # Cache of access control entry GUIDs keyed by their resolved identities
        [hashtable]$AceGUIDsByResolvedID = ([hashtable]::Synchronized(@{})),

        # Cache of access control entry GUIDs keyed by their paths
        [hashtable]$AceGUIDsByPath = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        [hashtable]$Win32AccountsBySID = ([hashtable]::Synchronized(@{})),

        [hashtable]$Win32AccountsByCaption = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        [string[]]$ACEPropertyName = (Get-Member -InputObject $ItemPath -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name,

        # String translations indexed by value in the [System.Security.AccessControl.InheritanceFlags] enum
        # Parameter default value is on a single line as a workaround to a PlatyPS bug
        [string[]]$InheritanceFlagResolved = @('this folder but not subfolders', 'this folder and subfolders', 'this folder and files, but not subfolders', 'this folder, subfolders, and files')

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    $ACL = $ACLsByPath[$ItemPath]

    if ($ACL.Owner.IdentityReference) {
        Write-LogMsg -Text "Resolve-Ace -ACE $($ACL.Owner) -ACEPropertyName @('$($ACEPropertyName -join "','")') @PSBoundParameters" @LogParams
        Resolve-Ace -ACE $ACL.Owner -Source 'Ownership' @PSBoundParameters
    }

    ForEach ($ACE in $ACL.Access) {
        Write-LogMsg -Text "Resolve-Ace -ACE $ACE -ACEPropertyName @('$($ACEPropertyName -join "','")') @PSBoundParameters" @LogParams
        Resolve-Ace -ACE $ACE -Source 'Discretionary ACL' @PSBoundParameters
    }

}
function Resolve-Folder {

    # Resolve the provided FolderPath to all of its associated UNC paths, including all DFS folder targets

    param (

        # Path of the folder(s) to resolve to all their associated UNC paths
        [string]$TargetPath,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$ThisHostname = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages
    )

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputstream
        WhoAmI       = $WhoAmI
    }

    $LoggingParams = @{
        LogMsgCache       = $LogMsgCache
        ThisHostname      = $ThisHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
    }

    $RegEx = '^(?<DriveLetter>\w):'

    if ($TargetPath -match $RegEx) {

        Write-LogMsg @LogParams -Text "Get-CachedCimInstance -ComputerName $ThisHostname -ClassName Win32_MappedLogicalDisk"
        $MappedNetworkDrives = Get-CachedCimInstance -ComputerName $ThisHostname -ClassName Win32_MappedLogicalDisk -KeyProperty DeviceID -CimCache $CimCache -ThisFqdn $ThisFqdn @LoggingParams

        $MatchingNetworkDrive = $MappedNetworkDrives |
        Where-Object -FilterScript { $_.DeviceID -eq "$($Matches.DriveLetter):" }

        if ($MatchingNetworkDrive) {
            # Resolve mapped network drives to their UNC path
            $UNC = $MatchingNetworkDrive.ProviderName
        } else {
            # Resolve local drive letters to their UNC paths using administrative shares
            $UNC = $TargetPath -replace $RegEx, "\\$(hostname)\$($Matches.DriveLetter)$"
        }

        if ($UNC) {
            # Replace hostname with FQDN in the path
            $Server = $UNC.split('\')[2]
            $FQDN = ConvertTo-DnsFqdn -ComputerName $Server
            $UNC -replace "^\\\\$Server\\", "\\$FQDN\"
        }

    } else {

        ## Workaround in place: Get-NetDfsEnum -Verbose parameter is not used due to errors when it is used with the PsRunspace module for multithreading
        ## https://github.com/IMJLA/Export-Permission/issues/46
        ## https://github.com/IMJLA/PsNtfs/issues/1
        Write-LogMsg @LogParams -Text "Get-NetDfsEnum -FolderPath '$TargetPath'"
        $AllDfs = Get-NetDfsEnum -FolderPath $TargetPath -ErrorAction SilentlyContinue

        if ($AllDfs) {

            $MatchingDfsEntryPaths = $AllDfs |
            Group-Object -Property DfsEntryPath |
            Where-Object -FilterScript {
                $TargetPath -match [regex]::Escape($_.Name)
            }

            # Filter out the DFS Namespace
            # TODO: I know this is an inefficient n2 algorithm, but my brain is fried...plez...halp...leeloo dallas multipass
            $RemainingDfsEntryPaths = $MatchingDfsEntryPaths |
            Where-Object -FilterScript {
                -not [bool]$(
                    ForEach ($ThisEntryPath in $MatchingDfsEntryPaths) {
                        if ($ThisEntryPath.Name -match "$([regex]::Escape("$($_.Name)")).+") { $true }
                    }
                )
            } |
            Sort-Object -Property Name

            $RemainingDfsEntryPaths |
            Select-Object -Last 1 -ExpandProperty Group |
            ForEach-Object {
                $_.FullOriginalQueryPath -replace [regex]::Escape($_.DfsEntryPath), $_.DfsTarget
            }

        } else {

            $Server = $TargetPath.split('\')[2]
            $FQDN = ConvertTo-DnsFqdn -ComputerName $Server
            $TargetPath -replace "^\\\\$Server\\", "\\$FQDN\"

        }

    }

}
function Resolve-IdentityReferenceDomainDNS {

    param (

        [string]$IdentityReference,

        [object]$ItemPath,

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{}))

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    switch -Wildcard ($IdentityReference) {

        "S-1-*" {
            # IdentityReference is a SID (Revision 1)
            $IndexOfLastHyphen = $IdentityReference.LastIndexOf("-")
            $DomainSid = $IdentityReference.Substring(0, $IndexOfLastHyphen)
            if ($DomainSid) {
                $DomainCacheResult = $DomainsBySID[$DomainSid]
                if ($DomainCacheResult) {
                    Write-LogMsg @LogParams -Text " # Domain SID cache hit for '$DomainSid' for '$IdentityReference'"
                    $DomainDNS = $DomainCacheResult.Dns
                } else {
                    Write-LogMsg @LogParams -Text " # Domain SID cache miss for '$DomainSid' for '$IdentityReference'"
                }
            }
        }
        "NT SERVICE\*" {}
        "BUILTIN\*" {}
        "NT AUTHORITY\*" {}
        default {
            $DomainNetBIOS = ($IdentityReference -split '\\')[0]
            if ($DomainNetBIOS) {
                $DomainDNS = $DomainsByNetbios[$DomainNetBIOS].Dns #Doesn't work for BUILTIN, etc.
            }
            if (-not $DomainDNS) {
                $ThisServerDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -DomainsByNetbios $DomainsByNetbios @LoggingParams
                $DomainDNS = ConvertTo-Fqdn -DistinguishedName $ThisServerDn -ThisFqdn $ThisFqdn -CimCache $CimCache @LoggingParams
            }
        }
    }

    if (-not $DomainDNS) {
        # TODO - Bug: I think this will report incorrectly for a remote domain not in the cache (trust broken or something)
        Write-LogMsg @LogParams -Text "Find-ServerNameInPath -LiteralPath '$ItemPath' -ThisFqdn '$ThisFqdn'"
        $DomainDNS = Find-ServerNameInPath -LiteralPath $ItemPath -ThisFqdn $ThisFqdn
    }

    return $DomainDNS

}
function Resolve-PermissionTarget {

    # Resolve each target path to all of its associated UNC paths (including all DFS folder targets)

    param (

        # Path to the NTFS folder whose permissions to export
        [Parameter(ValueFromPipeline)]
        [ValidateScript({ Test-Path $_ })]
        [System.IO.DirectoryInfo[]]$TargetPath,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$ThisHostname = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # Cache of access control lists keyed by path
        [hashtable]$ACLsByPath = [hashtable]::Synchronized(@{})

    )

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputstream
        WhoAmI       = $WhoAmI
    }

    $ResolveFolderParams = @{
        LogMsgCache       = $LogMsgCache
        ThisHostname      = $ThisHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
        CimCache          = $CimCache
        ThisFqdn          = $ThisFqdn
    }

    ForEach ($ThisTargetPath in $TargetPath) {

        Write-LogMsg @LogParams -Text "Resolve-Folder -TargetPath '$ThisTargetPath'"
        $Resolved = Resolve-Folder -TargetPath $ThisTargetPath @ResolveFolderParams

        ForEach ($ThisOne in $Resolved) {
            $ACLsByPath[$ThisOne] = $null
        }

    }

}
function Select-FolderPermissionTableProperty {

    # For the HTML table
    param (
        $InputObject,
        $IgnoreDomain
    )

    ForEach ($Object in $InputObject) {

        # Each ACE contains the original IdentityReference representing the group the Object is a member of
        $GroupString = ($Object.Access.IdentityReferenceResolved | Sort-Object -Unique) -join ' ; '

        # ToDo: param to allow setting [self] instead of the objects own name for this property
        #if ($GroupString -eq $Object.Account.ResolvedAccountName) {
        #    $GroupString = '[self]'
        #} else {
        ForEach ($IgnoreThisDomain in $IgnoreDomain) {
            $GroupString = $GroupString -replace "$IgnoreThisDomain\\", ''
        }
        #}

        [pscustomobject]@{
            'Account'              = $Object.Account.ResolvedAccountName
            'Access'               = ($Object.Access.FileSystemRights | Sort-Object -Unique) -join ' ; '
            'Due to Membership In' = $GroupString
            'Source of Access'     = ($Object.Access.SourceOfAccess | Sort-Object -Unique) -join ' ; '
            'Name'                 = $Object.Account.Name
            'Department'           = $Object.Account.Department
            'Title'                = $Object.Account.Title
        }

    }

}
function Select-ItemTableProperty {

    # For the HTML table

    param (
        $InputObject,
        $Culture = (Get-Culture)
    )

    ForEach ($Object in $InputObject) {

        [PSCustomObject]@{
            Folder      = $Object.Item.Path
            Inheritance = $Culture.TextInfo.ToTitleCase(-not $Object.Item.AreAccessRulesProtected)
        }

    }

}
function Select-UniquePrincipal {

    param (

        # Cache of security principals keyed by resolved identity reference
        [hashtable]$PrincipalsByResolvedID = ([hashtable]::Synchronized(@{})),

        # Regular expressions matching names of Users or Groups to exclude from the Html report
        [string[]]$ExcludeAccount,

        <#
        Domain(s) to ignore (they will be removed from the username)

        Intended when a user has matching SamAccountNames in multiple domains but you only want them to appear once on the report.

        Can also be used to remove all domains simply for brevity in the report.
        #>
        [string[]]$IgnoreDomain,

        # Hashtable will be used to deduplicate
        $UniquePrincipal = [hashtable]::Synchronized(@{}),

        $UniquePrincipalsByResolvedID = [hashtable]::Synchronized(@{})

    )

    $FilterContents = @{}

    ForEach ($ThisID in $PrincipalsByResolvedID.Keys) {

        if (
            # Exclude the objects whose names match the regular expressions specified in the parameters
            [bool]$(
                ForEach ($RegEx in $ExcludeAccount) {
                    if ($ThisID -match $RegEx) {
                        $FilterContents[$ThisID] = $ThisID
                        $true
                    }
                }
            )
        ) { continue }

        $ShortName = $ThisID

        ForEach ($IgnoreThisDomain in $IgnoreDomain) {
            $ShortName = $ShortName -replace "^$IgnoreThisDomain\\", ''
        }

        $ThisKnownUser = $null
        $ThisKnownUser = $UniquePrincipal[$ShortName]
        if ($null -eq $ThisKnownUser) {
            $UniquePrincipal[$ShortName] = [System.Collections.Generic.List[string]]::new()

        }

        $null = $UniquePrincipal[$ShortName].Add($ThisID)
        $UniquePrincipalsByResolvedID[$ThisID] = $ShortName

    }

}
function Update-CaptionCapitalization {
    # As of 2022-08-31 this function is still not implemented...need to rethink
    param (
        [string]$ThisHostName,
        [hashtable]$Win32AccountsByCaption
    )
    $NewDictionary = [hashtable]::Synchronized(@{})
    $Win32AccountsByCaption.Keys |
    ForEach-Object {
        $Object = $Win32AccountsByCaption[$_]
        $NewKey = $_ -replace "^$ThisHostname\\$ThisHostname\\", "$ThisHostname\$ThisHostname\"
        $NewKey = $NewKey -replace "^$ThisHostname\\", "$ThisHostname\"
        $NewDictionary[$NewKey] = $Object
    }
    return $NewDictionary
}

# Add any custom C# classes as usable (exported) types
$CSharpFiles = Get-ChildItem -Path "$PSScriptRoot\*.cs"
ForEach ($ThisFile in $CSharpFiles) {
    Add-Type -Path $ThisFile.FullName -ErrorAction Stop
}

Export-ModuleMember -Function @('Add-CacheItem','ConvertTo-ItemBlock','Expand-AcctPermission','Expand-PermissionPrincipal','Expand-PermissionTarget','Export-FolderPermissionHtml','Export-RawPermissionCsv','Export-ResolvedPermissionCsv','Format-FolderPermission','Format-TimeSpan','Get-CachedCimInstance','Get-CachedCimSession','Get-FolderAcl','Get-FolderColumnJson','Get-FolderPermissionsBlock','Get-FolderPermissionTableHeader','Get-FolderTableHeader','Get-HtmlBody','Get-HtmlReportFooter','Get-Permission','Get-PermissionPrincipal','Get-PrtgXmlSensorOutput','Get-ReportDescription','Get-TimeZoneName','Get-UniqueServerFqdn','Group-Permission','Initialize-Cache','Invoke-PermissionCommand','Remove-CachedCimSession','Resolve-AccessControlList','Resolve-Ace','Resolve-Acl','Resolve-Folder','Resolve-IdentityReferenceDomainDNS','Resolve-PermissionTarget','Select-FolderPermissionTableProperty','Select-ItemTableProperty','Select-UniquePrincipal','Update-CaptionCapitalization')






























































































































































































































