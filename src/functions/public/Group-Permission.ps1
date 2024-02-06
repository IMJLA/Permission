function Group-Permission {

    param (

        [object[]]$InputObject,

        [string]$Property

    )

    $Cache = @{}

    ForEach ($Permission in $InputObject) {

        $Key = $Permission.$Property
        $CacheResult = $Cache[$Key]
        if (-not $CacheResult) {
            $CacheResult = [System.Collections.Generic.List[object]]::new()
        }
        $CacheResult.Add($Permission)
        $Cache[$Key] = $CacheResult

    }

    ForEach ($Key in $Cache.Keys) {

        $CacheResult = $Cache[$Key]
        [pscustomobject]@{
            PSTypeName = "Permission.$Property`Permission"
            Group      = $CacheResult
            Name       = $Key
            Count      = $CacheResult.Count
        }

    }

}
