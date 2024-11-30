function Resolve-IdentityReferenceDomainDNS {

    param (

        # An NTAccount caption string, or similarly-formatted SID from an item's ACL.
        [String]$IdentityReference,

        # Network path of the item whose ACL the IdentityReference parameter value is from.
        [object]$ItemPath,

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $Log = @{ 'Cache' = $Cache }

    if ($Cache.Value['WellKnownSidBySid'].Value[$IdentityReference]) {

        # IdentityReference is a well-known SID of a local account.
        # For local accounts, the domain is the computer hosting the network resource.
        # This can be extracted from the network path of the item whose ACL IdentityReference is from.
        $DomainDNS = Find-ServerNameInPath -LiteralPath $ItemPath -Cache $Cache
        return $DomainDNS

    }

    if ($IdentityReference.Substring(0, 4) -eq 'S-1-') {

        # IdentityReference should be a SID (Revision 1).
        $IndexOfLastHyphen = $IdentityReference.LastIndexOf('-')
        $DomainSid = $IdentityReference.Substring(0, $IndexOfLastHyphen)

        if ($DomainSid) {

            # IdentityReference appears to be a properly-formatted SID. Its domain SID was able to be parsed.
            $DomainCacheResult = $Cache.Value['DomainBySid'].Value[$DomainSid]

            if ($DomainCacheResult) {

                # IdentityReference belongs to a known domain.
                #Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Domain SID '$DomainSid' # Domain SID cache hit"
                return $DomainCacheResult.Dns

            }

            #Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Domain SID '$DomainSid' # Domain SID cache miss"
            $KnownSid = Get-KnownSid -SID $IdentityReference

            if ($KnownSid) {

                #Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Domain SID '$DomainSid' # Known SID pattern match"
                $DomainDNS = Find-ServerNameInPath -LiteralPath $ItemPath -Cache $Cache
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
            $DomainDNS = Find-ServerNameInPath -LiteralPath $ItemPath -Cache $Cache
            return $DomainDNS

        }

        $DomainCacheResult = $Cache.Value['DomainByNetbios'].Value[$DomainNetBIOS]

        if ($CDomainCacheResult) {

            # IdentityReference belongs to a known domain.
            return $DomainCacheResult.Dns

        }

        # IdentityReference belongs to an unnown domain.
        # Attempt live translation to the domain's DistinguishedName then convert that to FQDN.
        $ThisServerDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -Cache $Cache
        $DomainDNS = ConvertTo-Fqdn -DistinguishedName $ThisServerDn -Cache $Cache
        return $DomainDNS

    }

    $Log['Type'] = 'Error'
    Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Bug before Resolve-IdentityReferenceDomainDNS. Unexpectedly unable to resolve a DNS FQDN due to malformed NTAccount caption"
    return $IdentityReference

}
