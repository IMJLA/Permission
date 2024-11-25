function Get-PermissionWhoAmI {

    # Get the NTAccount caption of the user running the script, with the correct capitalization.

    param (

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [String]$ThisHostname = (HOSTNAME.EXE)

    )

    Get-CurrentWhoAmI -ThisHostName $ThisHostname

}
