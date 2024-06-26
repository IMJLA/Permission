function Resolve-IdentityReferenceDomainDNS {

    param (

        [String]$IdentityReference,

        [object]$ItemPath,

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
        [Hashtable]$LogBuffer = @{},

        # Cache of CIM sessions and instances to reduce connections and queries
        [Hashtable]$CimCache = @{}

    )

    $Log = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        Buffer       = $LogBuffer
        WhoAmI       = $WhoAmI
    }

    if ($IdentityReference.Substring(0, 4) -eq 'S-1-') {
        # IdentityReference is a SID (Revision 1)
        $IndexOfLastHyphen = $IdentityReference.LastIndexOf("-")
        $DomainSid = $IdentityReference.Substring(0, $IndexOfLastHyphen)
        if ($DomainSid) {
            $DomainCacheResult = $DomainsBySID[$DomainSid]
            if ($DomainCacheResult) {
                Write-LogMsg @Log -Text " # Domain SID cache hit for '$DomainSid' for '$IdentityReference'"
                $DomainDNS = $DomainCacheResult.Dns
            } else {
                Write-LogMsg @Log -Text " # Domain SID cache miss for '$DomainSid' for '$IdentityReference'"
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
        Write-LogMsg @Log -Text "Find-ServerNameInPath -LiteralPath '$ItemPath' -ThisFqdn '$ThisFqdn'"
        $DomainDNS = Find-ServerNameInPath -LiteralPath $ItemPath -ThisFqdn $ThisFqdn
    }

    return $DomainDNS

}
