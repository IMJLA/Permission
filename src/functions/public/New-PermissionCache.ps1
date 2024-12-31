function New-PermissionCache {

    <#
    Create an in-process cache to reduce calls to other processes, disk, or network, and to store repetitive parameters for better readability of code and logs.
    #>

    param(

        <#
        Number of asynchronous threads to use
        Recommended starting with the # of logical CPUs:
        (Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum
        #>
        [uint16]$ThreadCount = 1,

        # Path to the folder to save the logs and reports generated by this script
        [string]$OutputDir = "$env:AppData\Export-Permission",

        [string]$TranscriptFile

    )

    # Get the hostname of the computer running the script.
    $ThisHostname = HOSTNAME.EXE
    $WhoAmI = Get-PermissionWhoAmI -ThisHostname $ThisHostname
    $ProgressParentId = 0
    $Culture = Get-Culture
    $LogType = 'Debug'
    $LogCacheMap = @{ 'Cache' = '$Cache' }
    $LogAnalysisMap = @{ 'Cache' = '$Cache' ; 'Analysis' = '$PermissionAnalysis' ; 'Permission' = '$Permissions' }
    $LogWellKnownMap = @{ 'Cache' = '$Cache' ; 'CachedWellKnownSID' = '$CachedWellKnownSID' ; 'AceGuid' = '$AceGuids' }
    $LogStopWatchMap = @{ 'Cache' = '$Cache' ; 'StopWatch' = '$StopWatch' ; 'Analysis' = '$PermissionAnalysis' ; 'Permission' = '$Permissions' ; 'FormattedPermission' = '$FormattedPermissions' }
    $LogCimMap = @{ 'Cache' = '$Cache' ; 'CimSession' = '$CimSession' }
    $LogFormattedMap = @{ 'FormattedPermission' = '$FormattedPermissions' ; 'Analysis' = '$PermissionAnalysis' }
    $LogDirEntryMap = @{ 'Cache' = '$Cache' ; 'DirectoryEntry' = '$DirectoryEntry' ; 'AceGuid' = '$AceGuids' }
    $LogSourcePathMap = @{ 'Cache' = '$Cache' ; 'TargetPath' = '$Items' }
    $LogEmptyMap = @{}
    $ParamStringMap = Get-ParamStringMap
    $LogBuffer = [System.Collections.Concurrent.ConcurrentQueue[System.Collections.Specialized.OrderedDictionary]]::new()

    $Log = @{
        'Type'         = $LogType
        'ThisHostname' = $ThisHostname
        'Buffer'       = ([ref]$LogBuffer)
        'ExpandKeyMap' = $LogEmptyMap
    }

    # These events already happened but we will log them now that we have the correct capitalization of the user.
    Write-LogMsg -Text '$StopWatch = [System.Diagnostics.Stopwatch]::new() ; $StopWatch.Start() # This command was already run but is now being logged' @Log
    Write-LogMsg -Text "New-Item -ItemType Directory -Path '$OutputDir' -ErrorAction SilentlyContinue # This command was already run but is now being logged" @Log
    Write-LogMsg -Text "Start-Transcript -Path '$TranscriptFile' # This command was already run but is now being logged" @Log
    Write-LogMsg -Text 'HOSTNAME.EXE # This command was already run but is now being logged' @Log
    Write-LogMsg -Text "Get-PermissionWhoAmI -ThisHostName '$ThisHostname' # This command was already run but is now being logged" @Log
    $Boolean = [type]'String'
    $String = [type]'String'
    $GuidList = [type]'System.Collections.Generic.List[Guid]'
    $StringArray = [type]'String[]'
    $StringList = [type]'System.Collections.Generic.List[String]'
    $Object = [type]'Object'
    $PSCustomObject = [type]'PSCustomObject'
    $DirectoryInfo = [type]'System.IO.DirectoryInfo'
    $PSReference = [type]'ref'
    $WellKnownSidBySid = Get-KnownSidHashTable
    $WellKnownSidByName = Get-KnownSidByName -WellKnownSIDBySID $WellKnownSidBySid
    $WellKnownSidByCaption = Get-KnownCaptionHashTable -WellKnownSidBySid $WellKnownSidBySid

    # String translations indexed by value in the [System.Security.AccessControl.InheritanceFlags] enum
    # Parameter default value is on a single line as a workaround to a PlatyPS bug
    # TODO: Move to i18n
    $InheritanceFlagResolved = @('this folder but not subfolders', 'this folder and subfolders', 'this folder and files, but not subfolders', 'this folder, subfolders, and files')

    <#
    $CimCache
        Key is a String
        Value is a dict
            Key is a String
            Value varies (CimSession or dict)
    #>

    return [hashtable]::Synchronized(@{
            'AceByGUID'                    = New-PermissionCacheRef -Key $String -Value $Object #hashtable Initialize a cache of access control entries keyed by GUID generated in Resolve-ACE.
            'AceGuidByID'                  = New-PermissionCacheRef -Key $String -Value $GuidList #hashtable Initialize a cache of access control entry GUIDs keyed by their resolved NTAccount captions.
            'AceGuidByPath'                = New-PermissionCacheRef -Key $String -Value $GuidList #hashtable Initialize a cache of access control entry GUIDs keyed by their paths.
            'AclByPath'                    = New-PermissionCacheRef -Key $String -Value $PSCustomObject #hashtable Initialize a cache of access control lists keyed by their paths.
            'CimCache'                     = New-PermissionCacheRef -Key $String -Value $PSReference #hashtable Initialize a cache of CIM sessions, instances, and query results.
            'Culture'                      = [ref]$Culture
            'DirectoryEntryByPath'         = New-PermissionCacheRef -Key $String -Value $Object #DirectoryEntryCache Initialize a cache of ADSI directory entry keyed by their Path to minimize ADSI queries.
            'DomainBySID'                  = New-PermissionCacheRef -Key $String -Value $Object #DomainsBySID Initialize a cache of directory domains keyed by domain SID to minimize CIM and ADSI queries.
            'DomainByNetbios'              = New-PermissionCacheRef -Key $String -Value $Object #DomainsByNetbios Initialize a cache of directory domains keyed by domain NetBIOS to minimize CIM and ADSI queries.
            'DomainByFqdn'                 = New-PermissionCacheRef -Key $String -Value $Object #DomainsByFqdn Initialize a cache of directory domains keyed by domain DNS FQDN to minimize CIM and ADSI queries.
            'ExcludeAccountFilterContents' = New-PermissionCacheRef -Key $String -Value $Boolean #hashtable Initialize a cache of accounts filtered by the ExcludeAccount parameter.
            'ExcludeClassFilterContents'   = New-PermissionCacheRef -Key $String -Value $Boolean #hashtable Initialize a cache of accounts filtered by the ExcludeClass parameter.
            'IdByShortName'                = New-PermissionCacheRef -Key $String -Value $StringList #hashtable Initialize a cache of resolved NTAccount captions keyed by their short names (results of the IgnoreDomain parameter).
            'IncludeAccountFilterContents' = New-PermissionCacheRef -Key $String -Value $Boolean #hashtable Initialize a cache of accounts filtered by the IncludeAccount parameter.
            'InheritanceFlagResolved'      = [ref]$InheritanceFlagResolved
            'Log'                          = [ref]$Log
            'LogBuffer'                    = [ref]$LogBuffer # Initialize a cache of log messages in memory to minimize random disk access.
            'LogEmptyMap'                  = [ref]$LogEmptyMap
            'LogCacheMap'                  = [ref]$LogCacheMap
            'LogAnalysisMap'               = [ref]$LogAnalysisMap
            'LogSourcePathMap'             = [ref]$LogSourcePathMap
            'LogFormattedMap'              = [ref]$LogFormattedMap
            'LogStopWatchMap'              = [ref]$LogStopWatchMap
            'LogCimMap'                    = [ref]$LogCimMap
            'LogDirEntryMap'               = [ref]$LogDirEntryMap
            'LogWellKnownMap'              = [ref]$LogWellKnownMap
            'LogType'                      = [ref]$LogType
            'ParamStringMap'               = [ref]$ParamStringMap
            'ParentBySourcePath'           = New-PermissionCacheRef -Key $DirectoryInfo -Value $StringArray #hashtable Initialize a cache of resolved parent item paths keyed by their unresolved target paths.
            'PrincipalByID'                = New-PermissionCacheRef -Key $String -Value $PSCustomObject #hashtable Initialize a cache of ADSI security principals keyed by their resolved NTAccount caption.
            'ProgressParentId'             = [ref]$ProgressParentId
            'ShortNameByID'                = New-PermissionCacheRef -Key $String -Value $String  #hashtable Initialize a cache of short names (results of the IgnoreDomain parameter) keyed by their resolved NTAccount captions.
            'ThisFqdn'                     = [ref]''
            'ThisHostname'                 = [ref]$ThisHostname
            'ThreadCount'                  = [ref]$ThreadCount
            'WellKnownSidByCaption'        = [ref]$WellKnownSidByCaption
            'WellKnownSidByName'           = [ref]$WellKnownSidByName
            'WellKnownSidBySid'            = [ref]$WellKnownSidBySid
            'WhoAmI'                       = [ref]$WhoAmI
        })

}
