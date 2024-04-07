function Resolve-IdentityReferenceDomainDNS {

    param (

        [string]$IdentityReference,

        [object]$ItemPath,

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

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
        [hashtable]$LogMsgCache = ([hashtable]::Synchronized(@{})),

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{}))

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    if ($IdentityReference.Substring(0, 4) -eq 'S-1-') {
        # IdentityReference is a SID (Revision 1)
        $IndexOfLastHyphen = $IdentityReference.LastIndexOf("-")
        $DomainSid = $IdentityReference.Substring(0, $IndexOfLastHyphen)
        if ($DomainSid) {
            $DomainCacheResult = $DomainsBySID[$DomainSid]
            if ($DomainCacheResult) {
                Write-LogMsg @LogParams -Text " # Domain SID cache hit for '$DomainSid' for '$IdentityReference'"
                $DomainDNS = $DomainCacheResult.Dns
            } else {
                Write-LogMsg @LogParams -Text " # Domain SID cache miss for '$DomainSid' for '$IdentityReference'"
            }
        }
    } else {
        $DomainNetBIOS = ($IdentityReference.Split('\'))[0]

        $KnownLocalDomains = @{
            'NT SERVICE'   = $true
            'BUILTIN'      = $true
            'NT AUTHORITY' = $true
        }
        if (-not $KnownLocalDomains[$DomainNetBIOS]) {
            if ($DomainNetBIOS) {
                $DomainDNS = $DomainsByNetbios[$DomainNetBIOS].Dns #Doesn't work for BUILTIN, etc.
            }
            if (-not $DomainDNS) {
                $ThisServerDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -DomainsByNetbios $DomainsByNetbios @LoggingParams
                $DomainDNS = ConvertTo-Fqdn -DistinguishedName $ThisServerDn -ThisFqdn $ThisFqdn -CimCache $CimCache @LoggingParams
            }
        }
    }

    if (-not $DomainDNS) {
        # TODO - Bug: I think this will report incorrectly for a remote domain not in the cache (trust broken or something)
        Write-LogMsg @LogParams -Text "Find-ServerNameInPath -LiteralPath '$ItemPath' -ThisFqdn '$ThisFqdn'"
        $DomainDNS = Find-ServerNameInPath -LiteralPath $ItemPath -ThisFqdn $ThisFqdn
    }

    return $DomainDNS

}
