---
Module Name: Permission
Module Guid: ded19ba7-2e6d-480e-9cf4-9c5bb56bbc0e
Download Help Link: {{ Update Download Link }}
Help Version: 0.0.1230
Locale: en-US
---

# Permission Module
## Description
Module for working with Access Control Lists
## Permission Cmdlets
### [Add-CacheItem](Add-CacheItem.md)

Add-CacheItem [-Cache] <hashtable> [-Key] <Object> [[-Value] <Object>] [[-Type] <type>] [<CommonParameters>]

### [Add-PermissionCacheItem](Add-PermissionCacheItem.md)

Add-PermissionCacheItem [-Cache] <ref> [-Key] <Object> [[-Value] <Object>] [[-Type] <type>] [<CommonParameters>]

### [ConvertTo-ItemBlock](ConvertTo-ItemBlock.md)

ConvertTo-ItemBlock [[-ItemPermissions] <Object>] [-Cache] <ref> [<CommonParameters>]

### [ConvertTo-PermissionFqdn](ConvertTo-PermissionFqdn.md)

ConvertTo-PermissionFqdn [-ComputerName] <string> [-Cache] <ref> [-ThisFqdn] [<CommonParameters>]

### [Expand-Permission](Expand-Permission.md)

Expand-Permission [[-SplitBy] <string[]>] [[-GroupBy] <string>] [[-Children] <hashtable>] [-Cache] <ref> [<CommonParameters>]

### [Expand-PermissionSource](Expand-PermissionSource.md)

Expand-PermissionSource [[-RecurseDepth] <int>] [-Cache] <ref> [<CommonParameters>]

### [Find-CachedCimInstance](Find-CachedCimInstance.md)

Find-CachedCimInstance [[-ComputerName] <string>] [[-Key] <string>] [[-CimCache] <hashtable>] [[-Log] <hashtable>] [[-CacheToSearch] <string[]>]

### [Find-ResolvedIDsWithAccess](Find-ResolvedIDsWithAccess.md)

Find-ResolvedIDsWithAccess [[-ItemPath] <Object>] [[-AceGUIDsByPath] <ref>] [[-ACEsByGUID] <ref>] [[-PrincipalsByResolvedID] <ref>]

### [Find-ServerFqdn](Find-ServerFqdn.md)

Find-ServerFqdn [[-ParentCount] <ulong>] [-Cache] <ref> [<CommonParameters>]

### [Format-Permission](Format-Permission.md)

Format-Permission [[-Permission] <psobject>] [[-IgnoreDomain] <string[]>] [[-GroupBy] <string>] [[-FileFormat] <string[]>] [[-OutputFormat] <string>] [-Cache] <ref> [[-AccountProperty] <string[]>] [[-Analysis] <psobject>] [<CommonParameters>]

### [Format-TimeSpan](Format-TimeSpan.md)

Format-TimeSpan [[-TimeSpan] <timespan>] [[-UnitsToResolve] <string[]>]

### [Get-AccessControlList](Get-AccessControlList.md)

Get-AccessControlList [[-SourcePath] <hashtable>] [[-WarningCache] <hashtable>] [-Cache] <ref> [<CommonParameters>]

### [Get-CachedCimInstance](Get-CachedCimInstance.md)

Get-CachedCimInstance [[-ComputerName] <string>] [[-ClassName] <string>] [[-Namespace] <string>] [[-Query] <string>] [-KeyProperty] <string> [[-CacheByProperty] <string[]>] [-Cache] <ref> [<CommonParameters>]

### [Get-CachedCimSession](Get-CachedCimSession.md)

Get-CachedCimSession [[-ComputerName] <string>] [-Cache] <ref> [<CommonParameters>]

### [Get-PermissionPrincipal](Get-PermissionPrincipal.md)

Get-PermissionPrincipal [-Cache] <ref> [[-AccountProperty] <string[]>] [-NoGroupMembers] [<CommonParameters>]

### [Get-PermissionTrustedDomain](Get-PermissionTrustedDomain.md)

Get-PermissionTrustedDomain [-Cache] <ref> [<CommonParameters>]

### [Get-PermissionWhoAmI](Get-PermissionWhoAmI.md)

Get-PermissionWhoAmI [[-ThisHostname] <string>]

### [Get-TimeZoneName](Get-TimeZoneName.md)

Get-TimeZoneName [[-Time] <datetime>] [[-TimeZone] <ciminstance>]

### [Initialize-PermissionCache](Initialize-PermissionCache.md)

Initialize-PermissionCache [[-ThreadCount] <ushort>] [[-OutputDir] <string>] [[-TranscriptFile] <string>]

### [Invoke-PermissionAnalyzer](Invoke-PermissionAnalyzer.md)

Invoke-PermissionAnalyzer [[-AllowDisabledInheritance] <hashtable>] [[-AccountConvention] <scriptblock>] [-Cache] <ref> [<CommonParameters>]

### [Invoke-PermissionCommand](Invoke-PermissionCommand.md)

Invoke-PermissionCommand [[-Command] <string>] [-Cache] <ref> [<CommonParameters>]

### [Optimize-PermissionCache](Optimize-PermissionCache.md)

Optimize-PermissionCache [[-Fqdn] <string[]>] [-Cache] <ref> [<CommonParameters>]

### [Out-Permission](Out-Permission.md)

Out-Permission [[-OutputFormat] <string>] [[-GroupBy] <string>] [[-FormattedPermission] <hashtable>]

### [Out-PermissionFile](Out-PermissionFile.md)

Out-PermissionFile [[-OutputDir] <Object>] [[-StopWatch] <Object>] [[-Analysis] <psobject>] [-Cache] <ref> [[-ParameterDict] <hashtable>] [[-Permission] <Object>] [[-FormattedPermission] <Object>] [[-LogFileList] <Object>] [[-ReportInstanceId] <Object>] [[-SourceCount] <ulong>] [[-ParentCount] <ulong>] [[-ChildCount] <ulong>] [[-ItemCount] <ulong>] [[-FqdnCount] <ulong>] [[-AclCount] <ulong>] [[-AceCount] <ulong>] [[-IdCount] <ulong>] [[-PrincipalCount] <ulong>] [<CommonParameters>]

### [Remove-CachedCimSession](Remove-CachedCimSession.md)

Remove-CachedCimSession [[-CimCache] <hashtable>]

### [Resolve-AccessControlList](Resolve-AccessControlList.md)

Resolve-AccessControlList [-Cache] <ref> [[-AccountProperty] <string[]>] [<CommonParameters>]

### [Resolve-PermissionSource](Resolve-PermissionSource.md)

Resolve-PermissionSource [[-SourcePath] <DirectoryInfo[]>] [-Cache] <ref> [<CommonParameters>]

### [Select-PermissionPrincipal](Select-PermissionPrincipal.md)

Select-PermissionPrincipal [[-ExcludeAccount] <string[]>] [[-IncludeAccount] <string[]>] [[-IgnoreDomain] <string[]>] [-Cache] <ref> [<CommonParameters>]


