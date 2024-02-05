function Get-CachedCimInstance {

    param (

        # Name of the computer to query via CIM
        [string]$ComputerName,

        # Name of the CIM class whose instances to return
        [string]$ClassName,

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
        [hashtable]$LogMsgCache = $Global:LogMessages
    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    $CimCacheResult = $CimCache[$ComputerName]

    if ($CimCacheResult) {

        $CimCacheSubresult = $CimCacheResult[$ClassName]

        if ($CimCacheSubresult) {
            return $CimCacheSubresult
        }

    }

    $CimSession = Get-CachedCimSession -ComputerName $ComputerName -CimCache $CimCache -ThisFqdn $ThisFqdn @LogParams

    if ($CimSession) {
        Write-LogMsg @LogParams -Text "Get-CimInstance -ClassName $ClassName -CimSession `$CimSession"
        $CimInstance = Get-CimInstance -ClassName $ClassName -CimSession $CimSession
        $CimCache[$ComputerName][$ClassName] = $CimInstance
        return $CimInstance
    }

}
