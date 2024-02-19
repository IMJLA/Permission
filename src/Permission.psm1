
# Add any custom C# classes as usable (exported) types
$CSharpFiles = Get-ChildItem -Path "$PSScriptRoot\*.cs"
ForEach ($ThisFile in $CSharpFiles) {
    Add-Type -Path $ThisFile.FullName -ErrorAction Stop
}

Export-ModuleMember -Function @('Add-CacheItem','ConvertTo-ItemBlock','Expand-AccountPermissionReference','Expand-ItemPermissionReference','Expand-PermissionTarget','Export-FolderPermissionHtml','Export-RawPermissionCsv','Export-ResolvedPermissionCsv','Find-ResolvedIDsWithAccess','Format-FolderPermission','Format-TimeSpan','Get-CachedCimInstance','Get-CachedCimSession','Get-FolderAcl','Get-FolderColumnJson','Get-FolderPermissionsBlock','Get-FolderPermissionTableHeader','Get-FolderTableHeader','Get-HtmlBody','Get-HtmlReportFooter','Get-PermissionPrincipal','Get-PrtgXmlSensorOutput','Get-ReportDescription','Get-TimeZoneName','Get-UniqueServerFqdn','Group-AccountPermissionReference','Group-ItemPermissionReference','Initialize-Cache','Invoke-PermissionCommand','Remove-CachedCimSession','Resolve-AccessControlList','Resolve-Ace','Resolve-Acl','Resolve-Folder','Resolve-IdentityReferenceDomainDNS','Resolve-PermissionTarget','Select-FolderPermissionTableProperty','Select-ItemTableProperty','Select-UniquePrincipal')












































































































































































































































