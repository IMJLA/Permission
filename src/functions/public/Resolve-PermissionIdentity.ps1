function Resolve-PermissionIdentity {

    # Resolve identities in access control lists to their SIDs and NTAccount names

    param (

        # Cache of access control lists keyed by path
        [hashtable]$ACLsByPath = [hashtable]::Synchronized(@{}),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Maximum number of concurrent threads to allow
        [int]$ThreadCount = (Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum,

        # Cache of access control entries keyed by their resolved identities
        [hashtable]$ACEsByResolvedID = ([hashtable]::Synchronized(@{})),

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
        [int]$ProgressParentId

    )

    $Progress = @{
        Activity = 'Resolve-PermissionIdentity'
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
        CimCache               = $CimCache
        ACEsByResolvedID       = $ACEsByResolvedID
        ACLsByPath             = $ACLsByPath
        ACEPropertyName        = $ACEPropertyName
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
            Write-LogMsg @LogParams -Text "Resolve-Acl -InputObject '$ThisPath' -ACLsByPath `$ACLsByPath -ACEsByResolvedID `$ACEsByResolvedID"
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

        Write-LogMsg @LogParams -Text "Split-Thread -Command 'Resolve-Acl' -InputParameter InputObject -InputObject @('$($ACLsByPath.Keys -join "','")') -AddParam @{ACLsByPath=`$ACLsByPath;ACEsByResolvedID=`$ACEsByResolvedID}"
        Split-Thread @SplitThreadParams

    }

    Write-Progress @Progress -Completed

}
