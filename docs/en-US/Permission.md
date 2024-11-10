---
Module Name: Permission
Module Guid: ded19ba7-2e6d-480e-9cf4-9c5bb56bbc0e
Download Help Link: {{ Update Download Link }}
Help Version: 0.0.834
Locale: en-US
---

# Permission Module
## Description
Module for working with Access Control Lists
## Permission Cmdlets
### [Add-CachedCimInstance](Add-CachedCimInstance.md)

Add-CachedCimInstance [[-InputObject] <Object>] [[-ComputerName] <string>] [[-ClassName] <string>] [[-Query] <string>] [[-CimCache] <hashtable>] [[-DebugOutputStream] <string>] [[-ThisHostName] <string>] [[-WhoAmI] <string>] [-LogBuffer] <ref> [[-CacheByProperty] <string[]>] [<CommonParameters>]

### [Add-CacheItem](Add-CacheItem.md)

Add-CacheItem [-Cache] <hashtable> [-Key] <Object> [[-Value] <Object>] [[-Type] <type>] [<CommonParameters>]

### [Add-PermissionCacheItem](Add-PermissionCacheItem.md)

Add-PermissionCacheItem [-Cache] <ref> [-Key] <Object> [[-Value] <Object>] [[-Type] <type>] [<CommonParameters>]

### [ConvertTo-ItemBlock](ConvertTo-ItemBlock.md)

ConvertTo-ItemBlock [[-ItemPermissions] <Object>]

### [ConvertTo-PermissionFqdn](ConvertTo-PermissionFqdn.md)

ConvertTo-PermissionFqdn [[-ComputerName] <string>] [[-ThisHostname] <string>] [[-WhoAmI] <string>] [[-Cache] <ref>]

### [Expand-Permission](Expand-Permission.md)

Expand-Permission [[-SplitBy] <Object>] [[-GroupBy] <Object>] [[-AceGuidByPath] <Object>] [[-AceGuidByID] <Object>] [[-ACEsByGUID] <Object>] [[-PrincipalsByResolvedID] <Object>] [[-ACLsByPath] <Object>] [[-TargetPath] <hashtable>] [[-Children] <hashtable>] [[-ThisHostName] <string>] [[-WhoAmI] <string>] [-LogBuffer] <ref> [[-DebugOutputStream] <string>] [[-ProgressParentId] <int>] [<CommonParameters>]

### [Expand-PermissionTarget](Expand-PermissionTarget.md)

Expand-PermissionTarget [[-RecurseDepth] <int>] [[-ThreadCount] <ushort>] [[-DebugOutputStream] <string>] [[-ThisHostname] <string>] [[-WhoAmI] <string>] [[-ProgressParentId] <int>] [[-Cache] <ref>]

### [Find-CachedCimInstance](Find-CachedCimInstance.md)

Find-CachedCimInstance [[-ComputerName] <string>] [[-Key] <string>] [[-CimCache] <hashtable>] [[-Log] <hashtable>] [[-CacheToSearch] <string[]>]

### [Find-ResolvedIDsWithAccess](Find-ResolvedIDsWithAccess.md)

Find-ResolvedIDsWithAccess [[-ItemPath] <Object>] [[-AceGUIDsByPath] <hashtable>] [[-ACEsByGUID] <hashtable>] [[-PrincipalsByResolvedID] <hashtable>]

### [Find-ServerFqdn](Find-ServerFqdn.md)

Find-ServerFqdn [[-Known] <string[]>] [[-TargetPath] <hashtable>] [[-ThisFqdn] <string>] [[-ProgressParentId] <int>]

### [Format-Permission](Format-Permission.md)

Format-Permission [[-Permission] <psobject>] [[-IgnoreDomain] <string[]>] [[-GroupBy] <string>] [[-FileFormat] <string[]>] [[-OutputFormat] <string>] [[-Culture] <cultureinfo>] [[-ShortNameByID] <hashtable>] [[-ExcludeClassFilterContents] <hashtable>] [[-IncludeFilterContents] <hashtable>] [[-ProgressParentId] <int>]

### [Format-TimeSpan](Format-TimeSpan.md)

Format-TimeSpan [[-TimeSpan] <timespan>] [[-UnitsToResolve] <string[]>]

### [Get-AccessControlList](Get-AccessControlList.md)

Get-AccessControlList [[-TargetPath] <hashtable>] [[-ThreadCount] <ushort>] [[-DebugOutputStream] <string>] [[-ThisHostname] <string>] [[-WhoAmI] <string>] [[-ProgressParentId] <int>] [[-WarningCache] <hashtable>] [[-Cache] <ref>] [<CommonParameters>]

### [Get-CachedCimInstance](Get-CachedCimInstance.md)

Get-CachedCimInstance [[-ComputerName] <string>] [[-ClassName] <string>] [[-Namespace] <string>] [[-Query] <string>] [[-DebugOutputStream] <string>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [-KeyProperty] <string> [[-CacheByProperty] <string[]>] [[-Cache] <ref>] [<CommonParameters>]

### [Get-CachedCimSession](Get-CachedCimSession.md)

Get-CachedCimSession [[-ComputerName] <string>] [[-DebugOutputStream] <string>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-Cache] <ref>]

### [Get-PermissionPrincipal](Get-PermissionPrincipal.md)

