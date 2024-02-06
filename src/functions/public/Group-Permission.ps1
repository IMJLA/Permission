function Group-Permission {

    param (

        [object[]]$InputObject,

        [string]$Property

    )

    $Cache = @{}

    ForEach ($Permission in $InputObject) {

        [string]$Key = $Permission.$Property
        $CacheResult = $Cache[$Key]

        if ($CacheResult) {
            $CacheResult.Add($Permission)
        } else {
            $CacheResult = [System.Collections.Generic.List[object]]::new().Add($Permission)
        }

        $Cache[$Key] = $CacheResult

    }

    ForEach ($Key in $Cache.Keys) {

        $CacheResult = $Cache[$Key]
        [pscustomobject]@{
            PSType = "Permission.$Property`Permission"
            Group  = $CacheResult
            Name   = $Key
            Count  = $CacheResult.Count
        }

    }

}
