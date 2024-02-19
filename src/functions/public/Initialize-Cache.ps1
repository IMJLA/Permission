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

    $GetAdsiServer = @{
        DirectoryEntryCache = $DirectoryEntryCache
        DomainsByFqdn       = $DomainsByFqdn
        DomainsByNetbios    = $DomainsByNetbios
        DomainsBySid        = $DomainsBySid
        ThisHostName        = $ThisHostName
        ThisFqdn            = $ThisFqdn
        WhoAmI              = $WhoAmI
        LogMsgCache         = $LogMsgCache
        CimCache            = $CimCache
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
            $null = Get-AdsiServer -Fqdn $ThisServerName @GetAdsiServer

        }

    } else {

        $SplitThread = @{
            Command        = 'Get-AdsiServer'
            InputObject    = $ServerFqdns
            InputParameter = 'Fqdn'
            TodaysHostname = $ThisHostname
            WhoAmI         = $WhoAmI
            LogMsgCache    = $LogMsgCache
            Timeout        = 600
            Threads        = $ThreadCount
            AddParam       = $GetAdsiServer
        }

        Write-LogMsg @LogParams -Text "Split-Thread -Command 'Get-AdsiServer' -InputParameter AdsiServer -InputObject @('$($ServerFqdns -join "',")')"
        $null = Split-Thread @SplitThread

    }

    Write-Progress @Progress -Completed

}
