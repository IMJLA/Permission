function Resolve-Acl {
    <#
    .SYNOPSIS
    Use ADSI to lookup info about IdentityReferences from Authorization Rule Collections that came from Discretionary Access Control Lists
    .DESCRIPTION
    Based on the IdentityReference proprety of each Access Control Entry:
    Resolve SID to NT account name and vise-versa
    Resolve well-known SIDs
    Resolve generic defaults like 'NT AUTHORITY' and 'BUILTIN' to the applicable computer or domain name
    Add these properties (IdentityReferenceSID,IdentityReferenceName,IdentityReferenceResolved) to the object and return it
    .INPUTS
    [System.Security.AccessControl.AuthorizationRuleCollection]$ItemPath
    .OUTPUTS
    [PSCustomObject] Original object plus IdentityReferenceSID,IdentityReferenceName,IdentityReferenceResolved, and AdsiProvider properties
    .EXAMPLE
    Get-Acl |
    Expand-Acl |
    Resolve-Ace

    Use Get-Acl from the Microsoft.PowerShell.Security module as the source of the access list
    This works in either Windows Powershell or in Powershell
    Get-Acl does not support long paths (>256 characters)
    That was why I originally used the .Net Framework method
    .EXAMPLE
    Get-FolderAce -LiteralPath C:\Test -IncludeInherited |
    Resolve-Ace
    .EXAMPLE
    [String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor [System.Security.AccessControl.AccessControlSections]::Owner
    $FileSecurity = [System.Security.AccessControl.FileSecurity]::new($DirectoryInfo,$Sections)
    $IncludeExplicitRules = $true
    $IncludeInheritedRules = $true
    $AccountType = [System.Security.Principal.SecurityIdentifier]
    $FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
    Resolve-Ace

    This uses .Net Core as the source of the access list
    It uses the GetAccessRules method on the [System.Security.AccessControl.FileSecurity] class
    The targetType parameter of the method is used to specify that the accounts in the ACL are returned as SIDs
    .EXAMPLE
    [String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor
    [System.Security.AccessControl.AccessControlSections]::Owner -bor
    [System.Security.AccessControl.AccessControlSections]::Group
    $DirectorySecurity = [System.Security.AccessControl.DirectorySecurity]::new($DirectoryInfo,$Sections)
    $IncludeExplicitRules = $true
    $IncludeInheritedRules = $true
    $AccountType = [System.Security.Principal.NTAccount]
    $FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
    Resolve-Ace

    This uses .Net Core as the source of the access list
    It uses the GetAccessRules method on the [System.Security.AccessControl.FileSecurity] class
    The targetType parameter of the method is used to specify that the accounts in the ACL are returned as NT account names (DOMAIN\User)
    .EXAMPLE
    [String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    [System.Security.AccessControl.DirectorySecurity]$DirectorySecurity = $DirectoryInfo.GetAccessControl('Access')
    [System.Security.AccessControl.AuthorizationRuleCollection]$AuthRules = $DirectorySecurity.Access
    $AuthRules | Resolve-Ace

    Use the .Net Framework (or legacy .Net Core up to 2.2) as the source of the access list
    Only works in Windows PowerShell
    Those versions of .Net had a GetAccessControl method on the [System.IO.DirectoryInfo] class
    This method is removed in modern versions of .Net Core

    .EXAMPLE
    [String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor [System.Security.AccessControl.AccessControlSections]::Owner
    $FileSecurity = [System.IO.FileSystemAclExtensions]::GetAccessControl($DirectoryInfo,$Sections)

    The [System.IO.FileSystemAclExtensions] class is a Windows-specific implementation
    It provides no known benefit over the cross-platform equivalent [System.Security.AccessControl.FileSecurity]

    .NOTES
    Dependencies:
        Get-DirectoryEntry
        Add-SidInfo
        Get-TrustedDomain
        Find-AdsiProvider

    if ($FolderPath.Length -gt 255) {
        $FolderPath = "\\?\$FolderPath"
    }
#>
    [OutputType([PSCustomObject])]
    param (

        # Authorization Rule Collection of Access Control Entries from Discretionary Access Control Lists
        [object]$ItemPath,

        # Cache of access control lists keyed by path
        [Hashtable]$ACLsByPath = [Hashtable]::Synchronized(@{}),

        # Cache of access control entries keyed by GUID generated in this function
        [Hashtable]$ACEsByGUID = ([Hashtable]::Synchronized(@{})),

        # Cache of access control entry GUIDs keyed by their resolved identities
        [Hashtable]$AceGUIDsByResolvedID = ([Hashtable]::Synchronized(@{})),

        # Cache of access control entry GUIDs keyed by their paths
        [Hashtable]$AceGUIDsByPath = ([Hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to a thread-safe dictionary with string keys and object values
        #>
        [ref]$DirectoryEntryCache = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [ref]$DomainsByNetbios = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [ref]$DomainsBySid = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [ref]$DomainsByFqdn = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

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

        # Cache of CIM sessions and instances to reduce connections and queries
        [Hashtable]$CimCache = ([Hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [String]$DebugOutputStream = 'Debug',

        [string[]]$ACEPropertyName = $ItemPath.PSObject.Properties.GetEnumerator().Name,

        # String translations indexed by value in the [System.Security.AccessControl.InheritanceFlags] enum
        # Parameter default value is on a single line as a workaround to a PlatyPS bug
        [string[]]$InheritanceFlagResolved = @('this folder but not subfolders', 'this folder and subfolders', 'this folder and files, but not subfolders', 'this folder, subfolders, and files')

    )

    #$Log = @{
    #    ThisHostname = $ThisHostname
    #    Type         = $DebugOutputStream
    #    Buffer       = $LogBuffer
    #    WhoAmI       = $WhoAmI
    #}

    $ResolveAceSplat = @{
        ACEsByGUID = $ACEsByGUID ; AceGUIDsByResolvedID = $AceGUIDsByResolvedID ; AceGUIDsByPath = $AceGUIDsByPath ;
        DirectoryEntryCache = $DirectoryEntryCache ; DomainsByNetbios = $DomainsByNetbios ; DomainsBySid = $DomainsBySid ;
        DomainsByFqdn = $DomainsByFqdn ; ThisHostName = $ThisHostName ; ThisFqdn = $ThisFqdn ;
        WhoAmI = $WhoAmI ; LogBuffer = $LogBuffer ; CimCache = $CimCache ; ItemPath = $ItemPath ;
        DebugOutputStream = $DebugOutputStream ; ACEPropertyName = $ACEPropertyName ; InheritanceFlagResolved = $InheritanceFlagResolved
    }

    $ACL = $ACLsByPath[$ItemPath]

    if ($ACL.Owner.IdentityReference) {

        #Write-LogMsg @Log -Text "Resolve-Ace -ACE `$ACL.Owner -ACEPropertyName @('$($ACEPropertyName -join "','")') @ResolveAceSplat # For Owner IdentityReference '$($ACL.Owner.IdentityReference)' # For ItemPath '$ItemPath'"
        Resolve-Ace -ACE $ACL.Owner -Source 'Ownership' @ResolveAceSplat

    }

    ForEach ($ACE in $ACL.Access) {

        #Write-LogMsg @Log -Text "Resolve-Ace -ACE `$ACE -ACEPropertyName @('$($ACEPropertyName -join "','")') @ResolveAceSplat # For ACE IdentityReference '$($ACE.IdentityReference)' # For ItemPath '$ItemPath'"
        Resolve-Ace -ACE $ACE -Source 'Discretionary ACL' @ResolveAceSplat

    }

}
