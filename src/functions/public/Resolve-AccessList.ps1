function Resolve-AccessList {

    <#
    Resolve and expand the identities in access control lists to the accounts they represent

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

        # Permission objects from Get-FolderAccessList whose IdentityReference to resolve
        [Parameter(ValueFromPipeline)]
        [object[]]$AccessList,

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

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName,AdsiProvider,Win32Accounts properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Cache of known Win32_Account instances keyed by domain and SID
        [hashtable]$Win32AccountsBySID = ([hashtable]::Synchronized(@{})),

        # Cache of known Win32_Account instances keyed by domain (e.g. CONTOSO) and Caption (NTAccount name e.g. CONTOSO\User1)
        [hashtable]$Win32AccountsByCaption = ([hashtable]::Synchronized(@{})),

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
        [string[]]$InheritanceFlagResolved = @(
            'this folder but not subfolders',
            'this folder and subfolders',
            'this folder and files, but not subfolders',
            'this folder, subfolders, and files'
        )

    )

    # Create a splat of the progress parameters for code readability
    $Progress = @{
        Activity = 'Resolve-AccessList'
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

    $Count = $AccessList.Count
    Write-Progress @Progress -Status "0% (permission 0 of $Count)" -CurrentOperation 'Initializing' -PercentComplete 0

    # Create a splat of constant Write-LogMsg parameters for code readability
    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    # Create a splat of log-related parameters to pass to various functions for code readability
    $LoggingParams = @{
        ThisHostname = $ThisHostname
        LogMsgCache  = $LogCache
        WhoAmI       = $WhoAmI
    }

    # Create a splat of caching-related parameters to pass to various functions for code readability
    $CacheParams = @{
        Win32AccountsBySID      = $Win32AccountsBySID
        Win32AccountsByCaption  = $Win32AccountsByCaption
        DirectoryEntryCache     = $DirectoryEntryCache
        DomainsByFqdn           = $DomainsByFqdn
        DomainsByNetbios        = $DomainsByNetbios
        DomainsBySid            = $DomainsBySid
        ThisFqdn                = $ThisFqdn
        ThreadCount             = $ThreadCount
        InheritanceFlagResolved = $InheritanceFlagResolved
    }

    # The resolved name will include the domain name (or local computer name for local accounts)
    Write-Progress -Status '35% (step 8 of 20)' -CurrentOperation 'Resolve identities in access control lists to their SIDs and NTAccount names' -PercentComplete 35 @Progress
    Write-LogMsg @LogParams -Text '$PermissionsWithResolvedIdentities = Resolve-PermissionIdentity -Permission $Permissions'
    $PermissionsWithResolvedIdentities = Resolve-PermissionIdentity -CimCache $CimCache @LoggingParams @CacheParams -Permission $Permissions @ProgressParent



    Write-Progress @Progress -Completed

}
