function Get-PermissionPrincipal {

    param (

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Maximum number of concurrent threads to allow
        [int]$ThreadCount = (Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum,

        # Thread-safe hashtable to use for caching directory entries and avoiding duplicate directory queries. END STATE
        [hashtable]$ACEsByPrincipal = ([hashtable]::Synchronized(@{})),

        # Cache of access control entries keyed by their resolved identities. STARTING STATE
        [hashtable]$ACEbyResolvedIDCache = ([hashtable]::Synchronized(@{})),

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
        [int]$ProgressParentId

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

    $Count = $ACEbyResolvedIDCache.Keys.Count
    Write-Progress @Progress -Status "0% (identity 0 of $Count)" -CurrentOperation 'Initialize' -PercentComplete 0

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $ADSIConversionParams = @{
        DirectoryEntryCache  = $DirectoryEntryCache
        DomainsBySID         = $DomainsBySID
        DomainsByNetbios     = $DomainsByNetbios
        DomainsByFqdn        = $DomainsByFqdn
        ThisHostName         = $ThisHostName
        ThisFqdn             = $ThisFqdn
        WhoAmI               = $WhoAmI
        LogMsgCache          = $LogMsgCache
        CimCache             = $CimCache
        DebugOutputStream    = $DebugOutputStream
        ACEsByPrincipal      = $ACEsByPrincipal # end state
        ACEbyResolvedIDCache = $ACEbyResolvedIDCache # start state
    }

    if ($ThreadCount -eq 1) {

        if ($NoGroupMembers) {
            $ADSIConversionParams['NoGroupMembers'] = $true
        }

        [int]$ProgressInterval = [math]::max(($Count / 100), 1)
        $IntervalCounter = 0
        $i = 0

        ForEach ($ResolvedIdentityReferenceString in $ACEbyResolvedIDCache.Keys) {

            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {

                [int]$PercentComplete = $i / $Count * 100
                Write-Progress @Progress -Status "$PercentComplete% (identity $($i + 1) of $Count)" -CurrentOperation "ConvertFrom-IdentityReferenceResolved for '$($ThisID.Name)'" -PercentComplete $PercentComplete
                $IntervalCounter = 0

            }

            $i++
            Write-LogMsg @LogParams -Text "ConvertFrom-IdentityReferenceResolved -IdentityReference $ResolvedIdentityReferenceString"
            ConvertFrom-IdentityReferenceResolved -IdentityReference $ResolvedIdentityReferenceString @ADSIConversionParams

        }

    } else {

        if ($NoGroupMembers) {
            $ADSIConversionParams['AddSwitch'] = 'NoGroupMembers'
        }

        $SplitThreadParams = @{
            Command              = 'ConvertFrom-IdentityReferenceResolved'
            InputObject          = $ACEbyResolvedIDCache.Keys
            InputParameter       = 'IdentityReference'
            ObjectStringProperty = 'Name'
            TodaysHostname       = $ThisHostname
            WhoAmI               = $WhoAmI
            LogMsgCache          = $LogMsgCache
            Threads              = $ThreadCount
            AddParam             = $ADSIConversionParams
        }

        Write-LogMsg @LogParams -Text "Split-Thread -Command 'ConvertFrom-IdentityReferenceResolved' -InputParameter 'IdentityReference' -InputObject `$ACEbyResolvedIDCache.Keys"
        Split-Thread @SplitThreadParams

    }

    Write-Progress @Progress -Completed

}
