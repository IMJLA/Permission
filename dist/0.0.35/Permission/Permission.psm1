
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
        [string]$TodaysHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages

    )

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $TodaysHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    if ($ThreadCount -eq 1 -or @($Folder).Count -eq 1) {

        $i = 0
        ForEach ($ThisFolder in $Folder) {
            $PercentComplete = $i / $Folder.Count
            Write-Progress -Activity "Get-Subfolder" -CurrentOperation $ThisFolder -PercentComplete $PercentComplete
            $i++
            $Subfolders = $null
            $Subfolders = Get-Subfolder -TargetPath $ThisFolder -FolderRecursionDepth $LevelsOfSubfolders -ErrorAction Continue
            Write-LogMsg @LogParams -Text "# Folders (including parent): $($Subfolders.Count + 1) for '$ThisFolder'"
            $Subfolders
        }
        Write-Progress -Activity "Get-Subfolder" -Completed

    } else {

        $GetSubfolder = @{
            Command           = 'Get-Subfolder'
            InputObject       = $Folder
            InputParameter    = 'TargetPath'
            DebugOutputStream = $DebugOutputStream
            TodaysHostname    = $TodaysHostname
            WhoAmI            = $WhoAmI
            LogMsgCache       = $LogMsgCache
            Threads           = $ThreadCount
        }
        Split-Thread @GetSubfolder

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
        [string]$DebugOutputStream = 'Silent',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$TodaysHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages

    )

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $TodaysHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    # We expect a small number of folders and a large number of subfolders
    # We will multithread the subfolders but not the folders
    # Multithreading overhead actually hurts performance for such a fast operation (Get-FolderAce) on a small number of items
    $i = 0
    ForEach ($ThisFolder in $Folder) {
        $PercentComplete = $i / $Folder.Count
        Write-Progress -Activity "Get-FolderAce -IncludeInherited" -CurrentOperation $ThisFolder -PercentComplete $PercentComplete
        $i++
        Get-FolderAce -LiteralPath $ThisFolder -IncludeInherited
    }
    Write-Progress -Activity "Get-FolderAce -IncludeInherited" -Completed

    if ($ThreadCount -eq 1) {

        $i = 0
        ForEach ($ThisFolder in $Subfolder) {
            $PercentComplete = $i / $Subfolder.Count
            Write-Progress -Activity "Get-FolderAce" -CurrentOperation $ThisFolder -PercentComplete $PercentComplete
            $i++
            Get-FolderAce -LiteralPath $ThisFolder
        }
        Write-Progress -Activity "Get-FolderAce" -Completed

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
        }
        Split-Thread @GetFolderAce

    }
}
function Get-FolderPermissionsBlock {
    param (
        $FolderPermissions,

        # Regular expressions matching names of Users or Groups to exclude from the Html report
        [string[]]$ExcludeAccount,

        $ExcludeEmptyGroups,

        <#
        Domain(s) to ignore (they will be removed from the username)

        Intended when a user has matching SamAccountNames in multiple domains but you only want them to appear once on the report.

        Can also be used to remove all domains simply for brevity in the report.
        #>
        [string[]]$IgnoreDomain

    )

    $ShortestFolderPath = $ThisFolder.Name |
    Sort-Object |
    Select-Object -First 1

    ForEach ($ThisFolder in $FolderPermissions) {

        $ThisHeading = New-HtmlHeading "Accounts with access to $($ThisFolder.Name)" -Level 5

        $Leaf = $ThisFolder.Name | Split-Path -Parent | Split-Path -Leaf -ErrorAction SilentlyContinue

        if ($Leaf) {
            $ParentLeaf = $Leaf
        } else {
            $ParentLeaf = $ThisFolder.Name | Split-Path -Parent
        }
        if ('' -ne $ParentLeaf) {
            if (($ThisFolder.Group.FolderInheritanceEnabled | Select-Object -First 1) -eq $true) {
                if ($ThisFolder.Name -eq $ShortestFolderPath) {
                    $ThisSubHeading = "Inherited permissions from the parent folder ($ParentLeaf) are included.  This folder can only be accessed by the users listed below:"
                } else {
                    $ThisSubHeading = "Accounts with access to the parent folder and subfolders ($ParentLeaf) can access this folder. So can any users listed below:"
                }
            } else {
                $ThisSubHeading = "Accounts with access to the parent folder and subfolders ($ParentLeaf) cannot access this folder unless they are listed below:"
            }
        } else {
            $ThisSubHeading = "This is the top-level folder. It can only be accessed by the users listed below:"
        }

        $FilteredAccounts = $ThisFolder.Group |
        Group-Object -Property Account |
        # Skip the accounts we need to skip
        Where-Object -FilterScript {
            ![bool]$(
                ForEach ($RegEx in $ExcludeAccount) {
                    if ($_.Name -match $RegEx) {
                        $true
                    }
                }
            )
        }

        # Exclude groups with members (the group will be reflected on the report with its members)
        $FilteredAccounts = $FilteredAccounts |
        Where-Object -FilterScript {
            -not (
                $_.Group.SchemaClassName -contains 'group' -and
                $null -eq $_.Group.IdentityReference
            )
        }

        if ($ExcludeEmptyGroups) {
            $FilteredAccounts = $FilteredAccounts |
            Where-Object -FilterScript {
                # Eliminate empty groups (not useful to see in the middle of a list of users/job titles/departments/etc).
                $_.Group.SchemaClassName -notcontains 'group'
            }
        }

        $ThisTable = $FilteredAccounts |
        Select-Object -Property @{Label = 'Account'; Expression = { $_.Name } },
        @{Label = 'Access'; Expression = { ($_.Group | Sort-Object -Property IdentityReference -Unique).Access -join ' ; ' } },
        @{Label = 'Due to Membership In'; Expression = {
                $GroupString = ($_.Group.IdentityReference | Sort-Object -Unique) -join ' ; '
                ForEach ($IgnoreThisDomain in $IgnoreDomain) {
                    $GroupString = $GroupString -replace "$IgnoreThisDomain\\", ''
                }
                $GroupString
            }
        },
        @{Label = 'Name'; Expression = { $_.Group.Name | Sort-Object -Unique } },
        @{Label = 'Department'; Expression = { $_.Group.Department | Sort-Object -Unique } },
        @{Label = 'Title'; Expression = { $_.Group.Title | Sort-Object -Unique } } |
        Sort-Object -Property Name |
        ConvertTo-Html -Fragment |
        New-BootstrapTable

        New-BootstrapDiv -Text ($ThisHeading + $ThisSubHeading + $ThisTable)
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
    $StartTime = $FinishTime.AddTicks(-$FinishTime.ElapsedTicks)
    $TimeZoneName = Get-TimeZoneName -Time $FinishTime
    $Duration = Format-TimeSpan -TimeSpan $StopWatch.Elapsed
    if ($TotalBytes) {
        $Size = " ($($TotalBytes / 1TB) TiB"
    }
    $Text = @"
Report generated by $WhoAmI on $ThisFQDN starting at $StartTime and ending at $FinishTime $TimeZoneName<br />
Processed permissions for $ItemCount items$Size in $Duration<br />
Report instance: $ReportInstanceId)
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
function Select-FolderTableProperty {
    param (
        $InputObject
    )
    $InputObject | Select-Object -Property @{
        Label      = 'Folder'
        Expression = { $_.Name }
    },
    @{
        Label      = 'Inheritance'
        Expression = { $_.Group.FolderInheritanceEnabled | Select-Object -First 1 }
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

Export-ModuleMember -Function @('Expand-Folder','Format-TimeSpan','Get-FolderAccessList','Get-FolderPermissionsBlock','Get-FolderTableHeader','Get-HtmlBody','Get-HtmlReportFooter','Get-PrtgXmlSensorOutput','Get-ReportDescription','Get-TimeZoneName','Select-FolderTableProperty','Select-UniqueAccountPermission','test','Update-CaptionCapitalization')


































