
# Add any custom C# classes as usable (exported) types
$CSharpFiles = Get-ChildItem -Path "$PSScriptRoot\*.cs"
ForEach ($ThisFile in $CSharpFiles) {
    Add-Type -Path $ThisFile.FullName -ErrorAction Stop
}

Export-ModuleMember -Function @('Add-CacheItem','Add-PermissionCacheItem','ConvertTo-ItemBlock','ConvertTo-PermissionFqdn','Expand-Permission','Expand-PermissionSource','Find-CachedCimInstance','Find-ResolvedIDsWithAccess','Find-ServerFqdn','Format-Permission','Format-TimeSpan','Get-AccessControlList','Get-CachedCimInstance','Get-CachedCimSession','Get-PermissionPrincipal','Get-PermissionTrustedDomain','Get-PermissionWhoAmI','Get-TimeZoneName','Initialize-PermissionCache','Invoke-PermissionAnalyzer','Invoke-PermissionCommand','Optimize-PermissionCache','Out-Permission','Out-PermissionFile','Remove-CachedCimSession','Resolve-AccessControlList','Resolve-PermissionSource','Select-PermissionPrincipal')


























































































































































































































































































































































































































































































































































































































































