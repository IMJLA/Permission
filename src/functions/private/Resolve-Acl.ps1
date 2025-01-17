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

        [string[]]$ACEPropertyName = $ItemPath.PSObject.Properties.GetEnumerator().Name,

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache,

        # Properties of each Account to display on the report
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description')

    )

    #$Log = @{
    #    'Cache'        = $Cache
    #    'ExpansionMap' = $PermissionCache['LogCacheMap'].Value
    #}

    $AceParams = @{
        AccountProperty = $AccountProperty ; Cache = $Cache ; Type = [guid] ; ItemPath = $ItemPath ;
        ACEPropertyName = $ACEPropertyName
    }

    $ACL = $Cache.Value['AclByPath'].Value[$ItemPath]

    if ($ACL.Owner.IdentityReference) {

        #Write-LogMsg @Log -Text "Resolve-Ace -ACE `$ACL.Owner -ACEPropertyName @('$($ACEPropertyName -join "','")') @AceParams # For Owner IdentityReference '$($ACL.Owner.IdentityReference)' # For ItemPath '$ItemPath'"
        Resolve-Ace -ACE $ACL.Owner -Source 'Ownership' @AceParams

    }

    ForEach ($ACE in $ACL.Access) {

        #Write-LogMsg @Log -Text "Resolve-Ace -ACE `$ACE -ACEPropertyName @('$($ACEPropertyName -join "','")') @AceParams # For ACE IdentityReference '$($ACE.IdentityReference)' # For ItemPath '$ItemPath'"
        Resolve-Ace -ACE $ACE -Source 'Discretionary ACL' @AceParams

    }

}
