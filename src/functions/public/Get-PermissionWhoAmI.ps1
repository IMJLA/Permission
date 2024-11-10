function Get-PermissionWhoAmI {

    param (

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [String]$ThisHostname = (HOSTNAME.EXE),

        # In-process cache to reduce calls to other processes or to disk
        [ref]$Cache

    )

    Get-CurrentWhoAmI -ThisHostName $ThisHostname -LogBuffer $Cache.Value['LogBuffer']

}
