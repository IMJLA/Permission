function Get-PermissionTrustedDomain {

    param (

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [String]$ThisHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [String]$WhoAmI = (whoami.EXE),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # In-process cache to reduce calls to other processes or to disk
        [ref]$Cache

    )

    Get-TrustedDomain -ThisHostname $ThisHostname -WhoAmI $WhoAmI -DebugOutputStream $DebugOutputStream -Cache $Cache

}
