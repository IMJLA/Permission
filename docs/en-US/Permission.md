---
Module Name: Permission
Module Guid: ded19ba7-2e6d-480e-9cf4-9c5bb56bbc0e
Download Help Link: {{ Update Download Link }}
Help Version: 0.0.722
Locale: en-US
---

# Permission Module
## Description
Module for working with Access Control Lists

## Permission Cmdlets
### [Add-CacheItem](Add-CacheItem.md)

Add-CacheItem [[-Cache] <hashtable>] [[-Key] <Object>] [[-Value] <Object>] [[-Type] <type>]


### [ConvertTo-ItemBlock](ConvertTo-ItemBlock.md)

ConvertTo-ItemBlock [[-ItemPermissions] <Object>]


### [Expand-Permission](Expand-Permission.md)

Expand-Permission [[-SplitBy] <Object>] [[-GroupBy] <Object>] [[-AceGuidByPath] <Object>] [[-AceGUIDsByResolvedID] <Object>] [[-ACEsByGUID] <Object>] [[-PrincipalsByResolvedID] <Object>] [[-ACLsByPath] <Object>] [[-TargetPath] <hashtable>] [[-Children] <hashtable>] [[-ThisHostName] <string>] [[-WhoAmI] <string>] [[-LogBuffer] <hashtable>] [[-DebugOutputStream] <string>] [[-ProgressParentId] <int>]


### [Expand-PermissionTarget](Expand-PermissionTarget.md)

Expand-PermissionTarget [[-RecurseDepth] <int>] [[-ThreadCount] <ushort>] [[-DebugOutputStream] <string>] [[-ThisHostname] <string>] [[-WhoAmI] <string>] [[-LogBuffer] <hashtable>] [[-ProgressParentId] <int>] [[-TargetPath] <hashtable>]


### [Find-ResolvedIDsWithAccess](Find-ResolvedIDsWithAccess.md)

Find-ResolvedIDsWithAccess [[-ItemPath] <Object>] [[-AceGUIDsByPath] <hashtable>] [[-ACEsByGUID] <hashtable>] [[-PrincipalsByResolvedID] <hashtable>]


### [Find-ServerFqdn](Find-ServerFqdn.md)

Find-ServerFqdn [[-Known] <string[]>] [[-TargetPath] <hashtable>] [[-ThisFqdn] <string>] [[-ProgressParentId] <int>]


### [Format-Permission](Format-Permission.md)

Format-Permission [[-Permission] <psobject>] [[-IgnoreDomain] <string[]>] [[-GroupBy] <string>] [[-FileFormat] <string[]>] [[-OutputFormat] <string>] [[-Culture] <cultureinfo>] [[-ShortNameByID] <hashtable>] [[-ExcludeClassFilterContents] <hashtable>] [[-IncludeFilterContents] <hashtable>]


### [Format-TimeSpan](Format-TimeSpan.md)

Format-TimeSpan [[-TimeSpan] <timespan>] [[-UnitsToResolve] <string[]>]


### [Get-AccessControlList](Get-AccessControlList.md)

Get-AccessControlList [[-TargetPath] <hashtable>] [[-ThreadCount] <ushort>] [[-DebugOutputStream] <string>] [[-TodaysHostname] <string>] [[-WhoAmI] <string>] [[-LogBuffer] <hashtable>] [[-OwnerCache] <ConcurrentDictionary[string,psobject]>] [[-ProgressParentId] <int>] [[-Output] <hashtable>]


### [Get-CachedCimInstance](Get-CachedCimInstance.md)

Get-CachedCimInstance [[-ComputerName] <string>] [[-ClassName] <string>] [[-Namespace] <string>] [[-Query] <string>] [[-CimCache] <hashtable>] [[-DebugOutputStream] <string>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogBuffer] <hashtable>] [-KeyProperty] <string> [[-CacheByProperty] <string[]>] [<CommonParameters>]


### [Get-CachedCimSession](Get-CachedCimSession.md)

Get-CachedCimSession [[-ComputerName] <string>] [[-CimCache] <hashtable>] [[-DebugOutputStream] <string>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogBuffer] <hashtable>]


### [Get-PermissionPrincipal](Get-PermissionPrincipal.md)

Get-PermissionPrincipal [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-PrincipalsByResolvedID] <hashtable>] [[-ACEsByResolvedID] <hashtable>] [[-CimCache] <hashtable>] [[-DirectoryEntryCache] <hashtable>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-DomainsByFqdn] <hashtable>] [[-ThisFqdn] <string>] [[-ThisHostName] <string>] [[-WhoAmI] <string>] [[-LogBuffer] <hashtable>] [[-ProgressParentId] <int>] [[-CurrentDomain] <string>] [-NoGroupMembers]


