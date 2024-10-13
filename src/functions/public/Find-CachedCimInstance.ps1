function Find-CachedCimInstance {

    param (
        [string]$ComputerName,
        [string]$Key,
        [hashtable]$CimCache,
        [hashtable]$Log,
        [string[]]$CacheToSearch = ($CimCache[$ComputerName].Keys | Sort-Object -Descending)
    )

    $CimServer = $CimCache[$ComputerName]

    if ($CimServer) {

        ForEach ($Cache in $CacheToSearch) {

            $InstanceCache = $CimServer[$Cache]

            if ($InstanceCache) {

                $CachedCimInstance = $InstanceCache[$Key]

                if ($CachedCimInstance) {

                    return $CachedCimInstance

                } else {
                    Write-LogMsg @Log -Text " # CIM Instance cache miss in the '$Cache' cache on '$ComputerName' for '$Key'"
                }

            } else {
                Write-LogMsg @Log -Text " # CIM Class/Query cache miss for '$Cache' on '$ComputerName' # for '$Key'"
            }

        }

    } else {
        Write-LogMsg @Log -Text " # CIM Server cache miss for '$ComputerName' # for '$Key'"
    }

}
