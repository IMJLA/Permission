---
Module Name: Permission
Module Guid: ded19ba7-2e6d-480e-9cf4-9c5bb56bbc0e ded19ba7-2e6d-480e-9cf4-9c5bb56bbc0e
Download Help Link: {{ Update Download Link }}
Help Version: 0.0.495
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

Expand-Permission [[-SortedPaths] <Object>] [[-SplitBy] <Object>] [[-GroupBy] <Object>] [[-AceGUIDsByPath] <Object>] [[-AceGUIDsByResolvedID] <Object>] [[-ACEsByGUID] <Object>] [[-PrincipalsByResolvedID] <Object>] [[-ACLsByPath] <Object>] [[-TargetPath] <hashtable>] [[-Children] <hashtable>]


### [Expand-PermissionTarget](Expand-PermissionTarget.md)

Expand-PermissionTarget [[-RecurseDepth] <int>] [[-ThreadCount] <ushort>] [[-DebugOutputStream] <string>] [[-ThisHostname] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ProgressParentId] <int>] [[-TargetPath] <hashtable>]


### [Find-ResolvedIDsWithAccess](Find-ResolvedIDsWithAccess.md)

Find-ResolvedIDsWithAccess [[-ItemPath] <Object>] [[-AceGUIDsByPath] <hashtable>] [[-ACEsByGUID] <hashtable>] [[-PrincipalsByResolvedID] <hashtable>]


### [Find-ServerFqdn](Find-ServerFqdn.md)

Find-ServerFqdn [[-Known] <string[]>] [[-TargetPath] <hashtable>] [[-ThisFqdn] <string>] [[-ProgressParentId] <int>]


### [Format-Permission](Format-Permission.md)

Format-Permission [[-Permission] <psobject>] [[-IgnoreDomain] <string[]>] [[-GroupBy] <string>] [[-FileFormat] <string[]>] [[-OutputFormat] <string>] [[-ShortestPath] <string>] [[-Culture] <cultureinfo>]


### [Format-TimeSpan](Format-TimeSpan.md)

Format-TimeSpan [[-TimeSpan] <timespan>] [[-UnitsToResolve] <string[]>]


### [Get-AccessControlList](Get-AccessControlList.md)

Get-AccessControlList [[-TargetPath] <hashtable>] [[-ThreadCount] <ushort>] [[-DebugOutputStream] <string>] [[-TodaysHostname] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-OwnerCache] <ConcurrentDictionary[string,psobject]>] [[-ProgressParentId] <int>] [[-AclByPath] <hashtable>]


### [Get-CachedCimInstance](Get-CachedCimInstance.md)

Get-CachedCimInstance [[-ComputerName] <string>] [[-ClassName] <string>] [[-Query] <string>] [[-CimCache] <hashtable>] [[-DebugOutputStream] <string>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [-KeyProperty] <string> [[-CacheByProperty] <string[]>] [<CommonParameters>]


### [Get-CachedCimSession](Get-CachedCimSession.md)

Get-CachedCimSession [[-ComputerName] <string>] [[-CimCache] <hashtable>] [[-DebugOutputStream] <string>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>]


### [Get-FolderPermissionsBlockUNUSED](Get-FolderPermissionsBlockUNUSED.md)

Get-FolderPermissionsBlockUNUSED [[-FolderPermissions] <Object>] [[-ExcludeAccount] <string[]>] [[-ExcludeClass] <string[]>] [[-IgnoreDomain] <string[]>] [[-ShortestPath] <Object>]


### [Get-PermissionPrincipal](Get-PermissionPrincipal.md)

Get-PermissionPrincipal [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-PrincipalsByResolvedID] <hashtable>] [[-ACEsByResolvedID] <hashtable>] [[-CimCache] <hashtable>] [[-DirectoryEntryCache] <hashtable>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-DomainsByFqdn] <hashtable>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ProgressParentId] <int>] [[-CurrentDomain] <string>] [-NoGroupMembers]


### [Get-PrtgXmlSensorOutput](Get-PrtgXmlSensorOutput.md)

