function Resolve-PermissionIdentity {

    param (

        # Permission objects from Get-FolderAccessList whose IdentityReference to resolve
        [Parameter(ValueFromPipeline)]
        [object[]]$Permission,

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Maximum number of concurrent threads to allow
        [int]$ThreadCount = (Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum,

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
        [hashtable]$LogMsgCache = $Global:LogMessages

    )

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    if ($ThreadCount -eq 1) {

        $ResolveAceParams = @{
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
        }

        [int]$ProgressInterval = [math]::max(($Permission.Count / 100), 1)
        $ProgressCounter = 0
        $i = 0

        ForEach ($ThisPermission in $Permission) {

            $ProgressCounter++

            if ($ProgressCounter -eq $ProgressInterval) {

                $PercentComplete = $i / $Permission.Count * 100
                Write-Progress -Activity 'Resolve-PermissionIdentity' -Status "$([int]$PercentComplete)%" -CurrentOperation "Resolve-Ace $($ThisPermission.IdentityReference)" -PercentComplete $PercentComplete
                $ProgressCounter = 0

            }

            $i++ # increment $i after Write-Progress to show progress conservatively rather than optimistically
            $ResolveAceParams['InputObject'] = $ThisPermission
            Write-LogMsg @LogParams -Text "Resolve-Ace -InputObject $($ThisPermission.IdentityReference)"
            Resolve-Ace @ResolveAceParams

        }

        Write-Progress -Activity 'Resolve-PermissionIdentity' -Completed

    } else {

        $ResolveAceParams = @{

            Command              = 'Resolve-Ace'
            InputObject          = $Permission
            InputParameter       = 'InputObject'
            ObjectStringProperty = 'IdentityReference'
            TodaysHostname       = $ThisHostname
            #DebugOutputStream    = 'Debug'
            WhoAmI               = $WhoAmI
            LogMsgCache          = $LogMsgCache
            Threads              = $ThreadCount
            AddParam             = @{
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


            }

        }

        Write-LogMsg @LogParams -Text "Split-Thread -Command 'Resolve-Ace' -InputParameter InputObject -InputObject `$Permission -ObjectStringProperty 'IdentityReference' -DebugOutputStream 'Debug'"

        Split-Thread @ResolveAceParams

    }

}
