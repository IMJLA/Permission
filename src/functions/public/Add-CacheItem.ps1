function Add-CacheItem {

    # Use a key to get a generic list from a hashtable
    # If it does not exist, create an empty list
    # Add the new item

    param (

        [Parameter(Mandatory)]
        [Hashtable]$Cache,

        [Parameter(Mandatory)]
        $Key,

        $Value,

        [type]$Type = [System.Object]

    )

    if ($key.Count -gt 1) { Pause }

    # Older, less efficient method
    $CacheResult = $Cache[$Key]

    if ($CacheResult) {
        $List = $CacheResult
    } else {
        $Command = "`$List = [System.Collections.Generic.List[$($Type.ToString())]]::new()"
        Invoke-Expression $Command
    }

    $List.Add($Value)
    $Cache[$Key] = $List

    <#
    # More efficient method requires switch to ConcurrentDictionary instead of SynchronizedHashtable

    $List = $null

    if ( -not $Cache.TryGetValue( $Key, [ref]$List ) ) {
        $Command = "`$List = [System.Collections.Generic.List[$($Type.ToString())]]::new()"
        Invoke-Expression $Command
        $Cache.Add($Key, $List)
    }

    $List.Add($Value)
    #>

}
