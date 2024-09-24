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
        [string[]]$Fqdn,

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [String]$DebugOutputStream = 'Debug',

        # Maximum number of concurrent threads to allow
        [int]$ThreadCount = (Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum,

        # Cache of CIM sessions and instances to reduce connections and queries
        [Hashtable]$CimCache = ([Hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [Hashtable]$DirectoryEntryCache = ([Hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [Hashtable]$DomainsByNetbios = ([Hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [Hashtable]$DomainsBySid = ([Hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName,AdsiProvider,Win32Accounts properties as values
        [Hashtable]$DomainsByFqdn = ([Hashtable]::Synchronized(@{})),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [String]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [String]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [String]$WhoAmI = (whoami.EXE),

        # Log messages which have not yet been written to disk
        [Hashtable]$LogBuffer = ([Hashtable]::Synchronized(@{})),

        # ID of the parent progress bar under which to show progress
        [int]$ProgressParentId,

        # Output from Get-KnownSidHashTable
        [hashtable]$WellKnownSIDBySID = (Get-KnownSidHashTable)

    )

    $Progress = @{
        Activity = 'Initialize-Cache'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $ProgressId = $ProgressParentId + 1
    } else {
        $ProgressId = 0
    }

    $Progress['Id'] = $ProgressId
    $Count = $Fqdn.Count

    $Log = @{
        Buffer       = $LogBuffer
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $WellKnownSIDByName = @{}
    ForEach ($KnownSID in $KnownSIDs.Keys) {
        $Known = $KnownSIDs[$KnownSID]
        $WellKnownSIDByName[$Known['Name']] = $Known
    }

    $GetAdsiServer = @{
        DirectoryEntryCache = $DirectoryEntryCache
        DomainsByFqdn       = $DomainsByFqdn
        DomainsByNetbios    = $DomainsByNetbios
        DomainsBySid        = $DomainsBySid
        ThisHostName        = $ThisHostName
        ThisFqdn            = $ThisFqdn
        WhoAmI              = $WhoAmI
        LogBuffer           = $LogBuffer
        CimCache            = $CimCache
        WellKnownSIDBySID   = $WellKnownSIDBySID
        WellKnownSIDByName  = $WellKnownSIDByName
    }

    if ($ThreadCount -eq 1) {

        $i = 0

        ForEach ($ThisServerName in $Fqdn) {

            [int]$PercentComplete = $i / $Count * 100
            Write-Progress -Status "$PercentComplete% (FQDN $($i + 1) of $Count) Get-AdsiServer" -CurrentOperation "Get-AdsiServer '$ThisServerName'" -PercentComplete $PercentComplete @Progress
            $i++ # increment $i after Write-Progress to show progress conservatively rather than optimistically
            Write-LogMsg @Log -Text "Get-AdsiServer -Fqdn '$ThisServerName'"
            $null = Get-AdsiServer -Fqdn $ThisServerName @GetAdsiServer

        }

    } else {

        $SplitThread = @{
            Command          = 'Get-AdsiServer'
            InputObject      = $Fqdn
            InputParameter   = 'Fqdn'
            TodaysHostname   = $ThisHostname
            WhoAmI           = $WhoAmI
            LogBuffer        = $LogBuffer
            Timeout          = 600
            Threads          = $ThreadCount
            ProgressParentId = $ProgressParentId
            AddParam         = $GetAdsiServer
        }

        Write-LogMsg @Log -Text "Split-Thread -Command 'Get-AdsiServer' -InputParameter AdsiServer -InputObject @('$($Fqdn -join "',")')"
        $null = Split-Thread @SplitThread

    }

    Write-Progress @Progress -Completed

}
