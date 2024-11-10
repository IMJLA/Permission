function Add-PermissionCacheItem {

    # Use a key to get a generic list from a hashtable
    # If it does not exist, create an empty list
    # Add the new item

    param (

        # Must be a Dictionary or ConcurrentDictionary
        [Parameter(Mandatory)]
        [ref]$Cache,

        [Parameter(Mandatory)]
        $Key,

        $Value,

        [type]$Type = [System.Object]

    )

    $List = $null
    $AddOrUpdateScriptblock = { param($key, $val) $val }

    if ( -not $Cache.Value.TryGetValue( $Key, [ref]$List ) ) {

        $genericTypeDefinition = [System.Collections.Generic.List`1]
        $genericType = $genericTypeDefinition.MakeGenericType($Type)
        $List = [Activator]::CreateInstance($genericType)
        $null = $Cache.Value.AddOrUpdate($Key, $List, $AddOrUpdateScriptblock)

    }

    $List.Add($Value)

}
