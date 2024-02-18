
# Add any custom C# classes as usable (exported) types
$CSharpFiles = Get-ChildItem -Path "$PSScriptRoot\*.cs"
ForEach ($ThisFile in $CSharpFiles) {
    Add-Type -Path $ThisFile.FullName -ErrorAction Stop
}

Export-ModuleMember -Function @('Add-CacheItem','ConvertTo-ItemBlock','Expand-AcctPermission','Expand-PermissionPrincipal','Expand-PermissionTarget','Export-FolderPermissionHtml','Export-RawPermissionCsv','Export-ResolvedPermissionCsv','Format-FolderPermission','Format-TimeSpan','Get-CachedCimInstance','Get-CachedCimSession','Get-FolderAccessList','Get-FolderColumnJson','Get-FolderPermissionsBlock','Get-FolderPermissionTableHeader','Get-FolderTableHeader','Get-HtmlBody','Get-HtmlReportFooter','Get-Permission','Get-PermissionPrincipal','Get-PrtgXmlSensorOutput','Get-ReportDescription','Get-TimeZoneName','Get-UniqueServerFqdn','Group-Permission','Initialize-Cache','Invoke-PermissionCommand','Remove-CachedCimSession','Resolve-AccessControlList','Resolve-Folder','Resolve-IdentityReferenceDomainDNS','Resolve-PermissionTarget','Select-FolderPermissionTableProperty','Select-ItemTableProperty','Select-UniquePrincipal','Update-CaptionCapitalization')



















































































































































































































