
# Add any custom C# classes as usable (exported) types
$CSharpFiles = Get-ChildItem -Path "$PSScriptRoot\*.cs"
ForEach ($ThisFile in $CSharpFiles) {
    Add-Type -Path $ThisFile.FullName -ErrorAction Stop
}

Export-ModuleMember -Function @('Expand-Folder','Export-FolderPermissionHtml','Format-TimeSpan','Get-FolderAccessList','Get-FolderBlock','Get-FolderColumnJson','Get-FolderPermissionsBlock','Get-FolderPermissionTableHeader','Get-FolderTableHeader','Get-HtmlBody','Get-HtmlReportFooter','Get-PrtgXmlSensorOutput','Get-ReportDescription','Get-TimeZoneName','Select-FolderPermissionTableProperty','Select-FolderTableProperty','Select-UniqueAccountPermission','test','Update-CaptionCapitalization')



















































