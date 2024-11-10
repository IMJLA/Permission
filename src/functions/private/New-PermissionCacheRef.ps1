function New-PermissionCacheRef {

    param (

        # Type of the keys
        [type]$Key = [System.String],

        # Type of the values
        [type]$Value = [System.Collections.Generic.List[System.Object]]

    )

    $genericTypeDefinition = [System.Collections.Concurrent.ConcurrentDictionary`2]
    $genericType = $genericTypeDefinition.MakeGenericType($Key, $Value)
    return [ref][Activator]::CreateInstance($genericType)

}
