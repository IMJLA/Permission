
# Add any custom C# classes as usable (exported) types
$CSharpFiles = Get-ChildItem -Path "$PSScriptRoot\*.cs"
ForEach ($ThisFile in $CSharpFiles) {
    Add-Type -Path $ThisFile.FullName -ErrorAction Stop
}

Export-ModuleMember -Function @('Expand-AcctPermission','Expand-Folder','Expand-PermissionIdentity','Export-FolderPermissionHtml','Export-RawPermissionCsv','Export-ResolvedPermissionCsv','Format-FolderPermission','Format-PermissionAccount','Format-TimeSpan','Get-FolderAccessList','Get-FolderBlock','Get-FolderColumnJson','Get-FolderPermissionsBlock','Get-FolderPermissionTableHeader','Get-FolderTableHeader','Get-HtmlBody','Get-HtmlReportFooter','Get-PrtgXmlSensorOutput','Get-ReportDescription','Get-TimeZoneName','Get-UniqueServerFqdn','Initialize-Cache','Resolve-PermissionIdentity','Resolve-PermissionTarget','Select-FolderPermissionTableProperty','Select-FolderTableProperty','Select-UniqueAccountPermission','Update-CaptionCapitalization')



















































































































































