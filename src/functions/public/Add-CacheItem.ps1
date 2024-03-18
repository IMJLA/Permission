function Add-CacheItem {

    # Use a key to get a generic list from a hashtable
    # If it does not exist, create an empty list
    # Add the new item

    param (

        [hashtable]$Cache,

        $Key,

        $Value,

        [type]$Type

    )

    $CacheResult = $Cache[$Key]

    if (-not $CacheResult) {
        $Command = "[System.Collections.Generic.List[$($Type.ToString())]]::new()"
        $CacheResult = Invoke-Expression $Command
    }

    $CacheResult.Add($Value)
    $Cache[$Key] = $CacheResult

}
