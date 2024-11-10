function ConvertTo-PermissionFqdn {

    param (

        [string]$ComputerName,

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [String]$ThisHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [String]$WhoAmI = (whoami.EXE),

        # In-process cache to reduce calls to other processes or to disk
        [ref]$Cache

    )

    ConvertTo-DnsFqdn -ComputerName $ComputerName -ThisHostName $ThisHostname -WhoAmI $WhoAmI -LogBuffer $Cache.Value['LogBuffer']

}
