function Remove-CachedCimSession {

    param (

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{}))

    )

    ForEach ($CacheResult in $CimCache.Values) {

        if ($CacheResult) {

            $CimSession = $CacheResult['CimSession']

            if ($CimSession) {
                $null = Remove-CimSession -CimSession $CimSession
            }

        }

    }

}
