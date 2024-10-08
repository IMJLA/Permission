function Find-CachedCimInstance {
    param (
        [string]$ComputerName,
        [string]$Key,
        [hashtable]$CimCache,
        [hashtable]$Log,
        [string[]]$CacheToSearch = ($CimServer.Keys | Sort-Object -Descending)
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
                    Write-LogMsg @Log -Text " # CIM Instance cache miss for '$Key' in the '$Cache' cache on '$ComputerName'"
                }

            } else {
                Write-LogMsg @Log -Text " # CIM Class/Query cache miss for '$Cache' on '$ComputerName'"
            }

        }

    } else {
        Write-LogMsg @Log -Text " # CIM Server cache miss for '$ComputerName'"
    }

}
