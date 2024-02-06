function Group-Permission {

    param (

        [object[]]$InputObject,

        [string]$Property

    )

    $Cache = @{}

    ForEach ($Permission in $InputObject) {

        if ($Cache[$Permission.$Property]) {
            $Cache[$Permission.$Property].Add($Permission)
        } else {
            $Cache[$Permission.$Property] = [System.Collections.Generic.List[object]]::new().Add($Permission)
        }

    }

    ForEach ($Key in $Cache.Keys) {

        [pscustomobject]@{
            PSType = "Permission.$Property`Permission"
            Group  = $Cache[$Key]
            Name   = $Key
        }

    }

}
