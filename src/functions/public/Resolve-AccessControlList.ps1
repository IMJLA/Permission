function Resolve-AccessControlList {

    # Wrapper to multithread Resolve-Acl
    # Resolve identities in access control lists to their SIDs and NTAccount names

    param (

        # Cache of access control lists keyed by path
        [Hashtable]$ACLsByPath = [Hashtable]::Synchronized(@{}),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [String]$DebugOutputStream = 'Debug',

        # Maximum number of concurrent threads to allow
        [int]$ThreadCount = (Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum,

        # Cache of access control entries keyed by GUID generated in this function
        [Hashtable]$ACEsByGUID = ([Hashtable]::Synchronized(@{})),

        # Cache of access control entry GUIDs keyed by their resolved identities
        [Hashtable]$AceGUIDsByResolvedID = ([Hashtable]::Synchronized(@{})),

        # Cache of access control entry GUIDs keyed by their paths
        [Hashtable]$AceGUIDsByPath = ([Hashtable]::Synchronized(@{})),

        # Cache of CIM sessions and instances to reduce connections and queries
        [Hashtable]$CimCache = ([Hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [Hashtable]$DirectoryEntryCache = ([Hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName,AdsiProvider,Win32Accounts properties as values
        [Hashtable]$DomainsByFqdn = ([Hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [Hashtable]$DomainsByNetbios = ([Hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [Hashtable]$DomainsBySid = ([Hashtable]::Synchronized(@{})),

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

    $Log = @{
        Buffer       = $LogBuffer
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $ACEPropertyName = $ACLsByPath.Values.Access[0].PSObject.Properties.GetEnumerator().Name

    $ResolveAclParams = @{
        DirectoryEntryCache     = $DirectoryEntryCache
        DomainsBySID            = $DomainsBySID
        DomainsByNetbios        = $DomainsByNetbios
        DomainsByFqdn           = $DomainsByFqdn
        ThisHostName            = $ThisHostName
        ThisFqdn                = $ThisFqdn
        WhoAmI                  = $WhoAmI
        LogBuffer               = $LogBuffer
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
            #Write-LogMsg @Log -Text "Resolve-Acl -InputObject '$ThisPath' -ACLsByPath `$ACLsByPath -ACEsByGUID `$ACEsByGUID"
            Resolve-Acl -ItemPath $ThisPath @ResolveAclParams

        }

    } else {

        $SplitThreadParams = @{
            Command          = 'Resolve-Acl'
            InputObject      = $Paths
            InputParameter   = 'ItemPath'
            TodaysHostname   = $ThisHostname
            WhoAmI           = $WhoAmI
            LogBuffer        = $LogBuffer
            Threads          = $ThreadCount
            ProgressParentId = $Progress['Id']
            AddParam         = $ResolveAclParams
            #DebugOutputStream    = 'Debug'
        }

        Write-LogMsg @Log -Text "Split-Thread -Command 'Resolve-Acl' -InputParameter InputObject -InputObject @('$($ACLsByPath.Keys -join "','")') -AddParam @{ACLsByPath=`$ACLsByPath;ACEsByGUID=`$ACEsByGUID}"
        Split-Thread @SplitThreadParams

    }

    Write-Progress @Progress -Completed

}
