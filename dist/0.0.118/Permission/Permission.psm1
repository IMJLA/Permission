
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
        [hashtable]$LogMsgCache = $Global:LogMessages

    )

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $Count = $SecurityPrincipal.Count

    if ($ThreadCount -eq 1) {

        [int]$ProgressInterval = [math]::max(($Count / 100), 1)
        $ProgressCounter = 0
        $i = 0
        ForEach ($ThisPrinc in $SecurityPrincipal) {
            $ProgressCounter++
            if ($ProgressCounter -eq $ProgressInterval) {
                $PercentComplete = $i / $Count * 100
                Write-Progress -Activity 'Expand-AcctPermission' -Status "$([int]$PercentComplete)%" -CurrentOperation "Expand-AccountPermission '$($ThisPrinc.Name)'" -PercentComplete $PercentComplete
                $ProgressCounter = 0
            }
            $i++

            Write-LogMsg @LogParams -Text "Expand-AccountPermission -AccountPermission $($ThisPrinc.Name)"
            Expand-AccountPermission -AccountPermission $ThisPrinc
        }
        Write-Progress -Activity 'Expand-AcctPermission' -Completed

    } else {
        $ExpandAccountPermissionParams = @{
            Command              = 'Expand-AccountPermission'
            InputObject          = $SecurityPrincipal
            InputParameter       = 'AccountPermission'
            TodaysHostname       = $ThisHostname
            ObjectStringProperty = 'Name'
            Timeout              = 1200
            Threads              = $ThreadCount
            AddParam             = @{
                WhoAmI      = $WhoAmI
                LogMsgCache = $LogMsgCache
            }
        }

        Write-LogMsg @LogParams -Text "Split-Thread -Command 'Expand-AccountPermission' -InputParameter 'AccountPermission' -InputObject `$SecurityPrincipal -ObjectStringProperty 'Name'"
        Split-Thread @ExpandAccountPermissionParams

    }

}
function Expand-Folder {

    # Expand a folder path into the paths of its subfolders

    param (

        # Path to return along, with the paths to its subfolders
        $Folder,

        <#
        How many levels of subfolder to enumerate

            Set to 0 to ignore all subfolders

            Set to -1 (default) to recurse infinitely

            Set to any whole number to enumerate that many levels
        #>
        $LevelsOfSubfolders,

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
        [int]$ProgressParentId

    )

    $Progress = @{
        Activity = 'Expand-Folder'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }

    Write-Progress @Progress -Status "0%" -CurrentOperation "Initializing..." -PercentComplete 0

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

    $FolderCount = @($Folder).Count
    if ($ThreadCount -eq 1 -or $FolderCount -eq 1) {

        [int]$ProgressInterval = [math]::max(($FolderCount / 100), 1)
        $ProgressCounter = 0
        $i = 0
        ForEach ($ThisFolder in $Folder) {
            $ProgressCounter++
            if ($ProgressCounter -eq $ProgressInterval) {
                $PercentComplete = $i / $FolderCount * 100
                Write-Progress @Progress -Status "$([int]$PercentComplete)% (item $($i++) of $FolderCount))" -CurrentOperation "Get-Subfolder '$($ThisFolder)'" -PercentComplete $PercentComplete
                $ProgressCounter = 0
            }
            $i++ # increment $i after the progress to show progress conservatively rather than optimistically

            $Subfolders = $null
            $Subfolders = Get-Subfolder -TargetPath $ThisFolder -FolderRecursionDepth $LevelsOfSubfolders -ErrorAction Continue @GetSubfolderParams
            Write-LogMsg @LogParams -Text "# Folders (including parent): $($Subfolders.Count + 1) for '$ThisFolder'"
            $Subfolders
        }

    } else {

        $GetSubfolder = @{
            Command           = 'Get-Subfolder'
            InputObject       = $Folder
            InputParameter    = 'TargetPath'
            DebugOutputStream = $DebugOutputStream
            TodaysHostname    = $ThisHostname
            WhoAmI            = $WhoAmI
            LogMsgCache       = $LogMsgCache
            Threads           = $ThreadCount
            AddParam          = @{
                LogMsgCache       = $LogMsgCache
                ThisHostname      = $ThisHostname
                DebugOutputStream = $DebugOutputStream
                WhoAmI            = $WhoAmI
            }
        }
        Split-Thread @GetSubfolder

    }

    Write-Progress @Progress -Completed

}
function Expand-PermissionIdentity {

    param (

        # Permission objects from Get-FolderAccessList whose IdentityReference to resolve
        [Parameter(ValueFromPipeline)]
        [object[]]$Identity,

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Maximum number of concurrent threads to allow
        [int]$ThreadCount = (Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum,

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

        # Thread-safe hashtable to use for caching directory entries and avoiding duplicate directory queries
        [hashtable]$IdentityReferenceCache = ([hashtable]::Synchronized(@{})),

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
        [switch]$NoGroupMembers

    )

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    if ($ThreadCount -eq 1) {
        $ExpandIdentityReferenceParams = @{
            DirectoryEntryCache    = $DirectoryEntryCache
            IdentityReferenceCache = $IdentityReferenceCache
            DomainsBySID           = $DomainsBySID
            DomainsByNetbios       = $DomainsByNetbios
            DomainsByFqdn          = $DomainsByFqdn
            ThisHostName           = $ThisHostName
            ThisFqdn               = $ThisFqdn
            WhoAmI                 = $WhoAmI
            LogMsgCache            = $LogMsgCache
            DebugOutputStream      = $DebugOutputStream
        }
        if ($NoGroupMembers) {
            $ExpandIdentityReferenceParams['NoGroupMembers'] = $true
        }

        [int]$ProgressInterval = [math]::max(($Identity.Count / 100), 1)
        $ProgressCounter = 0
        $i = 0
        ForEach ($ThisID in $Identity) {
            $ProgressCounter++
            if ($ProgressCounter -eq $ProgressInterval) {
                $PercentComplete = $i / $Identity.Count * 100
                Write-Progress -Activity 'Expand-IdentityReference' -Status "$([int]$PercentComplete)%" -CurrentOperation $ThisID.Name -PercentComplete $PercentComplete
                $ProgressCounter = 0
            }
            $i++

            $ExpandIdentityReferenceParams['AccessControlEntry'] = $ThisID
            Write-LogMsg @LogParams -Text "Expand-IdentityReference -AccessControlEntry $($ThisID.Name)"
            Expand-IdentityReference @ExpandIdentityReferenceParams
        }
        Write-Progress -Activity 'Expand-IdentityReference' -Completed

    } else {
        $ExpandIdentityReferenceParams = @{
            Command              = 'Expand-IdentityReference'
            InputObject          = $Identity
            InputParameter       = 'AccessControlEntry'
            TodaysHostname       = $ThisHostname
            WhoAmI               = $WhoAmI
            LogMsgCache          = $LogMsgCache
            Threads              = $ThreadCount
            AddParam             = @{
                DirectoryEntryCache    = $DirectoryEntryCache
                IdentityReferenceCache = $IdentityReferenceCache
                DomainsBySID           = $DomainsBySID
                DomainsByNetbios       = $DomainsByNetbios
                DomainsByFqdn          = $DomainsByFqdn
                ThisHostName           = $ThisHostName
                ThisFqdn               = $ThisFqdn
                WhoAmI                 = $WhoAmI
                LogMsgCache            = $LogMsgCache
                DebugOutputStream      = $DebugOutputStream
            }
            ObjectStringProperty = 'Name'
        }
        if ($NoGroupMembers) {
            $ExpandIdentityReferenceParams['AddSwitch'] = 'NoGroupMembers'
        }
        Write-LogMsg @LogParams -Text "Split-Thread -Command 'Expand-IdentityReference' -InputParameter 'AccessControlEntry' -InputObject `$Identity"
        Split-Thread @ExpandIdentityReferenceParams
    }
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

        $FolderPermissions,
        $LogParams,
        $ReportDescription,
        $FolderTableHeader,
        $ReportFileList,
        $ReportFile,
        $LogFileList,
        $ReportInstanceId,
        $Subfolders,
        $ResolvedFolderTargets
    )

    # Convert the target path(s) to a Bootstrap alert
    $TargetPathString = $TargetPath -join '<br />'
    Write-LogMsg @LogParams -Text "New-BootstrapAlert -Class Dark -Text '$TargetPathString'"
    $ReportDescription = "$(New-BootstrapAlert -Class Dark -Text $TargetPathString) $ReportDescription"

    # Convert the folder list to an HTML table
    $FormattedFolders = Get-FolderBlock -FolderPermissions $FolderPermissions

    # Convert the folder permissions to an HTML table
    $GetFolderPermissionsBlock = @{
        FolderPermissions = $FolderPermissions
        ExcludeAccount    = $ExcludeAccount
        ExcludeClass      = $ExcludeClass
        IgnoreDomain      = $IgnoreDomain
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

    $FormattedFolderPermissions |
    ForEach-Object {
        $null = $ScriptHtmlBuilder.AppendLine((ConvertTo-BootstrapTableScript -TableId "#Perms_$($_.Path -replace '[^A-Za-z0-9\-_:.]', '-')" -ColumnJson $_.JsonColumns -DataJson $_.JsonData))
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
    $ChildProgress = {
        Activity = 'Flatten the raw access control entries for CSV export'
        Id = $ProgressId++
        ParentId = $ProgressId
    }

    Write-Progress -CurrentOperation 'Flattening the raw access control entries for CSV export' -Status '0% (step 1 of 2)' -PercentComplete 0 @Progress

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
            Write-Progress -CurrentOperation "'$($Obj.IdentityReference)' on '$($Obj.SourceAccessList.Path)'" -Status "$PercentComplete% (entry $($i++) of $Count)" -PercentComplete $PercentComplete  @ChildProgress
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
    Write-Progress -CurrentOperation "Saving '$LiteralPath'" @Progress -PercentComplete 50 -Status '50% (step 2 of 2)'
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

        [hashtable]$LogMsgCache = $Global:LogMessages

    )

    Write-Progress -Activity 'Export-ResolvedPermissionCsv' -CurrentOperation 'Initializing' -Status '0%' -PercentComplete 0

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    Write-LogMsg @LogParams -Text "`$PermissionsWithResolvedIdentityReferences |"
    Write-LogMsg @LogParams -Text "`Select-Object -Property @{ Label = 'Path'; Expression = { `$_.SourceAccessList.Path } }, * |"
    Write-LogMsg @LogParams -Text "Export-Csv -NoTypeInformation -LiteralPath '$LiteralPath'"
    Write-Progress -Activity 'Export-ResolvedPermissionCsv' -CurrentOperation "Export-Csv '$LiteralPath'" -Status "$([int]$PercentComplete)%" -PercentComplete 50

    $Permission |
    Select-Object -Property @{
        Label      = 'Path'
        Expression = { $_.SourceAccessList.Path }
    }, * |
    Export-Csv -NoTypeInformation -LiteralPath $LiteralPath

    Write-Progress -Activity 'Export-ResolvedPermissionCsv' -Completed
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
        [hashtable]$LogMsgCache = $Global:LogMessages

    )

    begin {
        $i = 0

        $LogParams = @{
            ThisHostname = $ThisHostname
            Type         = 'Verbose'
            LogMsgCache  = $LogMsgCache
            WhoAmI       = $WhoAmI
        }

        $Activity = "Format-FolderPermission -FileSystemRightsToIgnore @('$($FileSystemRightsToIgnore -join "','")')"

    }
    process {

        $Count = ($UserPermission | Measure-Object).Count

        ForEach ($ThisUser in $UserPermission) {

            #Calculate the completion percentage, and format it to show 0 decimal places
            $i++
            $NewPercentComplete = $i / $Count * 100

            #Update the log with the current status
            [string]$statusMsg = "$([int]$NewPercentComplete)% ($($Count - $i) of $Count remain) Formatting user permission $i of $Count`: $($ThisUser.Name)"
            Write-LogMsg @LogParams -Text $statusMsg

            # Update the progress bar if at least 1% has completed since last loop iteration
            if (($NewPercentComplete - $OldPercentComplete) -ge 1) {
                $OldPercentComplete = $NewPercentComplete
                $Progress = @{
                    Activity         = $Activity
                    CurrentOperation = $statusMsg
                    PercentComplete  = $NewPercentComplete
                    Status           = $statusMsg
                }
                Write-Progress @Progress
            }
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
                }
                else {
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
                    }
                    else {
                        $SchemaClassName = 'user'
                    }
                }
                $Name = @($Names)[0]
                $Dept = @($Depts)[0]
                $Title = @($Titles)[0]
            }
            else {
                $Name = @($ThisUser.Group.name)[0]
                $Dept = @($ThisUser.Group.department)[0]
                $Title = @($ThisUser.Group.title)[0]

                if ($ThisUser.Group.Properties) {
                    if (
                        $ThisUser.Group.Properties['objectclass'] -contains 'group' -or
                        "$($ThisUser.Group.Properties['groupType'])" -ne ''
                    ) {
                        $SchemaClassName = 'group'
                    }
                    else {
                        $SchemaClassName = 'user'
                    }
                }
                else {
                    if ($ThisUser.Group.DirectoryEntry.SchemaClassName) {
                        $SchemaClassName = @($ThisUser.Group.DirectoryEntry.SchemaClassName)[0]
                    }
                    else {
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
                }
                else {
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
                }

            }

        }

    }

    end {
        Write-Progress -Activity $Activity -Completed
    }

}
function Format-PermissionAccount {

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
        [hashtable]$LogMsgCache = $Global:LogMessages

    )

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $Count = $SecurityPrincipal.Count

    if ($ThreadCount -eq 1) {

        [int]$ProgressInterval = [math]::max(($Count / 100), 1)
        $ProgressCounter = 0
        $i = 0

        ForEach ($ThisPrinc in $SecurityPrincipal) {

            $ProgressCounter++

            if ($ProgressCounter -eq $ProgressInterval) {

                $PercentComplete = $i / $Count * 100
                Write-Progress -Activity 'Format-SecurityPrincipal' -Status "$([int]$PercentComplete)%" -CurrentOperation $ThisPrinc.Name -PercentComplete $PercentComplete
                $ProgressCounter = 0

            }
            $i++

            Write-LogMsg @LogParams -Text "Format-SecurityPrincipal -SecurityPrincipal $($ThisPrinc.Name)"
            Format-SecurityPrincipal -SecurityPrincipal $ThisPrinc

        }

        Write-Progress -Activity 'Format-SecurityPrincipal' -Completed

    } else {

        $FormatSecurityPrincipalParams = @{
            Command              = 'Format-SecurityPrincipal'
            InputObject          = $SecurityPrincipal
            InputParameter       = 'SecurityPrincipal'
            Timeout              = 1200
            ObjectStringProperty = 'Name'
            TodaysHostname       = $ThisHostname
            WhoAmI               = $WhoAmI
            LogMsgCache          = $LogMsgCache
            Threads              = $ThreadCount
        }

        Write-LogMsg @LogParams -Text "Split-Thread -Command 'Format-SecurityPrincipal' -InputParameter 'SecurityPrincipal' -InputObject `$SecurityPrincipal -ObjectStringProperty 'Name'"
        Split-Thread @FormatSecurityPrincipalParams

    }

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
function Get-FolderAccessList {
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
        [int]$ProgressParentId

    )

    $Progress = @{
        Activity = 'Get-FolderAccessList'
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

    Write-Progress @Progress -Status '0% (step 1 of 4)' -CurrentOperation 'Parent DACLs' -PercentComplete 0

    $GetFolderAceParams = @{
        LogMsgCache       = $LogMsgCache
        ThisHostname      = $TodaysHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
    }

    # We expect a small number of folders and a large number of subfolders
    # We will multithread the subfolders but not the folders
    # Multithreading overhead actually hurts performance for such a fast operation (Get-FolderAce) on a small number of items
    $i = 0
    $Count = $Folder.Count
    ForEach ($ThisFolder in $Folder) {
        [int]$PercentComplete = $i / $Count * 100
        Write-Progress @ChildProgress -Status "$PercentComplete% (parent $($i++) of $Count)" -CurrentOperation "Get-FolderAce -IncludeInherited '$ThisFolder'" -PercentComplete $PercentComplete
        $i++
        Get-FolderAce -LiteralPath $ThisFolder -OwnerCache $OwnerCache -LogMsgCache $LogMsgCache -IncludeInherited @GetFolderAceParams
    }

    Write-Progress @ChildProgress -Completed
    $ChildProgress['Activity'] = 'Get-FolderAccessList (child DACLs)'
    Write-Progress @Progress -Status '25% (step 2 of 4)' -CurrentOperation $ChildProgress['Activity'] -PercentComplete 25
    $SubfolderCount = $Subfolder.Count

    if ($ThreadCount -eq 1) {
        Write-Progress @ChildProgress -Status '0%' -CurrentOperation 'Initializing'
        [int]$ProgressInterval = [math]::max(($SubfolderCount / 100), 1)
        $ProgressCounter = 0
        $i = 0
        ForEach ($ThisFolder in $Subfolder) {
            $ProgressCounter++
            if ($ProgressCounter -eq $ProgressInterval) {
                [int]$PercentComplete = $i / $SubfolderCount * 100
                Write-Progress @ChildProgress -Status "$PercentComplete% (child $($i++) of $SubfolderCount)" -CurrentOperation "Get-FolderAce '$ThisFolder'" -PercentComplete $PercentComplete
                $ProgressCounter = 0
            }
            $i++ # increment $i after the progress to show progress conservatively rather than optimistically

            Get-FolderAce -LiteralPath $ThisFolder -LogMsgCache $LogMsgCache -OwnerCache $OwnerCache @GetFolderAceParams
        }

        Write-Progress @ChildProgress -Completed
        Write-Progress @Progress -Status '50% (step 3 of 4)' -CurrentOperation 'Parent Owners' -PercentComplete 50

    } else {

        $GetFolderAce = @{
            Command           = 'Get-FolderAce'
            InputObject       = $Subfolder
            InputParameter    = 'LiteralPath'
            DebugOutputStream = $DebugOutputStream
            TodaysHostname    = $TodaysHostname
            WhoAmI            = $WhoAmI
            LogMsgCache       = $LogMsgCache
            Threads           = $ThreadCount
            AddParam          = @{
                OwnerCache        = $OwnerCache
                LogMsgCache       = $LogMsgCache
                ThisHostname      = $TodaysHostname
                DebugOutputStream = $DebugOutputStream
                WhoAmI            = $WhoAmI
            }

        }

        Split-Thread @GetFolderAce

    }

    # Return ACEs for the item owners (if they do not match the owner of the item's parent folder)
    # First return the owner of the parent item
    # We expect a small number of folders and a large number of subfolders
    # We will multithread the subfolders but not the folders
    # Multithreading overhead actually hurts performance for such a fast operation (Get-FolderAce) on a small number of items
    $ChildProgress['Activity'] = 'Get-FolderAccessList (parent owners)'
    $i = 0
    ForEach ($ThisFolder in $Folder) {
        [int]$PercentComplete = $i / $Count * 100
        Write-Progress @ChildProgress -Status "$PercentComplete% (parent $($i++) of $Count)" -CurrentOperation "Get-OwnerAce '$ThisFolder'" -PercentComplete $PercentComplete
        $i++
        Get-OwnerAce -Item $ThisFolder -OwnerCache $OwnerCache
    }
    Write-Progress @ChildProgress -Completed
    Write-Progress @Progress -Status '75% (step 4 of 4)' -CurrentOperation 'Child Owners' -PercentComplete 75
    $ChildProgress['Activity'] = 'Get-FolderAccessList (child owners)'

    # Then return the owners of any items that differ from their parents' owners
    if ($ThreadCount -eq 1) {

        $ProgressCounter = 0
        $i = 0
        ForEach ($Child in $Subfolder) {
            Write-Progress @ChildProgress -Status '0%' -CurrentOperation 'Initializing'
            $ProgressCounter++
            if ($ProgressCounter -eq $ProgressInterval) {
                [int]$PercentComplete = $i / $SubfolderCount * 100
                Write-Progress @ChildProgress -Status "$PercentComplete% (child $($i++) of $SubfolderCount))" -CurrentOperation "Get-FolderAce '$Child'" -PercentComplete $PercentComplete
                $ProgressCounter = 0
            }
            $i++
            Get-OwnerAce -Item $Child -OwnerCache $OwnerCache

        }
        Write-Progress @ChildProgress -Completed

    } else {

        $GetOwnerAce = @{
            Command           = 'Get-OwnerAce'
            InputObject       = $Subfolder
            InputParameter    = 'Item'
            DebugOutputStream = $DebugOutputStream
            TodaysHostname    = $TodaysHostname
            WhoAmI            = $WhoAmI
            LogMsgCache       = $LogMsgCache
            Threads           = $ThreadCount
            AddParam          = @{
                OwnerCache = $OwnerCache
            }
        }

        Split-Thread @GetOwnerAce

    }

    Write-Progress @Progress -Completed

}
function Get-FolderBlock {
    param (

        $FolderPermissions

    )

    Write-LogMsg @LogParams -Text "Select-FolderTableProperty -InputObject `$FolderPermissions | ConvertTo-Html -Fragment | New-BootstrapTable"
    $FolderObjectsForTable = Select-FolderTableProperty -InputObject $FolderPermissions |
    Sort-Object -Property Folder

    $HtmlTable = $FolderObjectsForTable |
    ConvertTo-Html -Fragment |
    New-BootstrapTable

    $JsonData = $FolderObjectsForTable |
    ConvertTo-Json

    $JsonColumns = Get-FolderColumnJson -InputObject $FolderObjectsForTable
    $JsonTable = ConvertTo-BootstrapJavaScriptTable -Id 'Folders' -InputObject $FolderObjectsForTable -DataFilterControl -SearchableColumn 'Folder' -DropdownColumn 'Inheritance'

    return [pscustomobject]@{
        HtmlDiv     = $HtmlTable
        JsonDiv     = $JsonTable
        JsonData    = $JsonData
        JsonColumns = $JsonColumns
    }

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
        [string[]]$IgnoreDomain

    )

    # Convert the $ExcludeClass array into a dictionary for fast lookups
    $ClassExclusions = @{}
    ForEach ($ThisClass in $ExcludeClass) {
        $ClassExclusions[$ThisClass] = $true
    }

    $ShortestFolderPath = @($FolderPermissions.Name |
        Sort-Object)[0]

    ForEach ($ThisFolder in $FolderPermissions) {

        $ThisHeading = New-HtmlHeading "Accounts with access to $($ThisFolder.Name)" -Level 5

        $ThisSubHeading = Get-FolderPermissionTableHeader -ThisFolder $ThisFolder -ShortestFolderPath $ShortestFolderPath

        $FilterContents = @{}

        $FilteredAccounts = $ThisFolder.Group |
        Group-Object -Property Account |
        Where-Object -FilterScript {

            # On built-in groups like 'Authenticated Users' or 'Administrators' the SchemaClassName is null but we have an ObjectType instead.
            # TODO: Research where this difference came from, should these be normalized earlier in the process?
            # A user who was found by being a member of a local group not have an ObjectType (because they are not directly part of the AccessControlEntry)
            # They should have their parent group's AccessControlEntry there...do they?  Doesn't it have a Group ObjectType there?

            if ($_.Group.AccessControlEntry.ObjectType) {
                $Schema = @($_.Group.AccessControlEntry.ObjectType)[0]
            } else {
                $Schema = @($_.Group.SchemaClassName)[0]
                # ToDo: SchemaClassName is a real property but may not exist on all objects.  ObjectType is my own property.  Need to verify+test all usage of both for accuracy.
                # ToDo: Why is $_.Group.SchemaClassName 'user' for the local Administrators group and Authenticated Users group, and it is 'Group' for the TestPC\Owner user?
            }

            # Exclude the object whose classes were specified in the parameters
            $SchemaExclusionResult = if ($ExcludeClass.Count -gt 0) {
                $ClassExclusions[$Schema]
            }
            -not $SchemaExclusionResult -and

            # Exclude the objects whose names match the regular expressions specified in the parameters
            ![bool]$(
                ForEach ($RegEx in $ExcludeAccount) {
                    if ($_.Name -match $RegEx) {
                        $FilterContents[$_.Name] = $_
                        $true
                    }
                }
            )

        }

        # Bugfix #48 https://github.com/IMJLA/Export-Permission/issues/48
        # Sending a dummy object down the line to avoid errors
        # TODO: More elegant solution needed. Downstream code should be able to handle null input.
        # TODO: Why does this suppress errors, but the object never appears in the tables? NOTE: Suspect this is now resolved by using -AsArray on ConvertTo-Json (lack of this was causing single objects to not be an array therefore not be displayed)
        if ($null -eq $FilteredAccounts) {
            $FilteredAccounts = [pscustomobject]@{
                'Name'  = 'NoAccountsMatchingCriteria'
                'Group' = [pscustomobject]@{
                    'IdentityReference' = '.'
                    'Access'            = '.'

                    'Name'              = '.'
                    'Department'        = '.'
                    'Title'             = '.'
                }
            }
        }

        $ObjectsForFolderPermissionTable = Select-FolderPermissionTableProperty -InputObject $FilteredAccounts -IgnoreDomain $IgnoreDomain |
        Sort-Object -Property Name

        $ThisTable = $ObjectsForFolderPermissionTable |
        ConvertTo-Html -Fragment |
        New-BootstrapTable

        $TableId = $ThisFolder.Name -replace '[^A-Za-z0-9\-_:.]', '-'

        $ThisJsonTable = ConvertTo-BootstrapJavaScriptTable -Id "Perms_$TableId" -InputObject $ObjectsForFolderPermissionTable -DataFilterControl -AllColumnsSearchable

        # Remove spaces from property titles
        $ObjectsForJsonData = $ObjectsForFolderPermissionTable |
        Select-Object -Property Account,
        Access,
        @{
            Label      = 'DuetoMembershipIn'
            Expression = { $_.'Due to Membership In' }
        },
        @{
            Label      = 'SourceofAccess'
            Expression = { $_.'Source of Access' }
        },
        Name,
        Department,
        Title

        [pscustomobject]@{
            HtmlDiv     = New-BootstrapDiv -Text ($ThisHeading + $ThisSubHeading + $ThisTable)
            JsonDiv     = New-BootstrapDiv -Text ($ThisHeading + $ThisSubHeading + $ThisJsonTable)
            JsonData    = $ObjectsForJsonData | ConvertTo-Json -AsArray
            JsonColumns = Get-FolderColumnJson -InputObject $ObjectsForFolderPermissionTable -PropNames Account, Access,
            'Due to Membership In', 'Source of Access', Name, Department, Title
            Path        = $ThisFolder.Name
        }
    }
}
function Get-FolderPermissionTableHeader {
    [OutputType([System.String])]
    param (
        $ThisFolder,
        [string]$ShortestFolderPath
    )
    $Leaf = $ThisFolder.Name | Split-Path -Parent | Split-Path -Leaf -ErrorAction SilentlyContinue
    if ($Leaf) {
        $ParentLeaf = $Leaf
    } else {
        $ParentLeaf = $ThisFolder.Name | Split-Path -Parent
    }
    if ('' -ne $ParentLeaf) {
        if (@($ThisFolder.Group.FolderInheritanceEnabled)[0] -eq $true) {
            if ($ThisFolder.Name -eq $ShortestFolderPath) {
                return "Inherited permissions from the parent folder ($ParentLeaf) are included. This folder can only be accessed by the accounts listed below:"
            } else {
                return "Inheritance is enabled on this folder. Accounts with access to the parent folder and subfolders ($ParentLeaf) can access this folder. So can any accounts listed below:"
            }
        } else {
            return "Inheritance is disabled on this folder. Accounts with access to the parent folder and subfolders ($ParentLeaf) cannot access this folder unless they are listed below:"
        }
    } else {
        return "This is the top-level folder. It can only be accessed by the accounts listed below:"
    }
}
function Get-FolderTableHeader {
    param ($LevelsOfSubfolders)

    switch ($LevelsOfSubfolders ) {
        0 {
            'Includes the target folder only (option to report on subfolders was declined)'
        }
        -1 {
            'Includes the target folder and all subfolders with unique permissions'
        }
        default {
            "Includes the target folder and $LevelsOfSubfolders levels of subfolders with unique permissions"
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

        [string]$ReportInstanceId

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
Processed permissions for $ItemCount items$Size in $Duration<br />
Report instance: $ReportInstanceId
"@
    New-BootstrapAlert -Class Light -Text $Text
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
    param ($LevelsOfSubfolders)

    switch ($LevelsOfSubfolders ) {
        0 {
            'Does not include permissions on subfolders (option was declined)'
        }
        -1 {
            'Includes all subfolders with unique permissions (including ∞ levels of subfolders)'
        }
        default {
            "Includes all subfolders with unique permissions (down to $LevelsOfSubfolders levels of subfolders)"
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
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName)

    )

    Write-Progress -Activity 'Get-UniqueAdsiServerName' -CurrentOperation 'Initializing' -Status '0%' -PercentComplete 0

    $UniqueValues = @{}

    ForEach ($Value in $Known) {
        $UniqueValues[$Value] = $null
    }

    ForEach ($Value in $FilePath) {
        $UniqueValues[$Value] = $null
    }

    # Add server names from the ACL paths
    [int]$ProgressInterval = [math]::max(($Permissions.Count / 100), 1)
    $ProgressCounter = 0
    $i = 0

    ForEach ($ThisPath in $Permissions.SourceAccessList.Path) {
        $ProgressCounter++
        if ($ProgressCounter -eq $ProgressInterval) {
            $PercentComplete = $i / $Permissions.Count * 100
            Write-Progress -Activity 'Get-UniqueAdsiServerName' -CurrentOperation "Find-ServerNameInPath '$ThisPath'" -Status "$([int]$PercentComplete)%" -PercentComplete 50
            $ProgressCounter = 0
        }
        $i++ # increment $i after Write-Progress to show progress conservatively rather than optimistically
        $UniqueValues[(Find-ServerNameInPath -LiteralPath $ThisPath -ThisFqdn $ThisFqdn)] = $null
    }

    Write-Progress -Activity 'Get-UniqueAdsiServerName' -Completed

    return $UniqueValues.Keys

}
function Initialize-Cache {

    <# Use the list of known ADSI server FQDNs to populate six caches:
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
        [hashtable]$LogMsgCache = $Global:LogMessages

    )

    Write-Progress -Activity 'Initialize-Cache' -Status '0%' -CurrentOperation 'Initializing' -PercentComplete 0

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    if ($ThreadCount -eq 1) {

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
        }

        [int]$ProgressInterval = [math]::max(($ServerFqdns.Count / 100), 1)
        $ProgressCounter = 0
        $i = 0

        ForEach ($ThisServerName in $ServerFqdns) {
            $ProgressCounter++
            if ($ProgressCounter -eq $ProgressInterval) {
                $PercentComplete = $i / $ServerFqdns.Count * 100
                Write-Progress -Activity 'Initialize-Cache' -CurrentOperation "Get-AdsiServer '$ThisServerName'" -Status "$([int]$PercentComplete)%" -PercentComplete $PercentComplete
                $ProgressCounter = 0
            }
            $i++ # increment $i after Write-Progress to show progress conservatively rather than optimistically

            Write-LogMsg @LogParams -Text "Get-AdsiServer -Fqdn '$ThisServerName'"
            $null = Get-AdsiServer @GetAdsiServerParams -Fqdn $ThisServerName
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
            AddParam       = @{
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
            }

        }

        Write-LogMsg @LogParams -Text "Split-Thread -Command 'Get-AdsiServer' -InputParameter AdsiServer -InputObject @('$($ServerFqdns -join "',")')"
        $null = Split-Thread @GetAdsiServerParams

    }

    Write-Progress -Activity 'Initialize-Cache' -Completed

}
function Resolve-PermissionIdentity {

    param (

        # Permission objects from Get-FolderAccessList whose IdentityReference to resolve
        [Parameter(ValueFromPipeline)]
        [object[]]$Permission,

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Maximum number of concurrent threads to allow
        [int]$ThreadCount = (Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum,

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
        [hashtable]$LogMsgCache = $Global:LogMessages

    )

    Write-Progress -Activity 'Resolve-PermissionIdentity' -Status "0%" -CurrentOperation 'Initializing' -PercentComplete 0

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    if ($ThreadCount -eq 1) {

        $ResolveAceParams = @{
            DirectoryEntryCache    = $DirectoryEntryCache
            Win32AccountsBySID     = $Win32AccountsBySID
            Win32AccountsByCaption = $Win32AccountsByCaption
            DomainsBySID           = $DomainsBySID
            DomainsByNetbios       = $DomainsByNetbios
            DomainsByFqdn          = $DomainsByFqdn
            ThisHostName           = $ThisHostName
            ThisFqdn               = $ThisFqdn
            WhoAmI                 = $WhoAmI
            LogMsgCache            = $LogMsgCache
        }

        [int]$ProgressInterval = [math]::max(($Permission.Count / 100), 1)
        $ProgressCounter = 0
        $i = 0

        ForEach ($ThisPermission in $Permission) {

            $ProgressCounter++

            if ($ProgressCounter -eq $ProgressInterval) {

                $PercentComplete = $i / $Permission.Count * 100
                Write-Progress -Activity 'Resolve-PermissionIdentity' -Status "$([int]$PercentComplete)%" -CurrentOperation "Resolve-Ace $($ThisPermission.IdentityReference)" -PercentComplete $PercentComplete
                $ProgressCounter = 0

            }

            $i++ # increment $i after Write-Progress to show progress conservatively rather than optimistically
            $ResolveAceParams['InputObject'] = $ThisPermission
            Write-LogMsg @LogParams -Text "Resolve-Ace -InputObject $($ThisPermission.IdentityReference)"
            Resolve-Ace @ResolveAceParams

        }

    } else {

        $ResolveAceParams = @{

            Command              = 'Resolve-Ace'
            InputObject          = $Permission
            InputParameter       = 'InputObject'
            ObjectStringProperty = 'IdentityReference'
            TodaysHostname       = $ThisHostname
            #DebugOutputStream    = 'Debug'
            WhoAmI               = $WhoAmI
            LogMsgCache          = $LogMsgCache
            Threads              = $ThreadCount
            AddParam             = @{
                DirectoryEntryCache    = $DirectoryEntryCache
                Win32AccountsBySID     = $Win32AccountsBySID
                Win32AccountsByCaption = $Win32AccountsByCaption
                DomainsBySID           = $DomainsBySID
                DomainsByNetbios       = $DomainsByNetbios
                DomainsByFqdn          = $DomainsByFqdn
                ThisHostName           = $ThisHostName
                ThisFqdn               = $ThisFqdn
                WhoAmI                 = $WhoAmI
                LogMsgCache            = $LogMsgCache

            }

        }

        Write-LogMsg @LogParams -Text "Split-Thread -Command 'Resolve-Ace' -InputParameter InputObject -InputObject `$Permission -ObjectStringProperty 'IdentityReference' -DebugOutputStream 'Debug'"

        Split-Thread @ResolveAceParams

    }

    Write-Progress -Activity 'Resolve-PermissionIdentity' -Completed

}
function Select-FolderPermissionTableProperty {
    # For the HTML table
    param (
        $InputObject,
        $IgnoreDomain
    )
    ForEach ($Object in $InputObject) {
        $GroupString = ($Object.Group.IdentityReference | Sort-Object -Unique) -join ' ; '
        # ToDo: param to allow setting [self] instead of the objects own name for this property
        #if ($GroupString -eq $Object.Name) {
        #    $GroupString = '[self]'
        #} else {
        ForEach ($IgnoreThisDomain in $IgnoreDomain) {
            $GroupString = $GroupString -replace "$IgnoreThisDomain\\", ''
        }
        #}
        [pscustomobject]@{
            'Account'              = $Object.Name
            'Access'               = ($Object.Group | Sort-Object -Property IdentityReference -Unique).Access -join ' ; '
            'Due to Membership In' = $GroupString
            'Source of Access'     = ($Object.Group.AccessControlEntry.ACESource | Sort-Object -Unique) -join ' ; '
            'Name'                 = @($Object.Group.Name)[0]
            'Department'           = @($Object.Group.Department)[0]
            'Title'                = @($Object.Group.Title)[0]
        }
    }

}
function Select-FolderTableProperty {
    # For the HTML table
    param (
        $InputObject
    )
    $Culture = Get-Culture
    $InputObject | Select-Object -Property @{
        Label      = 'Folder'
        Expression = { $_.Name }
    },
    @{
        Label      = 'Inheritance'
        Expression = {
            $Culture.TextInfo.ToTitleCase(@($_.Group.FolderInheritanceEnabled)[0])
        }
    }
}
function Select-UniqueAccountPermission {

    param (

        # Objects output from Format-SecurityPrincipal ... | Group-Object -Property User
        [Parameter(ValueFromPipeline)]
        $AccountPermission,

        <#
        Domain(s) to ignore (they will be removed from the username)

        Intended when a user has matching SamAccountNames in multiple domains but you only want them to appear once on the report.

        Can also be used to remove all domains simply for brevity in the report.
        #>
        [string[]]$IgnoreDomain,

        # Hashtable will be used to deduplicate
        $KnownUsers = [hashtable]::Synchronized(@{})

    )
    process {

        ForEach ($ThisUser in $AccountPermission) {

            $ShortName = $ThisUser.Name
            ForEach ($IgnoreThisDomain in $IgnoreDomain) {
                $ShortName = $ShortName -replace "^$IgnoreThisDomain\\", ''
            }

            $ThisKnownUser = $null
            $ThisKnownUser = $KnownUsers[$ShortName]
            if ($null -eq $ThisKnownUser) {
                $KnownUsers[$ShortName] = [pscustomobject]@{
                    'Count' = $ThisUser.Group.Count
                    'Name'  = $ShortName
                    'Group' = $ThisUser.Group
                }
            } else {
                $KnownUsers[$ShortName] = [pscustomobject]@{
                    'Count' = $ThisKnownUser.Group.Count + $ThisUser.Group.Count
                    'Name'  = $ShortName
                    'Group' = $ThisKnownUser.Group + $ThisUser.Group
                }
            }
        }

    }
    end {
        $KnownUsers.Values
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

Export-ModuleMember -Function @('Expand-AcctPermission','Expand-Folder','Expand-PermissionIdentity','Export-FolderPermissionHtml','Export-RawPermissionCsv','Export-ResolvedPermissionCsv','Format-FolderPermission','Format-PermissionAccount','Format-TimeSpan','Get-FolderAccessList','Get-FolderBlock','Get-FolderColumnJson','Get-FolderPermissionsBlock','Get-FolderPermissionTableHeader','Get-FolderTableHeader','Get-HtmlBody','Get-HtmlReportFooter','Get-PrtgXmlSensorOutput','Get-ReportDescription','Get-TimeZoneName','Get-UniqueServerFqdn','Initialize-Cache','Resolve-PermissionIdentity','Select-FolderPermissionTableProperty','Select-FolderTableProperty','Select-UniqueAccountPermission','Update-CaptionCapitalization')





















































































































