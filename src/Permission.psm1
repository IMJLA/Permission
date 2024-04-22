
# Add any custom C# classes as usable (exported) types
$CSharpFiles = Get-ChildItem -Path "$PSScriptRoot\*.cs"
ForEach ($ThisFile in $CSharpFiles) {
    Add-Type -Path $ThisFile.FullName -ErrorAction Stop
}

Export-ModuleMember -Function @('Add-CacheItem','ConvertTo-ItemBlock','Expand-Permission','Expand-PermissionTarget','Find-ResolvedIDsWithAccess','Find-ServerFqdn','Format-Permission','Format-TimeSpan','Get-AccessControlList','Get-CachedCimInstance','Get-CachedCimSession','Get-PermissionPrincipal','Get-PrtgXmlSensorOutput','Get-TimeZoneName','Initialize-Cache','Invoke-PermissionCommand','Out-PermissionReport','Remove-CachedCimSession','Resolve-AccessControlList','Resolve-Ace','Resolve-Acl','Resolve-Folder','Resolve-FormatParameter','Resolve-PermissionTarget','Select-PermissionPrincipal')












































