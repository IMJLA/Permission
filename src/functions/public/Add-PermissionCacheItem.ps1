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

    $List = $Cache.Value[$Key]

    if ( -not $List ) {

        $genericTypeDefinition = [System.Collections.Generic.List`1]
        $genericType = $genericTypeDefinition.MakeGenericType($Type)
        $List = [Activator]::CreateInstance($genericType)
        $Cache.Value[$Key] = $List

    }

    $List.Add($Value)

}
