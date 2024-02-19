function Get-CachedCimInstance {

    param (

        # Name of the computer to query via CIM
        [string]$ComputerName,

        # Name of the CIM class whose instances to return
        [string]$ClassName,

        # CIM query to run. Overrides ClassName if used (but not efficiently, so don't use both)
        [string]$Query,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        [Parameter(Mandatory)]
        [string]$KeyProperty,

        [string[]]$CacheByProperty = $KeyProperty

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    if ($PSBoundParameters.ContainsKey('ClassName')) {
        $InstanceCacheKey = "$ClassName`By$KeyProperty"
    } else {
        $InstanceCacheKey = "$Query`By$KeyProperty"
    }

    $CimCacheResult = $CimCache[$ComputerName]

    if ($CimCacheResult) {

        Write-LogMsg @LogParams -Text " # CIM cache hit for '$ComputerName'"
        $CimCacheSubresult = $CimCacheResult[$InstanceCacheKey]

        if ($CimCacheSubresult) {
            Write-LogMsg @LogParams -Text " # CIM instance cache hit for '$InstanceCacheKey' on '$ComputerName'"
            return $CimCacheSubresult.Values
        } else {
            Write-LogMsg @LogParams -Text " # CIM instance cache miss for '$InstanceCacheKey' on '$ComputerName'"
        }

    } else {
        Write-LogMsg @LogParams -Text " # CIM cache miss for '$ComputerName'"
    }

    $CimSession = Get-CachedCimSession -ComputerName $ComputerName -CimCache $CimCache -ThisFqdn $ThisFqdn @LogParams

    if ($CimSession) {

        if ($PSBoundParameters.ContainsKey('ClassName')) {
            Write-LogMsg @LogParams -Text "Get-CimInstance -ClassName $ClassName -CimSession `$CimSession"
            $CimInstance = Get-CimInstance -ClassName $ClassName -CimSession $CimSession -ErrorAction SilentlyContinue
        }

        if ($PSBoundParameters.ContainsKey('Query')) {
            Write-LogMsg @LogParams -Text "Get-CimInstance -Query '$Query' -CimSession `$CimSession"
            $CimInstance = Get-CimInstance -Query $Query -CimSession $CimSession -ErrorAction SilentlyContinue
        }

        if ($CimInstance) {

            $InstanceCache = [hashtable]::Synchronized(@{})

            ForEach ($Prop in $CacheByProperty) {

                if ($PSBoundParameters.ContainsKey('ClassName')) {
                    $InstanceCacheKey = "$ClassName`By$Prop"
                } else {
                    $InstanceCacheKey = "$Query`By$Prop"
                }

                ForEach ($Instance in $CimInstance) {
                    $InstancePropertyValue = $Instance.$Prop
                    Write-LogMsg @LogParams -Text " # Add '$InstancePropertyValue' to the '$InstanceCacheKey' cache"
                    $InstanceCache[$InstancePropertyValue] = $Instance
                }

                $CimCache[$ComputerName][$InstanceCacheKey] = $InstanceCache

            }

            return $CimInstance

        }

    }

}
