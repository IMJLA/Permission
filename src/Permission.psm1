
# Add any custom C# classes as usable (exported) types
$CSharpFiles = Get-ChildItem -Path "$PSScriptRoot\*.cs"
ForEach ($ThisFile in $CSharpFiles) {
    Add-Type -Path $ThisFile.FullName -ErrorAction Stop
}

Export-ModuleMember -Function @('Expand-Folder','Format-TimeSpan','Get-FolderAccessList','Get-FolderPermissionsBlock','Get-FolderTableHeader','Get-HtmlBody','Get-HtmlReportFooter','Get-PrtgXmlSensorOutput','Get-ReportDescription','Get-TimeZoneName','Select-FolderTableProperty','Select-UniqueAccountPermission','test','Update-CaptionCapitalization')


































