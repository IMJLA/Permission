---
Module Name: Permission
Module Guid: ded19ba7-2e6d-480e-9cf4-9c5bb56bbc0e
Download Help Link: {{ Update Download Link }}
Help Version: 0.0.980
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

ConvertTo-PermissionFqdn [-ComputerName] <string> [-Cache] <ref> [-ThisFqdn] [<CommonParameters>]

### [Expand-Permission](Expand-Permission.md)

Expand-Permission [[-SplitBy] <string[]>] [[-GroupBy] <string>] [[-Children] <hashtable>] [[-ThisHostName] <string>] [[-WhoAmI] <string>] [[-DebugOutputStream] <string>] [[-ProgressParentId] <int>] [-Cache] <ref> [<CommonParameters>]

### [Expand-PermissionTarget](Expand-PermissionTarget.md)

Expand-PermissionTarget [[-RecurseDepth] <int>] [-Cache] <ref> [<CommonParameters>]

### [Find-CachedCimInstance](Find-CachedCimInstance.md)

Find-CachedCimInstance [[-ComputerName] <string>] [[-Key] <string>] [[-CimCache] <hashtable>] [[-Log] <hashtable>] [[-CacheToSearch] <string[]>]

### [Find-ResolvedIDsWithAccess](Find-ResolvedIDsWithAccess.md)

Find-ResolvedIDsWithAccess [[-ItemPath] <Object>] [[-AceGUIDsByPath] <ref>] [[-ACEsByGUID] <ref>] [[-PrincipalsByResolvedID] <ref>]

### [Find-ServerFqdn](Find-ServerFqdn.md)

Find-ServerFqdn [[-Known] <string[]>] [[-ProgressParentId] <int>] [[-ParentCount] <ulong>] [-Cache] <ref> [<CommonParameters>]

### [Format-Permission](Format-Permission.md)

Format-Permission [[-Permission] <psobject>] [[-IgnoreDomain] <string[]>] [[-GroupBy] <string>] [[-FileFormat] <string[]>] [[-OutputFormat] <string>] [[-Culture] <cultureinfo>] [[-ProgressParentId] <int>] [-Cache] <ref> [[-AccountProperty] <string[]>] [<CommonParameters>]

### [Format-TimeSpan](Format-TimeSpan.md)

Format-TimeSpan [[-TimeSpan] <timespan>] [[-UnitsToResolve] <string[]>]

### [Get-AccessControlList](Get-AccessControlList.md)

Get-AccessControlList [[-TargetPath] <hashtable>] [[-WarningCache] <hashtable>] [-Cache] <ref> [<CommonParameters>]

### [Get-CachedCimInstance](Get-CachedCimInstance.md)

Get-CachedCimInstance [[-ComputerName] <string>] [[-ClassName] <string>] [[-Namespace] <string>] [[-Query] <string>] [-KeyProperty] <string> [[-CacheByProperty] <string[]>] [-Cache] <ref> [<CommonParameters>]

### [Get-CachedCimSession](Get-CachedCimSession.md)

Get-CachedCimSession [[-ComputerName] <string>] [-Cache] <ref> [<CommonParameters>]

### [Get-PermissionPrincipal](Get-PermissionPrincipal.md)

Get-PermissionPrincipal [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-ThisFqdn] <string>] [[-ThisHostName] <string>] [[-WhoAmI] <string>] [[-ProgressParentId] <int>] [-Cache] <ref> [[-CurrentDomain] <psobject>] [[-AccountProperty] <string[]>] [-NoGroupMembers] [<CommonParameters>]

### [Get-PermissionTrustedDomain](Get-PermissionTrustedDomain.md)

Get-PermissionTrustedDomain [-Cache] <ref> [<CommonParameters>]

### [Get-PermissionWhoAmI](Get-PermissionWhoAmI.md)

Get-PermissionWhoAmI [[-ThisHostname] <string>]

### [Get-TimeZoneName](Get-TimeZoneName.md)

Get-TimeZoneName [[-Time] <datetime>] [[-TimeZone] <ciminstance>]

### [Initialize-Cache](Initialize-Cache.md)

Initialize-Cache [[-Fqdn] <string[]>] [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-ProgressParentId] <int>] [-Cache] <ref> [<CommonParameters>]

### [Invoke-PermissionAnalyzer](Invoke-PermissionAnalyzer.md)

Invoke-PermissionAnalyzer [[-AllowDisabledInheritance] <hashtable>] [[-AccountConvention] <scriptblock>] [-Cache] <ref> [<CommonParameters>]

### [Invoke-PermissionCommand](Invoke-PermissionCommand.md)

Invoke-PermissionCommand [[-Command] <string>]

### [New-PermissionCache](New-PermissionCache.md)

New-PermissionCache [[-ThreadCount] <ushort>] [[-OutputDir] <string>] [[-ReportInstanceId] <guid>] [[-TranscriptFile] <string>]

### [Out-Permission](Out-Permission.md)

Out-Permission [[-OutputFormat] <string>] [[-GroupBy] <string>] [[-FormattedPermission] <hashtable>]

### [Out-PermissionFile](Out-PermissionFile.md)

Out-PermissionFile [[-ExcludeAccount] <string[]>] [[-ExcludeClass] <string[]>] [[-IgnoreDomain] <Object>] [[-TargetPath] <string[]>] [[-OutputDir] <Object>] [[-WhoAmI] <string>] [[-ThisFqdn] <Object>] [[-StopWatch] <Object>] [[-Title] <Object>] [[-Permission] <Object>] [[-FormattedPermission] <Object>] [[-LogParams] <Object>] [[-RecurseDepth] <Object>] [[-LogFileList] <Object>] [[-ReportInstanceId] <Object>] [[-Detail] <int[]>] [[-Culture] <cultureinfo>] [[-FileFormat] <string[]>] [[-OutputFormat] <string>] [[-GroupBy] <string>] [[-SplitBy] <string[]>] [[-BestPracticeEval] <psobject>] [[-TargetCount] <ulong>] [[-ParentCount] <ulong>] [[-ChildCount] <ulong>] [[-ItemCount] <ulong>] [[-FqdnCount] <ulong>] [[-AclCount] <ulong>] [[-AceCount] <ulong>] [[-IdCount] <ulong>] [[-PrincipalCount] <ulong>] [-Cache] <ref> [-NoMembers] [<CommonParameters>]

### [Remove-CachedCimSession](Remove-CachedCimSession.md)

Remove-CachedCimSession [[-CimCache] <hashtable>]

### [Resolve-AccessControlList](Resolve-AccessControlList.md)

Resolve-AccessControlList [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-ProgressParentId] <int>] [[-InheritanceFlagResolved] <string[]>] [-Cache] <ref> [[-AccountProperty] <string[]>] [<CommonParameters>]

### [Resolve-PermissionTarget](Resolve-PermissionTarget.md)

Resolve-PermissionTarget [[-TargetPath] <DirectoryInfo[]>] [-Cache] <ref> [<CommonParameters>]

### [Select-PermissionPrincipal](Select-PermissionPrincipal.md)

Select-PermissionPrincipal [[-ExcludeAccount] <string[]>] [[-IncludeAccount] <string[]>] [[-IgnoreDomain] <string[]>] [[-ProgressParentId] <int>] [[-ThisHostName] <string>] [[-WhoAmI] <string>] [-Cache] <ref> [<CommonParameters>]


