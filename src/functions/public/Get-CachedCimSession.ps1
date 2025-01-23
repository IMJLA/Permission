function Get-CachedCimSession {

    param (

        # Name of the computer to query via CIM
        [String]$ComputerName,

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $Log = @{
        'Cache'        = $Cache
        'ExpansionMap' = $Cache.Value['LogEmptyMap'].Value
        'Suffix'       = " # for ComputerName '$ComputerName'"
    }

    $ThisFqdn = $Cache.Value['ThisFqdn'].Value
    $ThisHostname = $Cache.Value['ThisHostname'].Value
    $CimCache = $Cache.Value['CimCache']
    $CimServer = $CimCache.Value[$ComputerName]
    $String = [type]'String'

    if ( $CimServer ) {

        #Write-LogMsg @Log -Text " # CIM server cache hit for '$ComputerName'"
        $CimSession = $CimServer.Value['CimSession']

        if ( $CimSession ) {

            #Write-LogMsg @Log -Text " # CIM session cache hit for '$ComputerName'"
            return $CimSession.Value

        } else {

            #Write-LogMsg @Log -Text " # CIM session cache miss for '$ComputerName'"
            $PastFailures = $CimServer.Value['CimFailure']

            if ( $PastFailures ) {
                #Write-LogMsg @Log -Text " # CIM failure cache hit for '$ComputerName'.  Skipping connection attempt."
                return
            }

        }

    } else {

        #Write-LogMsg @Log -Text " # CIM server cache miss for '$ComputerName'"
        $CimServer = New-PermissionCacheRef -Key $String -Value ([type]'System.Management.Automation.PSReference')
        $CimCache.Value[$ComputerName] = $CimServer

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
            Write-LogMsg @Log -Text " # CIM connection error: $($thisErr.Exception.Message -replace  '\s', ' ' )) # for '$ComputerName'"
        }

        $CimServer.Value['CimFailure'] = $CimErrors
        return

    }

    if ($CimSession) {

        $CimServer.Value['CimSession'] = $CimSession
        return $CimSession

    } else {

        $StartingLogType = $Cache.Value['LogType'].Value
        $Cache.Value['LogType'].Value = 'Warning'
        Write-LogMsg @Log -Text " # CIM connection failure without error message # for '$ComputerName'"
        $Cache.Value['LogType'].Value = $StartingLogType

    }

}
