---
Module Name: Permission
Module Guid: ded19ba7-2e6d-480e-9cf4-9c5bb56bbc0e
Download Help Link: {{ Update Download Link }}
Help Version: 0.0.169
Locale: en-US
---

# Permission Module
## Description
Module for working with Access Control Lists

## Permission Cmdlets
### [Expand-AcctPermission](Expand-AcctPermission.md)

Expand-AcctPermission [[-SecurityPrincipal] <Object[]>] [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-ThisHostName] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ProgressParentId] <int>] [<CommonParameters>]


### [Expand-Folder](Expand-Folder.md)

Expand-Folder [[-Folder] <Object>] [[-RecurseDepth] <Object>] [[-ThreadCount] <ushort>] [[-DebugOutputStream] <string>] [[-ThisHostname] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ProgressParentId] <int>]


### [Export-FolderPermissionHtml](Export-FolderPermissionHtml.md)

Export-FolderPermissionHtml [[-ExcludeAccount] <Object>] [[-ExcludeClass] <string[]>] [[-IgnoreDomain] <Object>] [[-TargetPath] <string[]>] [[-NoGroupMembers] <Object>] [[-OutputDir] <Object>] [[-WhoAmI] <Object>] [[-ThisFqdn] <Object>] [[-StopWatch] <Object>] [[-Title] <Object>] [[-FolderPermissions] <Object>] [[-LogParams] <Object>] [[-ReportDescription] <Object>] [[-FolderTableHeader] <Object>] [[-ReportFileList] <Object>] [[-ReportFile] <Object>] [[-LogFileList] <Object>] [[-ReportInstanceId] <Object>] [[-Subfolders] <Object>] [[-ResolvedFolderTargets] <Object>] [-NoJavaScript]


### [Export-RawPermissionCsv](Export-RawPermissionCsv.md)

Export-RawPermissionCsv [[-Permission] <Object[]>] [[-LiteralPath] <string>] [[-DebugOutputStream] <string>] [[-ThisHostname] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ProgressParentId] <int>]


### [Export-ResolvedPermissionCsv](Export-ResolvedPermissionCsv.md)

Export-ResolvedPermissionCsv [[-Permission] <Object[]>] [[-LiteralPath] <string>] [[-DebugOutputStream] <string>] [[-ThisHostname] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ProgressParentId] <int>]


### [Format-FolderPermission](Format-FolderPermission.md)

Format-FolderPermission [[-UserPermission] <Object>] [[-FileSystemRightsToIgnore] <string[]>] [[-ThisHostName] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ProgressParentId] <int>]


### [Format-PermissionAccount](Format-PermissionAccount.md)

Format-PermissionAccount [[-SecurityPrincipal] <Object[]>] [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-ThisHostName] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ProgressParentId] <int>] [<CommonParameters>]


### [Format-TimeSpan](Format-TimeSpan.md)

Format-TimeSpan [[-TimeSpan] <timespan>] [[-UnitsToResolve] <string[]>]


### [Get-CachedCimInstance](Get-CachedCimInstance.md)

Get-CachedCimInstance [[-ComputerName] <string>] [[-ClassName] <string>] [[-Query] <string>] [[-CimCache] <hashtable>] [[-DebugOutputStream] <string>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>]


### [Get-CachedCimSession](Get-CachedCimSession.md)

Get-CachedCimSession [[-ComputerName] <string>] [[-CimCache] <hashtable>] [[-DebugOutputStream] <string>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>]


### [Get-FolderAccessList](Get-FolderAccessList.md)

Get-FolderAccessList [[-Folder] <Object>] [[-Subfolder] <Object>] [[-ThreadCount] <ushort>] [[-DebugOutputStream] <string>] [[-TodaysHostname] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-OwnerCache] <ConcurrentDictionary[string,psobject]>] [[-ProgressParentId] <int>]


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

