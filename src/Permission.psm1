
# Add any custom C# classes as usable (exported) types
$CSharpFiles = Get-ChildItem -Path "$PSScriptRoot\*.cs"
ForEach ($ThisFile in $CSharpFiles) {
    Add-Type -Path $ThisFile.FullName -ErrorAction Stop
}

Export-ModuleMember -Function @('Add-CacheItem','ConvertTo-ItemBlock','Expand-Permission','Expand-PermissionTarget','Export-FolderPermissionHtml','Export-RawPermissionCsv','Export-ResolvedPermissionCsv','Find-ResolvedIDsWithAccess','Format-Permission','Format-TimeSpan','Get-CachedCimInstance','Get-CachedCimSession','Get-FolderAcl','Get-FolderColumnJson','Get-FolderPermissionsBlock','Get-FolderPermissionTableHeader','Get-FolderTableHeader','Get-HtmlBody','Get-HtmlReportFooter','Get-PermissionPrincipal','Get-PrtgXmlSensorOutput','Get-ReportDescription','Get-TimeZoneName','Get-UniqueServerFqdn','Initialize-Cache','Invoke-PermissionCommand','Remove-CachedCimSession','Resolve-AccessControlList','Resolve-Ace','Resolve-Acl','Resolve-Folder','Resolve-FormatParameter','Resolve-IdentityReferenceDomainDNS','Resolve-PermissionTarget','Select-ItemPermissionTableProperty','Select-ItemTableProperty','Select-UniquePrincipal')


































































































































































































































































