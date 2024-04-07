function Get-CachedCimSession {

    param (

        # Name of the computer to query via CIM
        [string]$ComputerName,

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
        [hashtable]$LogMsgCache = ([hashtable]::Synchronized(@{}))
    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    $CimCacheResult = $CimCache[$ComputerName]

    if ($CimCacheResult) {

        Write-LogMsg @LogParams -Text " # CIM cache hit for '$ComputerName'"
        $CimCacheSubresult = $CimCacheResult['CimSession']

        if ($CimCacheSubresult) {
            Write-LogMsg @LogParams -Text " # CIM session cache hit for '$ComputerName'"
            return $CimCacheSubresult
        } else {
            Write-LogMsg @LogParams -Text " # CIM session cache miss for '$ComputerName'"
        }

    } else {

        Write-LogMsg @LogParams -Text " # CIM cache miss for '$ComputerName'"
        $CimCache[$ComputerName] = [hashtable]::Synchronized(@{})

    }

    if (
        $ComputerName -eq $ThisHostname -or
        $ComputerName -eq "$ThisHostname." -or
        $ComputerName -eq $ThisFqdn -or
        $ComputerName -eq "$ThisFqdn." -or
        $ComputerName -eq 'localhost' -or
        $ComputerName -eq '127.0.0.1' -or
        [string]::IsNullOrEmpty($ComputerName)
    ) {
        Write-LogMsg @LogParams -Text '$CimSession = New-CimSession'
        $CimSession = New-CimSession
    } else {
        # If an Active Directory domain is targeted there are no local accounts and CIM connectivity is not expected
        # Suppress errors and return nothing in that case
        Write-LogMsg @LogParams -Text "`$CimSession = New-CimSession -ComputerName $ComputerName"
        $CimSession = New-CimSession -ComputerName $ComputerName -ErrorAction SilentlyContinue
    }

    if ($CimSession) {
        $CimCache[$ComputerName]['CimSession'] = $CimSession
        return $CimSession
    }

}