Get-PermissionPrincipal [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-PrincipalByID] <hashtable>] [[-AceGuidByID] <hashtable>] [[-CimCache] <hashtable>] [[-DirectoryEntryCache] <ref>] [[-DomainsByNetbios] <ref>] [[-DomainsBySid] <ref>] [[-DomainsByFqdn] <ref>] [[-ThisFqdn] <string>] [[-ThisHostName] <string>] [[-WhoAmI] <string>] [-LogBuffer] <ref> [[-ProgressParentId] <int>] [[-CurrentDomain] <string>] [-NoGroupMembers] [<CommonParameters>]

### [Get-PermissionTrustedDomain](Get-PermissionTrustedDomain.md)

Get-PermissionTrustedDomain [[-ThisHostname] <string>] [[-WhoAmI] <string>] [[-Cache] <ref>]

### [Get-PermissionWhoAmI](Get-PermissionWhoAmI.md)

Get-PermissionWhoAmI [[-ThisHostname] <string>] [[-Cache] <ref>]

### [Get-TimeZoneName](Get-TimeZoneName.md)

Get-TimeZoneName [[-Time] <datetime>] [[-TimeZone] <ciminstance>]

### [Initialize-Cache](Initialize-Cache.md)

Initialize-Cache [[-Fqdn] <string[]>] [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-CimCache] <hashtable>] [[-DirectoryEntryCache] <ref>] [[-DomainsByNetbios] <ref>] [[-DomainsBySid] <ref>] [[-DomainsByFqdn] <ref>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [-LogBuffer] <ref> [[-ProgressParentId] <int>] [[-WellKnownSIDBySID] <hashtable>] [<CommonParameters>]

### [Invoke-PermissionAnalyzer](Invoke-PermissionAnalyzer.md)

Invoke-PermissionAnalyzer [[-AclByPath] <hashtable>] [[-AllowDisabledInheritance] <hashtable>] [[-PrincipalByID] <hashtable>] [[-AccountConvention] <scriptblock>]

### [Invoke-PermissionCommand](Invoke-PermissionCommand.md)

Invoke-PermissionCommand [[-Command] <string>]

### [New-PermissionCache](New-PermissionCache.md)

New-PermissionCache 

### [Out-Permission](Out-Permission.md)

Out-Permission [[-OutputFormat] <string>] [[-GroupBy] <string>] [[-FormattedPermission] <hashtable>]

### [Out-PermissionFile](Out-PermissionFile.md)

Out-PermissionFile [[-ExcludeAccount] <string[]>] [[-ExcludeClass] <string[]>] [[-IgnoreDomain] <Object>] [[-TargetPath] <string[]>] [[-OutputDir] <Object>] [[-WhoAmI] <string>] [[-ThisFqdn] <Object>] [[-StopWatch] <Object>] [[-Title] <Object>] [[-Permission] <Object>] [[-FormattedPermission] <Object>] [[-LogParams] <Object>] [[-RecurseDepth] <Object>] [[-LogFileList] <Object>] [[-ReportInstanceId] <Object>] [[-AceByGUID] <hashtable>] [[-AclByPath] <hashtable>] [[-PrincipalByID] <hashtable>] [[-Parent] <hashtable>] [[-Detail] <int[]>] [[-Culture] <cultureinfo>] [[-FileFormat] <string[]>] [[-OutputFormat] <string>] [[-GroupBy] <string>] [[-SplitBy] <string[]>] [[-BestPracticeEval] <psobject>] [-NoMembers]

### [Remove-CachedCimSession](Remove-CachedCimSession.md)

Remove-CachedCimSession [[-CimCache] <hashtable>]

### [Resolve-AccessControlList](Resolve-AccessControlList.md)

Resolve-AccessControlList [[-ACLsByPath] <hashtable>] [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-ACEsByGUID] <hashtable>] [[-AceGuidByID] <hashtable>] [[-AceGUIDsByPath] <hashtable>] [[-CimCache] <hashtable>] [[-DirectoryEntryCache] <ref>] [[-DomainsByFqdn] <ref>] [[-DomainsByNetbios] <ref>] [[-DomainsBySid] <ref>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [-LogBuffer] <ref> [[-ProgressParentId] <int>] [[-InheritanceFlagResolved] <string[]>] [<CommonParameters>]

### [Resolve-PermissionTarget](Resolve-PermissionTarget.md)

Resolve-PermissionTarget [[-TargetPath] <DirectoryInfo[]>] [[-DebugOutputStream] <string>] [[-ThisHostname] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-Cache] <ref>] [[-ProgressParentId] <int>]

### [Select-PermissionPrincipal](Select-PermissionPrincipal.md)

Select-PermissionPrincipal [[-PrincipalByID] <hashtable>] [[-ExcludeAccount] <string[]>] [[-IncludeAccount] <string[]>] [[-IgnoreDomain] <string[]>] [[-IdByShortName] <hashtable>] [[-ShortNameByID] <hashtable>] [[-ExcludeClassFilterContents] <hashtable>] [[-ExcludeFilterContents] <hashtable>] [[-IncludeFilterContents] <hashtable>] [[-ProgressParentId] <int>] [[-ThisHostName] <string>] [[-WhoAmI] <string>] [[-LogBuffer] <hashtable>]


