function Resolve-Ace {

    <#
    .SYNOPSIS
    Use ADSI to lookup info about IdentityReferences from Authorization Rule Collections that came from Discretionary Access Control Lists
    .DESCRIPTION
    Based on the IdentityReference proprety of each Access Control Entry:
    Resolve SID to NT account name and vise-versa
    Resolve well-known SIDs
    Resolve generic defaults like 'NT AUTHORITY' and 'BUILTIN' to the applicable computer or domain name
    Add these properties (IdentityReferenceSID,IdentityReferenceResolved) to the object and return it
    .INPUTS
    [System.Security.AccessControl.AuthorizationRuleCollection]$ACE
    .OUTPUTS
    [PSCustomObject] Original object plus IdentityReferenceSID,IdentityReferenceResolved, and AdsiProvider properties
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

    TODO: add a param to offer DNS instead of or in addition to NetBIOS
    #>

    [OutputType([void])]

    param (

        # Authorization Rule Collection of Access Control Entries from Discretionary Access Control Lists
        [object]$ACE,

        [object]$ItemPath,

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

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [String]$DebugOutputStream = 'Debug',

        [string[]]$ACEPropertyName = $ACE.PSObject.Properties.GetEnumerator().Name,

        # Will be set as the Source property of the output object.
        # Intended to reflect permissions resulting from Ownership rather than Discretionary Access Lists
        [String]$Source,

        # String translations indexed by value in the [System.Security.AccessControl.InheritanceFlags] enum
        # Parameter default value is on a single line as a workaround to a PlatyPS bug
        [string[]]$InheritanceFlagResolved = @('this folder but not subfolders', 'this folder and subfolders', 'this folder and files, but not subfolders', 'this folder, subfolders, and files'),

        # In-process cache to reduce calls to other processes or to disk
        [ref]$Cache,

        # GUID type (can be provided to avoid repetitive instantiation)
        [type]$Type = [guid],

        # Properties of each Account to display on the report
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description')

    )

    #$Log = @{ ThisHostname = $ThisHostname ; Type = $DebugOutputStream ; Buffer = $Cache.Value['LogBuffer'] ; WhoAmI = $WhoAmI }
    $Splat = @{ ThisHostname = $ThisHostname ; Cache = $Cache ; WhoAmI = $WhoAmI ; DebugOutputStream = $DebugOutputStream ; ThisFqdn = $ThisFqdn }

    #Write-LogMsg @Log -Text "Resolve-IdentityReferenceDomainDNS -IdentityReference '$($ACE.IdentityReference)' -ItemPath '$ItemPath'" -Expand $Splat -Suffix " # For ACE IdentityReference '$($ACE.IdentityReference)' # For ItemPath '$ItemPath'"
    $DomainDNS = Resolve-IdentityReferenceDomainDNS -IdentityReference $ACE.IdentityReference -ItemPath $ItemPath @Splat

    #Write-LogMsg @Log -Text "`$AdsiServer = Get-AdsiServer -Fqdn '$DomainDNS'" -Expand $Splat -Suffix " # For ACE IdentityReference '$($ACE.IdentityReference)' # For ItemPath '$ItemPath'"
    $AdsiServer = Get-AdsiServer -Fqdn $DomainDNS @Splat

    #Write-LogMsg @Log -Text "Resolve-IdentityReference -IdentityReference '$($ACE.IdentityReference)' -AdsiServer `$AdsiServer -AccountProperty @('$($AccountProperty -join "','")'" -Expand $Splat -Suffix " # ADSI server '$($AdsiServer.AdsiProvider)://$($AdsiServer.Dns)' # For ACE IdentityReference '$($ACE.IdentityReference)' # For ItemPath '$ItemPath'"
    $ResolvedIdentityReference = Resolve-IdentityReference -IdentityReference $ACE.IdentityReference -AdsiServer $AdsiServer -AccountProperty $AccountProperty @Splat

    $ObjectProperties = @{
        Access                    = "$($ACE.AccessControlType) $($ACE.FileSystemRights) $($InheritanceFlagResolved[$ACE.InheritanceFlags])"
        AdsiProvider              = $AdsiServer.AdsiProvider
        AdsiServer                = $DomainDNS
        IdentityReferenceSID      = $ResolvedIdentityReference.SIDString
        IdentityReferenceResolved = $ResolvedIdentityReference.IdentityReferenceNetBios
        Path                      = $ItemPath
        SourceOfAccess            = $Source
        PSTypeName                = 'Permission.AccessControlEntry'
    }

    ForEach ($ThisProperty in $ACEPropertyName) {
        $ObjectProperties[$ThisProperty] = $ACE.$ThisProperty
    }

    $OutputObject = [PSCustomObject]$ObjectProperties
    $Guid = [guid]::NewGuid()
    Add-PermissionCacheItem -Cache $Cache.Value['AceByGuid'] -Key $Guid -Value $OutputObject -Type ([object])
    Add-PermissionCacheItem -Cache $Cache.Value['AceGuidById'] -Key $OutputObject.IdentityReferenceResolved -Value $Guid -Type $Type
    Add-PermissionCacheItem -Cache $Cache.Value['AceGuidByPath'] -Key $OutputObject.Path -Value $Guid -Type $Type

}
