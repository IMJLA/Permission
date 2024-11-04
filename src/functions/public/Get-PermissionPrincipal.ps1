function Get-PermissionPrincipal {

    param (

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [String]$DebugOutputStream = 'Debug',

        # Maximum number of concurrent threads to allow
        [int]$ThreadCount = (Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum,

        # Cache of security principals keyed by resolved identity reference. END STATE
        [Hashtable]$PrincipalByID = ([Hashtable]::Synchronized(@{})),

        # Cache of access control entries keyed by their resolved identities. STARTING STATE
        [Hashtable]$ACEsByResolvedID = ([Hashtable]::Synchronized(@{})),

        # Cache of CIM sessions and instances to reduce connections and queries
        [Hashtable]$CimCache = ([Hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to a thread-safe dictionary with string keys and object values
        #>
        [ref]$DirectoryEntryCache = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [ref]$DomainsByNetbios = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [ref]$DomainsBySid = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName,AdsiProvider,Win32Accounts properties as values
        [ref]$DomainsByFqdn = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [String]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [String]$ThisHostName = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [String]$WhoAmI = (whoami.EXE),

        # Log messages which have not yet been written to disk
        [Hashtable]$LogBuffer = ([Hashtable]::Synchronized(@{})),

        <#
        Do not get group members (only report the groups themselves)

        Note: By default, the -ExcludeClass parameter will exclude groups from the report.
          If using -NoGroupMembers, you most likely want to modify the value of -ExcludeClass.
          Remove the 'group' class from ExcludeClass in order to see groups on the report.
        #>
        [switch]$NoGroupMembers,

        # ID of the parent progress bar under which to show progress
        [int]$ProgressParentId,

        # The current domain
        # Can be passed as a parameter to reduce calls to Get-CurrentDomain
        [String]$CurrentDomain = (Get-CurrentDomain)

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
    Write-Progress @Progress -Status "0% (identity 0 of $Count) ConvertFrom-IdentityReferenceResolved" -CurrentOperation 'Initialize' -PercentComplete 0

    $Log = @{
        Buffer       = $LogBuffer
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $ADSIConversionParams = @{
        DirectoryEntryCache = $DirectoryEntryCache
        DomainsBySID        = $DomainsBySID
        DomainsByNetbios    = $DomainsByNetbios
        DomainsByFqdn       = $DomainsByFqdn
        ThisHostName        = $ThisHostName
        ThisFqdn            = $ThisFqdn
        WhoAmI              = $WhoAmI
        LogBuffer           = $LogBuffer
        CimCache            = $CimCache
        DebugOutputStream   = $DebugOutputStream
        PrincipalByID       = $PrincipalByID # end state
        ACEsByResolvedID    = $ACEsByResolvedID # start state
        CurrentDomain       = $CurrentDomain
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
            Write-LogMsg @Log -Text "ConvertFrom-IdentityReferenceResolved -IdentityReference '$ThisID'" -Expand $ADSIConversionParams
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
            LogBuffer            = $LogBuffer
            Threads              = $ThreadCount
            ProgressParentId     = $Progress['Id']
            AddParam             = $ADSIConversionParams
        }

        Write-LogMsg @Log -Text 'Split-Thread' -Expand $SplitThreadParams
        Split-Thread @SplitThreadParams

    }

    Write-Progress @Progress -Completed

}
