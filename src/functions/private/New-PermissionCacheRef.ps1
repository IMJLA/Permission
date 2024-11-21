function New-PermissionCacheRef {

    param (

        # Type of the keys
        [type]$Key = [System.String],

        # Type of the values
        [type]$Value = [System.Collections.Generic.List[System.Object]],

        [StringComparer]$Comparer = [StringComparer]::OrdinalIgnoreCase

    )

    $genericTypeDefinition = [System.Collections.Concurrent.ConcurrentDictionary`2]
    $genericType = $genericTypeDefinition.MakeGenericType($Key, $Value)
    if ($Key -eq [System.String]) {
        return [ref][Activator]::CreateInstance($genericType, $Comparer)
    }
    return [ref][Activator]::CreateInstance($genericType)

}
