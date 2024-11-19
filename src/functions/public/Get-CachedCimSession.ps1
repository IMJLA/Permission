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

    $AddOrUpdateScriptblock = { param($key, $val) $val }
    $CimCache = $Cache.Value['CimCache']
    $CimServer = $null
    $String = [type]'String'

    if ( $CimCache.Value.TryGetValue( $ComputerName , [ref]$CimServer ) ) {

        Write-LogMsg @Log -Text " # CIM server cache hit for '$ComputerName'"
        $CimSession = $null

        if ( $CimServer.Value.TryGetValue( 'CimSession' , [ref]$CimSession ) ) {

            Write-LogMsg @Log -Text " # CIM session cache hit for '$ComputerName'"
            return $CimSession.Value

        } else {

            Write-LogMsg @Log -Text " # CIM session cache miss for '$ComputerName'"
            $PastFailures = $null

            if ( $CimServer.Value.TryGetValue( 'CimFailure' , [ref]$PastFailures ) ) {
                Write-LogMsg @Log -Text " # CIM failure cache hit for '$ComputerName'.  Skipping connection attempt."
                return
            }

        }

    } else {

        Write-LogMsg @Log -Text " # CIM server cache miss for '$ComputerName'"
        $CimServer = New-PermissionCacheRef -Key $String -Value ([type]'System.Management.Automation.PSReference')
        $null = $CimCache.Value.AddOrUpdate( $ComputerName , $CimServer, $AddOrUpdateScriptblock )

    }

    $CimErrors = $null

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
        $CimSession = New-CimSession -ErrorVariable CimErrors -ErrorAction SilentlyContinue

    } else {

        # If an Active Directory domain is targeted there are no local accounts and CIM connectivity is not expected
        # Suppress errors and return nothing in that case
        Write-LogMsg @Log -Text "`$CimSession = New-CimSession -ComputerName $ComputerName"
        $CimSession = New-CimSession -ComputerName $ComputerName -ErrorVariable CimErrors -ErrorAction SilentlyContinue

    }

    if ($CimErrors.Count -gt 0) {

        ForEach ($thisErr in $CimErrors) {
            Write-LogMsg @Log -Text " # CIM connection error: $($thisErr.Exception.Message -replace  '\s', '' )) # for '$ComputerName'"
        }

        $null = $CimServer.Value.AddOrUpdate( 'CimFailure' , $CimErrors , $AddOrUpdateScriptblock )
        return

    }

    if ($CimSession) {

        $null = $CimServer.Value.AddOrUpdate( 'CimSession' , $CimSession , $AddOrUpdateScriptblock )
        return $CimSession

    } else {
        $Log['Type'] = 'Warning'
        Write-LogMsg @Log -Text " # CIM connection failure without error message # for '$ComputerName'"
    }

}
