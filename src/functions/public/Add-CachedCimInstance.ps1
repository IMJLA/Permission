function Add-CachedCimInstance {

    param (

        # CIM Instance(s) to add to the cache
        [Parameter(ValueFromPipeline)]
        $InputObject,

        # Name of the computer to query via CIM
        [String]$ComputerName,

        # Name of the CIM class whose instances to return
        [String]$ClassName,

        # CIM query to run. Overrides ClassName if used (but not efficiently, so don't use both)
        [String]$Query,

        # Cache of CIM sessions and instances to reduce connections and queries
        [Hashtable]$CimCache = ([Hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [String]$DebugOutputStream = 'Debug',

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [String]$ThisHostName = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [String]$WhoAmI = (whoami.EXE),

        # Log messages which have not yet been written to disk
        [Hashtable]$LogBuffer = ([Hashtable]::Synchronized(@{})),

        # Properties by which to key the cache
        [string[]]$CacheByProperty

    )

    begin {

        $Log = @{
            Buffer       = $LogBuffer
            ThisHostname = $ThisHostname
            Type         = $DebugOutputStream
            WhoAmI       = $WhoAmI
        }

        $ComputerCache = $CimCache[$ComputerName]

        if (-not $ComputerCache) {
            #Write-LogMsg @Log -Text " # CIM server cache miss for '$ComputerName'"
            $ComputerCache = [Hashtable]::Synchronized(@{})
        }

    }

    process {

        ForEach ($Prop in $CacheByProperty) {

            if ($PSBoundParameters.ContainsKey('ClassName')) {
                $InstanceCacheKey = "$ClassName`By$Prop"
            } else {

                if ($PSBoundParameters.ContainsKey('Query')) {
                    $InstanceCacheKey = "$Query`By$Prop"
                } else {

                    $ClassName = @($InputObject)[0].CimClass.CimClassName
                    $InstanceCacheKey = "$ClassName`By$Prop"

                }

            }

            #Write-LogMsg @Log -Text " # CIM server cache hit for '$ComputerName'"
            $InstanceCache = $ComputerCache[$InstanceCacheKey]

            if (-not $InstanceCache) {

                #Write-LogMsg @Log -Text " # CIM instance cache miss for '$InstanceCacheKey' on '$ComputerName'"
                $InstanceCache = [Hashtable]::Synchronized(@{})

            }

            ForEach ($Instance in $InputObject) {

                $InstancePropertyValue = $Instance.$Prop
                Write-LogMsg @Log -Text " # Add '$InstancePropertyValue' to the '$InstanceCacheKey' cache for '$ComputerName'"
                $InstanceCache[$InstancePropertyValue] = $Instance

            }

            $ComputerCache[$InstanceCacheKey] = $InstanceCache

        }

    }

    end {
        $CimCache[$ComputerName] = $ComputerCache
    }


}
