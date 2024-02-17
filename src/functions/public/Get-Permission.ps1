function Get-Permission {

  # Get detailed info about permissions and the accounts with them

  <#
    Get-FolderAccessList
      Get-FolderAce
    Resolve-AccessList (foreach AccessControlEntry)
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

    # Path to the item whose permissions to export (inherited ACEs will be included)
    $Folder,

    # Path to the subfolders whose permissions to report (inherited ACEs will be skipped)
    $Subfolder,

    # Number of asynchronous threads to use
    [uint16]$ThreadCount = ((Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum),

    # Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module
    [string]$DebugOutputStream = 'Debug',

    # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
    [string]$ThisHostname = (HOSTNAME.EXE),

    <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
    [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

    # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
    [string]$WhoAmI = (whoami.EXE),

    # Cache of CIM sessions and instances to reduce connections and queries
    [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

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

    # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
    [hashtable]$LogMsgCache = $Global:LogMessages,

    # Thread-safe cache of items and their owners
    [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]$OwnerCache = [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]::new(),

    # ID of the parent progress bar under which to show progres
    [int]$ProgressParentId,

    [string[]]$KnownFqdn,

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
    Activity = 'Get-Permission'
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

  # Create a splat of the child progress bar ID to pass to various functions for code readability
  $ChildProgress = @{
    ProgressParentId = $ProgressId
  }

  # Create a splat of the ThreadCount parameter to pass to various functions for code readability
  $Threads = @{
    ThreadCount = $ThreadCount
  }

  # Create a splat of log-related parameters to pass to various functions for code readability
  $LoggingParams = @{
    ThisHostname = $ThisHostname
    LogMsgCache  = $LogCache
    WhoAmI       = $WhoAmI
  }

  # Create a splat of caching-related parameters to pass to various functions for code readability
  $CacheParams = @{
    Win32AccountsBySID     = $Win32AccountsBySID
    Win32AccountsByCaption = $Win32AccountsByCaption
    DirectoryEntryCache    = $DirectoryEntryCache
    DomainsByFqdn          = $DomainsByFqdn
    DomainsByNetbios       = $DomainsByNetbios
    DomainsBySid           = $DomainsBySid
    ThisFqdn               = $ThisFqdn
    ThreadCount            = $ThreadCount
  }

  Write-Progress -Status '25% (step 2 of 4)' -CurrentOperation 'Get folder access control lists' -PercentComplete 15 @Progress
  Write-LogMsg @LogParams -Text "`$AccessLists = Get-FolderAccessList -Folder @('$($Folder -join "','")') -Subfolder @('$($Subfolder -join "','")')"
  $AccessLists = Get-FolderAccessList -Folder $Folder -Subfolder $Subfolder @Threads @ChildProgress @LoggingParams

  # Without this step, threads that start simulataneously would all find the cache empty and would all perform queries to populate it
  Write-Progress -Status '50% (step 3 of 4)' -CurrentOperation 'Pre-populate caches in memory to avoid redundant ADSI and CIM queries' -PercentComplete 30 @Progress
  Write-LogMsg @LogParams -Text "Initialize-Cache -Fqdn @('$($KnownFqdn -join "',")')"
  Initialize-Cache -Fqdn $KnownFqdn -CimCache $CimCache @ProgressParent @LoggingParams @CacheParams

  Write-Progress -Status '75% (step 4 of 4)' -CurrentOperation 'Resolve and expand the identities in access control lists to the accounts they represent' -PercentComplete 30 @Progress
  Write-LogMsg @LogParams -Text "Resolve-AccessList -AccessList `$AccessLists"
  Resolve-AccessList -AccessList $AccessLists -InheritanceFlagResolved $InheritanceFlagResolved @Threads @ChildProgress @LoggingParams

  Write-Progress @Progress -Completed

}
