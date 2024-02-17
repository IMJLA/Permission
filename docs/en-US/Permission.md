---
Module Name: Permission
Module Guid: ded19ba7-2e6d-480e-9cf4-9c5bb56bbc0e ded19ba7-2e6d-480e-9cf4-9c5bb56bbc0e
Download Help Link: {{ Update Download Link }}
Help Version: 0.0.203
Locale: en-US
---

# Permission Module
## Description
Module for working with Access Control Lists

## Permission Cmdlets
### [Expand-AcctPermission](Expand-AcctPermission.md)

Expand-AcctPermission [[-SecurityPrincipal] <Object[]>] [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-ThisHostName] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ProgressParentId] <int>] [<CommonParameters>]


### [Expand-PermissionPrincipal](Expand-PermissionPrincipal.md)

Expand-PermissionPrincipal [[-PrincipalsByResolvedID] <hashtable>] [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-ThisHostName] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ProgressParentId] <int>]


### [Expand-PermissionTarget](Expand-PermissionTarget.md)

Expand-PermissionTarget [[-RecurseDepth] <Object>] [[-ThreadCount] <ushort>] [[-DebugOutputStream] <string>] [[-ThisHostname] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ProgressParentId] <int>] [[-ACLsByPath] <hashtable>]


### [Export-FolderPermissionHtml](Export-FolderPermissionHtml.md)

Export-FolderPermissionHtml [[-ExcludeAccount] <Object>] [[-ExcludeClass] <string[]>] [[-IgnoreDomain] <Object>] [[-TargetPath] <string[]>] [[-NoGroupMembers] <Object>] [[-OutputDir] <Object>] [[-WhoAmI] <Object>] [[-ThisFqdn] <Object>] [[-StopWatch] <Object>] [[-Title] <Object>] [[-FolderPermissions] <Object>] [[-LogParams] <Object>] [[-ReportDescription] <Object>] [[-FolderTableHeader] <Object>] [[-ReportFileList] <Object>] [[-ReportFile] <Object>] [[-LogFileList] <Object>] [[-ReportInstanceId] <Object>] [[-Subfolders] <Object>] [[-ResolvedFolderTargets] <Object>] [[-ExpandedAccountPermissions] <Object>] [[-PrincipalsByResolvedID] <Object>] [-NoJavaScript]


### [Export-RawPermissionCsv](Export-RawPermissionCsv.md)

Export-RawPermissionCsv [[-Permission] <Object[]>] [[-LiteralPath] <string>] [[-DebugOutputStream] <string>] [[-ThisHostname] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ProgressParentId] <int>]


### [Export-ResolvedPermissionCsv](Export-ResolvedPermissionCsv.md)

Export-ResolvedPermissionCsv [[-Permission] <Object[]>] [[-LiteralPath] <string>] [[-DebugOutputStream] <string>] [[-ThisHostname] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ProgressParentId] <int>]


### [Format-FolderPermission](Format-FolderPermission.md)

Format-FolderPermission [[-UserPermission] <Object>] [[-FileSystemRightsToIgnore] <string[]>] [[-ThisHostName] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ProgressParentId] <int>]


### [Format-TimeSpan](Format-TimeSpan.md)

Format-TimeSpan [[-TimeSpan] <timespan>] [[-UnitsToResolve] <string[]>]


### [Get-CachedCimInstance](Get-CachedCimInstance.md)

Get-CachedCimInstance [[-ComputerName] <string>] [[-ClassName] <string>] [[-Query] <string>] [[-CimCache] <hashtable>] [[-DebugOutputStream] <string>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>]


### [Get-CachedCimSession](Get-CachedCimSession.md)

Get-CachedCimSession [[-ComputerName] <string>] [[-CimCache] <hashtable>] [[-DebugOutputStream] <string>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>]


### [Get-FolderAccessList](Get-FolderAccessList.md)

Get-FolderAccessList [[-Folder] <Object>] [[-Subfolder] <Object>] [[-ThreadCount] <ushort>] [[-DebugOutputStream] <string>] [[-TodaysHostname] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-OwnerCache] <ConcurrentDictionary[string,psobject]>] [[-ProgressParentId] <int>] [[-ACLsByPath] <hashtable>]


### [Get-FolderBlock](Get-FolderBlock.md)

Get-FolderBlock [[-FolderPermissions] <Object>]


### [Get-FolderColumnJson](Get-FolderColumnJson.md)

Get-FolderColumnJson [[-InputObject] <Object>] [[-PropNames] <string[]>]


### [Get-FolderPermissionsBlock](Get-FolderPermissionsBlock.md)

Get-FolderPermissionsBlock [[-FolderPermissions] <Object>] [[-ExcludeAccount] <string[]>] [[-ExcludeClass] <string[]>] [[-IgnoreDomain] <string[]>]


### [Get-FolderPermissionTableHeader](Get-FolderPermissionTableHeader.md)

Get-FolderPermissionTableHeader [[-ThisFolder] <Object>] [[-ShortestFolderPath] <string>]


### [Get-FolderTableHeader](Get-FolderTableHeader.md)

Get-FolderTableHeader [[-RecurseDepth] <Object>]


### [Get-HtmlBody](Get-HtmlBody.md)

Get-HtmlBody [[-FolderList] <Object>] [[-HtmlFolderPermissions] <Object>] [[-ReportFooter] <Object>] [[-HtmlFileList] <Object>] [[-LogDir] <Object>] [[-HtmlExclusions] <Object>]


### [Get-HtmlReportFooter](Get-HtmlReportFooter.md)

