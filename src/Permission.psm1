
# Add any custom C# classes as usable (exported) types
$CSharpFiles = Get-ChildItem -Path "$PSScriptRoot\*.cs"
ForEach ($ThisFile in $CSharpFiles) {
    Add-Type -Path $ThisFile.FullName -ErrorAction Stop
}

Export-ModuleMember -Function @('Get-FolderAccessList','Get-FolderPermissionsBlock','Get-FolderTableHeader','Get-HtmlBody','Get-HtmlFolderList','Get-PrtgXmlSensorOutput','Get-ReportDescription','Select-FolderTableProperty')












