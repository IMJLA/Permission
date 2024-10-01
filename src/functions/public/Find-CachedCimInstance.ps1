function Find-CachedCimInstance {
    param (
        [string]$ComputerName,
        [string]$Key,
        [hashtable]$CimCache,
        [hashtable]$Log
    )

    $CimServer = $CimCache[$ComputerName]

    if ($CimServer) {

        ForEach ($Cache in $CimServer.Keys) {

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
