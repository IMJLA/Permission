function Get-CachedCimSession {

    param (

        # Name of the computer to query via CIM
        [String]$ComputerName,

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

        # In-process cache to reduce calls to other processes or to disk
        [ref]$Cache

    )

    $Log = @{
        Buffer       = $Cache.Value['LogBuffer']
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $InstanceCacheByComputer = $null
    $CimCache = $Cache.Value['CimCache']

    if ( $CimCache.Value.TryGetValue( $ComputerName , [ref]$InstanceCacheByComputer ) ) {

        Write-LogMsg @Log -Text " # CIM server cache hit for '$ComputerName'"
        $SessionCache = $null

        if ( $InstanceCacheByComputer.Value.TryGetValue( 'CimSession' , [ref]$SessionCache ) ) {
            Write-LogMsg @Log -Text " # CIM session cache hit for '$ComputerName'"
            return $SessionCache
        } else {
            Write-LogMsg @Log -Text " # CIM session cache miss for '$ComputerName'"
        }

    } else {

        Write-LogMsg @Log -Text " # CIM server cache miss for '$ComputerName'"
        $InstanceCacheByComputer = New-PermissionCacheRef -Key $String -Value [type]'ref'
        $null = $CimCache.Value.AddOrUpdate( $ComputerName , $InstanceCacheByComputer, $AddOrUpdateScriptblock )

    }

    if (
        $ComputerName -eq $ThisHostname -or
        $ComputerName -eq "$ThisHostname." -or
        $ComputerName -eq $ThisFqdn -or
        $ComputerName -eq "$ThisFqdn." -or
        $ComputerName -eq 'localhost' -or
        $ComputerName -eq '127.0.0.1' -or
        [String]::IsNullOrEmpty($ComputerName)
    ) {

        Write-LogMsg @Log -Text '$CimSession = New-CimSession'
        $CimSession = New-CimSession

    } else {

        # If an Active Directory domain is targeted there are no local accounts and CIM connectivity is not expected
        # Suppress errors and return nothing in that case
        Write-LogMsg @Log -Text "`$CimSession = New-CimSession -ComputerName $ComputerName"
        $CimSession = New-CimSession -ComputerName $ComputerName -ErrorAction SilentlyContinue

    }

    if ($CimSession) {

        $null = $InstanceCacheByComputer.Value.AddOrUpdate( 'CimSession' , $CimSession , { param($key, $val) $val } )
        return $CimSession

    }

}
