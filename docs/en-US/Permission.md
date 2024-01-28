---
Module Name: Permission
Module Guid: ded19ba7-2e6d-480e-9cf4-9c5bb56bbc0e
Download Help Link: {{ Update Download Link }}
Help Version: 0.0.74
Locale: en-US
---

# Permission Module
## Description
Module for working with Access Control Lists

## Permission Cmdlets
### [Expand-Folder](Expand-Folder.md)

Expand-Folder [[-Folder] <Object>] [[-LevelsOfSubfolders] <Object>] [[-ThreadCount] <ushort>] [[-DebugOutputStream] <string>] [[-TodaysHostname] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>]


### [Export-FolderPermissionHtml](Export-FolderPermissionHtml.md)

Export-FolderPermissionHtml [[-ExcludeAccount] <Object>] [[-ExcludeClass] <string[]>] [[-IgnoreDomain] <Object>] [[-TargetPath] <string[]>] [[-NoGroupMembers] <Object>] [[-OutputDir] <Object>] [[-WhoAmI] <Object>] [[-ThisFqdn] <Object>] [[-StopWatch] <Object>] [[-Title] <Object>] [[-FolderPermissions] <Object>] [[-LogParams] <Object>] [[-ReportDescription] <Object>] [[-FolderTableHeader] <Object>] [[-ReportFileList] <Object>] [[-ReportFile] <Object>] [[-LogFileList] <Object>] [[-ReportInstanceId] <Object>] [[-Subfolders] <Object>] [[-ResolvedFolderTargets] <Object>] [-NoJavaScript]


### [Format-TimeSpan](Format-TimeSpan.md)

Format-TimeSpan [[-TimeSpan] <timespan>] [[-UnitsToResolve] <string[]>]


### [Get-FolderAccessList](Get-FolderAccessList.md)

Get-FolderAccessList [[-Folder] <Object>] [[-Subfolder] <Object>] [[-ThreadCount] <ushort>] [[-DebugOutputStream] <string>] [[-TodaysHostname] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [[-OwnerCache] <ConcurrentDictionary[string,psobject]>]


### [Get-FolderBlock](Get-FolderBlock.md)

Get-FolderBlock [[-FolderPermissions] <Object>]


### [Get-FolderColumnJson](Get-FolderColumnJson.md)

Get-FolderColumnJson [[-InputObject] <Object>] [[-PropNames] <string[]>]


### [Get-FolderPermissionsBlock](Get-FolderPermissionsBlock.md)

Get-FolderPermissionsBlock [[-FolderPermissions] <Object>] [[-ExcludeAccount] <string[]>] [[-ExcludeClass] <string[]>] [[-IgnoreDomain] <string[]>]


### [Get-FolderPermissionTableHeader](Get-FolderPermissionTableHeader.md)

Get-FolderPermissionTableHeader [[-ThisFolder] <Object>] [[-ShortestFolderPath] <string>]


### [Get-FolderTableHeader](Get-FolderTableHeader.md)

Get-FolderTableHeader [[-LevelsOfSubfolders] <Object>]


### [Get-HtmlBody](Get-HtmlBody.md)

Get-HtmlBody [[-FolderList] <Object>] [[-HtmlFolderPermissions] <Object>] [[-ReportFooter] <Object>] [[-HtmlFileList] <Object>] [[-LogDir] <Object>] [[-HtmlExclusions] <Object>]


### [Get-HtmlReportFooter](Get-HtmlReportFooter.md)

Get-HtmlReportFooter [[-StopWatch] <Stopwatch>] [[-WhoAmI] <string>] [[-ThisFqdn] <string>] [[-ItemCount] <ulong>] [[-TotalBytes] <ulong>] [[-ReportInstanceId] <string>]


### [Get-PrtgXmlSensorOutput](Get-PrtgXmlSensorOutput.md)

Get-PrtgXmlSensorOutput [[-NtfsIssues] <Object>]


### [Get-ReportDescription](Get-ReportDescription.md)

Get-ReportDescription [[-LevelsOfSubfolders] <Object>]


### [Get-TimeZoneName](Get-TimeZoneName.md)

Get-TimeZoneName [[-Time] <datetime>] [[-TimeZone] <ciminstance>]


### [Select-FolderPermissionTableProperty](Select-FolderPermissionTableProperty.md)

Select-FolderPermissionTableProperty [[-InputObject] <Object>] [[-IgnoreDomain] <Object>]


### [Select-FolderTableProperty](Select-FolderTableProperty.md)

Select-FolderTableProperty [[-InputObject] <Object>]


### [Select-UniqueAccountPermission](Select-UniqueAccountPermission.md)

Select-UniqueAccountPermission [[-AccountPermission] <Object>] [[-IgnoreDomain] <string[]>] [[-KnownUsers] <Object>] [<CommonParameters>]


### [Update-CaptionCapitalization](Update-CaptionCapitalization.md)

Update-CaptionCapitalization [[-ThisHostName] <string>] [[-Win32AccountsByCaption] <hashtable>]