### [Get-TimeZoneName](Get-TimeZoneName.md)

Get-TimeZoneName [[-Time] <datetime>] [[-TimeZone] <ciminstance>]


### [Initialize-Cache](Initialize-Cache.md)

Initialize-Cache [[-Fqdn] <string[]>] [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-CimCache] <hashtable>] [[-DirectoryEntryCache] <hashtable>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-DomainsByFqdn] <hashtable>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogBuffer] <hashtable>] [[-ProgressParentId] <int>]


### [Invoke-PermissionAnalyzer](Invoke-PermissionAnalyzer.md)

Invoke-PermissionAnalyzer [[-AclByPath] <hashtable>] [[-AllowDisabledInheritance] <hashtable>] [[-PrincipalByID] <hashtable>] [[-AccountConvention] <scriptblock>]


### [Invoke-PermissionCommand](Invoke-PermissionCommand.md)

Invoke-PermissionCommand [[-Command] <string>]


### [Out-Permission](Out-Permission.md)

Out-Permission [[-OutputFormat] <string>] [[-GroupBy] <string>] [[-FormattedPermission] <hashtable>]


### [Out-PermissionFile](Out-PermissionFile.md)

Out-PermissionFile [[-ExcludeAccount] <string[]>] [[-ExcludeClass] <string[]>] [[-IgnoreDomain] <Object>] [[-TargetPath] <string[]>] [[-OutputDir] <Object>] [[-WhoAmI] <string>] [[-ThisFqdn] <Object>] [[-StopWatch] <Object>] [[-Title] <Object>] [[-Permission] <Object>] [[-FormattedPermission] <Object>] [[-LogParams] <Object>] [[-RecurseDepth] <Object>] [[-LogFileList] <Object>] [[-ReportInstanceId] <Object>] [[-AceByGUID] <hashtable>] [[-AclByPath] <hashtable>] [[-PrincipalByID] <hashtable>] [[-Parent] <hashtable>] [[-Detail] <int[]>] [[-Culture] <cultureinfo>] [[-FileFormat] <string[]>] [[-OutputFormat] <string>] [[-GroupBy] <string>] [[-SplitBy] <string[]>] [[-BestPracticeEval] <psobject>] [-NoMembers]


### [Remove-CachedCimSession](Remove-CachedCimSession.md)

Remove-CachedCimSession [[-CimCache] <hashtable>]


### [Resolve-AccessControlList](Resolve-AccessControlList.md)

Resolve-AccessControlList [[-ACLsByPath] <hashtable>] [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-ACEsByGUID] <hashtable>] [[-AceGUIDsByResolvedID] <hashtable>] [[-AceGUIDsByPath] <hashtable>] [[-CimCache] <hashtable>] [[-DirectoryEntryCache] <hashtable>] [[-DomainsByFqdn] <hashtable>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogBuffer] <hashtable>] [[-ProgressParentId] <int>] [[-InheritanceFlagResolved] <string[]>]


### [Resolve-Folder](Resolve-Folder.md)

Resolve-Folder [[-TargetPath] <string>] [[-CimCache] <hashtable>] [[-DebugOutputStream] <string>] [[-ThisHostname] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogBuffer] <hashtable>]


### [Resolve-PermissionTarget](Resolve-PermissionTarget.md)

Resolve-PermissionTarget [[-TargetPath] <DirectoryInfo[]>] [[-CimCache] <hashtable>] [[-DebugOutputStream] <string>] [[-ThisHostname] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogBuffer] <hashtable>] [[-Output] <hashtable>] [[-ProgressParentId] <int>] [<CommonParameters>]


### [Select-PermissionPrincipal](Select-PermissionPrincipal.md)

Select-PermissionPrincipal [[-PrincipalByID] <hashtable>] [[-ExcludeAccount] <string[]>] [[-IncludeAccount] <string[]>] [[-IgnoreDomain] <string[]>] [[-IdByShortName] <hashtable>] [[-ShortNameByID] <hashtable>] [[-ExcludeClassFilterContents] <hashtable>] [[-ExcludeFilterContents] <hashtable>] [[-IncludeFilterContents] <hashtable>] [[-ProgressParentId] <int>] [[-ThisHostName] <string>] [[-WhoAmI] <string>] [[-LogBuffer] <hashtable>]