Get-HtmlReportFooter [[-StopWatch] <Stopwatch>] [[-WhoAmI] <string>] [[-ThisFqdn] <string>] [[-ItemCount] <ulong>] [[-TotalBytes] <ulong>] [[-ReportInstanceId] <string>]


### [Get-PermissionPrincipal](Get-PermissionPrincipal.md)

Get-PermissionPrincipal [[-Identity] <Object[]>] [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-CimCache] <hashtable>] [[-Win32AccountsBySID] <hashtable>] [[-Win32AccountsByCaption] <hashtable>] [[-DirectoryEntryCache] <hashtable>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-DomainsByFqdn] <hashtable>] [[-IdentityCache] <hashtable>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ProgressParentId] <int>] [-NoGroupMembers] [<CommonParameters>]


### [Get-PrtgXmlSensorOutput](Get-PrtgXmlSensorOutput.md)

Get-PrtgXmlSensorOutput [[-NtfsIssues] <Object>]


### [Get-ReportDescription](Get-ReportDescription.md)

Get-ReportDescription [[-RecurseDepth] <Object>]


### [Get-TimeZoneName](Get-TimeZoneName.md)

Get-TimeZoneName [[-Time] <datetime>] [[-TimeZone] <ciminstance>]


### [Get-UniqueServerFqdn](Get-UniqueServerFqdn.md)

Get-UniqueServerFqdn [[-Known] <string[]>] [[-FilePath] <string[]>] [[-ThisFqdn] <string>] [[-ProgressParentId] <int>]


### [Initialize-Cache](Initialize-Cache.md)

Initialize-Cache [[-Fqdn] <string[]>] [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-CimCache] <hashtable>] [[-Win32AccountsBySID] <hashtable>] [[-Win32AccountsByCaption] <hashtable>] [[-DirectoryEntryCache] <hashtable>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-DomainsByFqdn] <hashtable>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-ProgressParentId] <int>] [<CommonParameters>]


### [Invoke-PermissionCommand](Invoke-PermissionCommand.md)

Invoke-PermissionCommand [[-Command] <string>]


### [Remove-CachedCimSession](Remove-CachedCimSession.md)

Remove-CachedCimSession [[-CimCache] <hashtable>]


### [Resolve-Folder](Resolve-Folder.md)

Resolve-Folder [[-TargetPath] <string>] [[-CimCache] <hashtable>] [[-DebugOutputStream] <string>] [[-ThisHostname] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>]


### [Resolve-PermissionIdentity](Resolve-PermissionIdentity.md)

Resolve-PermissionIdentity [[-Permission] <Object[]>] [[-DebugOutputStream] <string>] [[-ThreadCount] <int>] [[-Win32AccountsBySID] <hashtable>] [[-Win32AccountsByCaption] <hashtable>] [[-DirectoryEntryCache] <hashtable>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-DomainsByFqdn] <hashtable>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-CimCache] <hashtable>] [[-ProgressParentId] <int>] [<CommonParameters>]


### [Resolve-PermissionTarget](Resolve-PermissionTarget.md)

Resolve-PermissionTarget [[-TargetPath] <DirectoryInfo[]>] [[-CimCache] <hashtable>] [[-DebugOutputStream] <string>] [[-ThisHostname] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [<CommonParameters>]


### [Select-FolderPermissionTableProperty](Select-FolderPermissionTableProperty.md)

Select-FolderPermissionTableProperty [[-InputObject] <Object>] [[-IgnoreDomain] <Object>]


### [Select-FolderTableProperty](Select-FolderTableProperty.md)

Select-FolderTableProperty [[-InputObject] <Object>]


### [Select-UniqueAccountPermission](Select-UniqueAccountPermission.md)

Select-UniqueAccountPermission [[-AccountPermission] <Object>] [[-IgnoreDomain] <string[]>] [[-KnownUsers] <Object>] [<CommonParameters>]


### [Update-CaptionCapitalization](Update-CaptionCapitalization.md)

Update-CaptionCapitalization [[-ThisHostName] <string>] [[-Win32AccountsByCaption] <hashtable>]