Get-PrtgXmlSensorOutput [[-NtfsIssues] <Object>]


### [Get-TimeZoneName](Get-TimeZoneName.md)

Get-TimeZoneName [[-Time] <datetime>] [[-TimeZone] <ciminstance>]


### [Initialize-Cache](Initialize-Cache.md)

Initialize-Cache [[-Fqdn] <string[]>] [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-CimCache] <hashtable>] [[-DirectoryEntryCache] <hashtable>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-DomainsByFqdn] <hashtable>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ProgressParentId] <int>]


### [Invoke-PermissionCommand](Invoke-PermissionCommand.md)

Invoke-PermissionCommand [[-Command] <string>]


### [Out-PermissionReport](Out-PermissionReport.md)

Out-PermissionReport [[-ExcludeAccount] <string[]>] [[-ExcludeClass] <string[]>] [[-IgnoreDomain] <Object>] [[-TargetPath] <string[]>] [[-OutputDir] <Object>] [[-WhoAmI] <string>] [[-ThisFqdn] <Object>] [[-StopWatch] <Object>] [[-Title] <Object>] [[-Permission] <Object>] [[-FormattedPermission] <Object>] [[-LogParams] <Object>] [[-RecurseDepth] <Object>] [[-LogFileList] <Object>] [[-ReportInstanceId] <Object>] [[-ACEsByGUID] <hashtable>] [[-ACLsByPath] <hashtable>] [[-PrincipalsByResolvedID] <Object>] [[-BestPracticeIssue] <Object>] [[-Parent] <hashtable>] [[-Detail] <int[]>] [[-Culture] <cultureinfo>] [[-FileFormat] <string[]>] [[-OutputFormat] <string>] [[-GroupBy] <string>] [-NoMembers]


### [Remove-CachedCimSession](Remove-CachedCimSession.md)

Remove-CachedCimSession [[-CimCache] <hashtable>]


### [Resolve-AccessControlList](Resolve-AccessControlList.md)

Resolve-AccessControlList [[-ACLsByPath] <hashtable>] [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-ACEsByGUID] <hashtable>] [[-AceGUIDsByResolvedID] <hashtable>] [[-AceGUIDsByPath] <hashtable>] [[-CimCache] <hashtable>] [[-DirectoryEntryCache] <hashtable>] [[-DomainsByFqdn] <hashtable>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ProgressParentId] <int>] [[-InheritanceFlagResolved] <string[]>]


### [Resolve-Ace](Resolve-Ace.md)
Use ADSI to lookup info about IdentityReferences from Authorization Rule Collections that came from Discretionary Access Control Lists

### [Resolve-Acl](Resolve-Acl.md)
Use ADSI to lookup info about IdentityReferences from Authorization Rule Collections that came from Discretionary Access Control Lists

### [Resolve-Folder](Resolve-Folder.md)

Resolve-Folder [[-TargetPath] <string>] [[-CimCache] <hashtable>] [[-DebugOutputStream] <string>] [[-ThisHostname] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>]


### [Resolve-FormatParameter](Resolve-FormatParameter.md)

Resolve-FormatParameter [[-FileFormat] <string[]>] [[-OutputFormat] <string>]


### [Resolve-IdentityReferenceDomainDNS](Resolve-IdentityReferenceDomainDNS.md)

Resolve-IdentityReferenceDomainDNS [[-IdentityReference] <string>] [[-ItemPath] <Object>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-CimCache] <hashtable>]


### [Resolve-PermissionTarget](Resolve-PermissionTarget.md)

Resolve-PermissionTarget [[-TargetPath] <DirectoryInfo[]>] [[-CimCache] <hashtable>] [[-DebugOutputStream] <string>] [[-ThisHostname] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-Output] <hashtable>] [<CommonParameters>]


### [Select-UniquePrincipal](Select-UniquePrincipal.md)

Select-UniquePrincipal [[-PrincipalsByResolvedID] <hashtable>] [[-ExcludeAccount] <string[]>] [[-IgnoreDomain] <string[]>] [[-UniquePrincipal] <Object>] [[-UniquePrincipalsByResolvedID] <Object>]



