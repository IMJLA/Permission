function Add-CacheItem {

    # Use a key to get a generic list from a hashtable
    # If it does not exist, create an empty list
    # Add the new item

    param (

        [Hashtable]$Cache,

        $Key,

        $Value,

        [type]$Type

    )

    $CacheResult = $Cache[$Key]

    if ($CacheResult) {
        $List = $CacheResult
    } else {
        $Command = "`$List = [System.Collections.Generic.List[$($Type.ToString())]]::new()"
        Invoke-Expression $Command
    }

    $List.Add($Value)
    $Cache[$Key] = $List

}