Get-HtmlReportFooter [[-StopWatch] <Stopwatch>] [[-WhoAmI] <string>] [[-ThisFqdn] <string>] [[-ItemCount] <ulong>] [[-TotalBytes] <ulong>] [[-ReportInstanceId] <string>] [[-PermissionCount] <ulong>] [[-PrincipalCount] <ulong>]


### [Get-Permission](Get-Permission.md)

Get-Permission [[-Folder] <Object>] [[-Subfolder] <Object>] [[-ThreadCount] <ushort>] [[-DebugOutputStream] <string>] [[-ThisHostname] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-CimCache] <hashtable>] [[-Win32AccountsBySID] <hashtable>] [[-Win32AccountsByCaption] <hashtable>] [[-DirectoryEntryCache] <hashtable>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-DomainsByFqdn] <hashtable>] [[-LogMsgCache] <hashtable>] [[-OwnerCache] <ConcurrentDictionary[string,psobject]>] [[-ProgressParentId] <int>] [[-KnownFqdn] <string[]>]


### [Get-PermissionPrincipal](Get-PermissionPrincipal.md)

Get-PermissionPrincipal [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-PrincipalsByResolvedID] <hashtable>] [[-ACEsByResolvedID] <hashtable>] [[-CimCache] <hashtable>] [[-DirectoryEntryCache] <hashtable>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-DomainsByFqdn] <hashtable>] [[-Win32AccountsByCaption] <hashtable>] [[-Win32AccountsBySID] <hashtable>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ProgressParentId] <int>] [[-CurrentDomain] <string>] [-NoGroupMembers]


### [Get-PrtgXmlSensorOutput](Get-PrtgXmlSensorOutput.md)

Get-PrtgXmlSensorOutput [[-NtfsIssues] <Object>]


### [Get-ReportDescription](Get-ReportDescription.md)

Get-ReportDescription [[-RecurseDepth] <Object>]


### [Get-TimeZoneName](Get-TimeZoneName.md)

Get-TimeZoneName [[-Time] <datetime>] [[-TimeZone] <ciminstance>]


### [Get-UniqueServerFqdn](Get-UniqueServerFqdn.md)

Get-UniqueServerFqdn [[-Known] <string[]>] [[-FilePath] <string[]>] [[-ThisFqdn] <string>] [[-ProgressParentId] <int>]


### [Group-Permission](Group-Permission.md)

Group-Permission [[-InputObject] <Object[]>] [[-Property] <string>]


### [Initialize-Cache](Initialize-Cache.md)

Initialize-Cache [[-Fqdn] <string[]>] [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-CimCache] <hashtable>] [[-Win32AccountsBySID] <hashtable>] [[-Win32AccountsByCaption] <hashtable>] [[-DirectoryEntryCache] <hashtable>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-DomainsByFqdn] <hashtable>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ProgressParentId] <int>] [<CommonParameters>]


### [Invoke-PermissionCommand](Invoke-PermissionCommand.md)

Invoke-PermissionCommand [[-Command] <string>]


### [Remove-CachedCimSession](Remove-CachedCimSession.md)

Remove-CachedCimSession [[-CimCache] <hashtable>]


### [Resolve-AccessList](Resolve-AccessList.md)

Resolve-AccessList [[-AccessList] <Object[]>] [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-CimCache] <hashtable>] [[-DirectoryEntryCache] <hashtable>] [[-DomainsByFqdn] <hashtable>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-Win32AccountsBySID] <hashtable>] [[-Win32AccountsByCaption] <hashtable>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ProgressParentId] <int>] [<CommonParameters>]


### [Resolve-Folder](Resolve-Folder.md)

Resolve-Folder [[-TargetPath] <string>] [[-CimCache] <hashtable>] [[-DebugOutputStream] <string>] [[-ThisHostname] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>]


### [Resolve-PermissionIdentity](Resolve-PermissionIdentity.md)

Resolve-PermissionIdentity [[-ACLsByPath] <hashtable>] [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-ACEsByGUID] <hashtable>] [[-AceGUIDsByResolvedID] <hashtable>] [[-AceGUIDsByPath] <hashtable>] [[-CimCache] <hashtable>] [[-DirectoryEntryCache] <hashtable>] [[-DomainsByFqdn] <hashtable>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-Win32AccountsByCaption] <hashtable>] [[-Win32AccountsBySID] <hashtable>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ProgressParentId] <int>]


### [Resolve-PermissionTarget](Resolve-PermissionTarget.md)

Resolve-PermissionTarget [[-TargetPath] <DirectoryInfo[]>] [[-CimCache] <hashtable>] [[-DebugOutputStream] <string>] [[-ThisHostname] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ACLsByPath] <hashtable>] [<CommonParameters>]


### [Select-FolderPermissionTableProperty](Select-FolderPermissionTableProperty.md)

Select-FolderPermissionTableProperty [[-InputObject] <Object>] [[-IgnoreDomain] <Object>]


### [Select-FolderTableProperty](Select-FolderTableProperty.md)

Select-FolderTableProperty [[-InputObject] <Object>]


### [Select-UniquePrincipal](Select-UniquePrincipal.md)

Select-UniquePrincipal [[-PrincipalsByResolvedID] <hashtable>] [[-ExcludeAccount] <string[]>] [[-IgnoreDomain] <string[]>] [[-UniquePrincipal] <Object>] [[-UniquePrincipalsByResolvedID] <Object>]


### [Update-CaptionCapitalization](Update-CaptionCapitalization.md)

Update-CaptionCapitalization [[-ThisHostName] <string>] [[-Win32AccountsByCaption] <hashtable>]



