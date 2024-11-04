function Resolve-IdentityReferenceDomainDNS {

    param (

        # An NTAccount caption string, or similarly-formatted SID from an item's ACL.
        [String]$IdentityReference,

        # Network path of the item whose ACL the IdentityReference parameter value is from.
        [object]$ItemPath,

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [ref]$DomainsByNetbios = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [ref]$DomainsBySid = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

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
        [Hashtable]$CimCache = @{},

        # Output from Get-KnownSidHashTable
        [hashtable]$WellKnownSidBySid = (Get-KnownSidHashTable),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [String]$DebugOutputStream = 'Debug'

    )

    $Log = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        Buffer       = $LogBuffer
        WhoAmI       = $WhoAmI
    }

    if ($WellKnownSidBySid[$IdentityReference]) {

        # IdentityReference is a well-known SID of a local account.
        # For local accounts, the domain is the computer hosting the network resource.
        # This can be extracted from the network path of the item whose ACL IdentityReference is from.
        $DomainDNS = Find-ServerNameInPath -LiteralPath $ItemPath -ThisFqdn $ThisFqdn
        return $DomainDNS

    }

    if ($IdentityReference.Substring(0, 4) -eq 'S-1-') {

        # IdentityReference should be a SID (Revision 1).
        $IndexOfLastHyphen = $IdentityReference.LastIndexOf('-')
        $DomainSid = $IdentityReference.Substring(0, $IndexOfLastHyphen)

        if ($DomainSid) {

            # IdentityReference appears to be a properly-formatted SID. Its domain SID was able to be parsed.
            $DomainCacheResult = $DomainsBySID[$DomainSid]

            if ($DomainCacheResult) {

                # IdentityReference belongs to a known domain.
                #Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Domain SID '$DomainSid' # Domain SID cache hit"
                return $DomainCacheResult.Dns

            }

            #Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Domain SID '$DomainSid' # Domain SID cache miss"
            $KnownSid = Get-KnownSid -SID $IdentityReference

            if ($KnownSid) {

                #Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Domain SID '$DomainSid' # Known SID pattern match"
                $DomainDNS = Find-ServerNameInPath -LiteralPath $ItemPath -ThisFqdn $ThisFqdn
                return $DomainDNS

            }

            # IdentityReference belongs to an unknown domain.
            $Log['Type'] = 'Warning'
            Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Domain SID '$DomainSid' # Unknown domain (possibly offline). Unable to resolve domain FQDN"
            return $DomainSid

        }

        # IdentityReference is not a properly-formatted SID.
        $Log['Type'] = 'Error'
        Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Bug before Resolve-IdentityReferenceDomainDNS. Unable to resolve a DNS FQDN due to malformed SID"
        return $IdentityReference

    }

    # IdentityReference should be an NTAccount caption
    $DomainNetBIOS = ($IdentityReference.Split('\'))[0]

    if ($DomainNetBIOS) {

        # IdentityReference appears to be a properly-formatted NTAccount caption. Its domain was able to be parsed.

        $KnownLocalDomains = @{
            'NT SERVICE'   = $true
            'BUILTIN'      = $true
            'NT AUTHORITY' = $true
        }

        $DomainCacheResult = $KnownLocalDomains[$DomainNetBIOS]

        if ($DomainCacheResult) {

            # IdentityReference belongs to a well-known local domain.
            # For local accounts, the domain is the computer hosting the network resource.
            # This can be extracted from the network path of the item whose ACL IdentityReference is from.
            $DomainDNS = Find-ServerNameInPath -LiteralPath $ItemPath -ThisFqdn $ThisFqdn
            return $DomainDNS

        }

        $DomainCacheResult = $DomainsByNetbios[$DomainNetBIOS]

        if ($DomainCacheResult) {

            # IdentityReference belongs to a known domain.
            return $DomainCacheResult.Dns

        }

        # IdentityReference belongs to an unnown domain.
        # Attempt live translation to the domain's DistinguishedName then convert that to FQDN.
        $ThisServerDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -DomainsByNetbios $DomainsByNetbios @LoggingParams
        $DomainDNS = ConvertTo-Fqdn -DistinguishedName $ThisServerDn -ThisFqdn $ThisFqdn -CimCache $CimCache @LoggingParams
        return $DomainDNS

    }

    $Log['Type'] = 'Error'
    Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Bug before Resolve-IdentityReferenceDomainDNS. Unexpectedly unable to resolve a DNS FQDN due to malformed NTAccount caption"
    return $IdentityReference

}
