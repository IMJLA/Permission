function Get-CachedCimInstance {

    param (

        # Name of the computer to query via CIM
        [String]$ComputerName,

        # Name of the CIM class whose instances to return
        [String]$ClassName,

        # Name of the CIM namespace containing the class
        [String]$Namespace,

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

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [String]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [String]$WhoAmI = (whoami.EXE),

        # Log messages which have not yet been written to disk
        [Parameter(Mandatory)]
        [ref]$LogBuffer,

        [Parameter(Mandatory)]
        [String]$KeyProperty,

        [string[]]$CacheByProperty = $KeyProperty

    )

    $Log = @{
        Buffer       = $LogBuffer
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    if ($PSBoundParameters.ContainsKey('ClassName')) {
        $InstanceCacheKey = "$ClassName`By$KeyProperty"
    } else {
        $InstanceCacheKey = "$Query`By$KeyProperty"
    }

    $CimCacheResult = $CimCache[$ComputerName]

    if ($CimCacheResult) {

        #Write-LogMsg @Log -Text " # CIM server cache hit for '$ComputerName'"
        $CimCacheSubresult = $CimCacheResult[$InstanceCacheKey]

        if ($CimCacheSubresult) {
            #Write-LogMsg @Log -Text " # CIM instance cache hit for '$InstanceCacheKey' on '$ComputerName'"
            return $CimCacheSubresult.Values
        } else {
            Write-LogMsg @Log -Text " # CIM instance cache miss for '$InstanceCacheKey' on '$ComputerName'"
        }

    } else {
        Write-LogMsg @Log -Text " # CIM server cache miss for '$ComputerName'"
    }

    $CimSession = Get-CachedCimSession -ComputerName $ComputerName -CimCache $CimCache -ThisFqdn $ThisFqdn @Log

    if ($CimSession) {

        $GetCimInstanceParams = @{
            CimSession  = $CimSession
            ErrorAction = 'SilentlyContinue'
        }

        if ($Namespace) {
            $GetCimInstanceParams['Namespace'] = $Namespace
        }

        if ($PSBoundParameters.ContainsKey('ClassName')) {
            Write-LogMsg @Log -Text "Get-CimInstance -ClassName $ClassName -CimSession `$CimSession"
            $CimInstance = Get-CimInstance -ClassName $ClassName @GetCimInstanceParams
        }

        if ($PSBoundParameters.ContainsKey('Query')) {
            Write-LogMsg @Log -Text "Get-CimInstance -Query '$Query' -CimSession `$CimSession"
            $CimInstance = Get-CimInstance -Query $Query @GetCimInstanceParams
        }

        if ($CimInstance) {

            ForEach ($Prop in $CacheByProperty) {

                $InstanceCache = [Hashtable]::Synchronized(@{})

                if ($PSBoundParameters.ContainsKey('ClassName')) {
                    $InstanceCacheKey = "$ClassName`By$Prop"
                } else {
                    $InstanceCacheKey = "$Query`By$Prop"
                }

                ForEach ($Instance in $CimInstance) {
                    $InstancePropertyValue = $Instance.$Prop
                    Write-LogMsg @Log -Text " # Add '$InstancePropertyValue' to the '$InstanceCacheKey' cache for '$ComputerName'"
                    $InstanceCache[$InstancePropertyValue] = $Instance
                }

                $CimCache[$ComputerName][$InstanceCacheKey] = $InstanceCache

            }

            return $CimInstance

        }

    }

}
