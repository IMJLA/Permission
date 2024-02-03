function Resolve-PermissionTarget {

    # Resolve each target path to all of its associated UNC paths (including all DFS folder targets)

    param (

        # Path to the NTFS folder whose permissions to export
        [Parameter(ValueFromPipeline)]
        [ValidateScript({ Test-Path $_ })]
        [System.IO.DirectoryInfo[]]$TargetPath,

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$ThisHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    ForEach ($ThisTargetPath in $TargetPath) {

        Write-LogMsg @LogParams -Text "Resolve-Folder -FolderPath '$ThisTargetPath'"
        Resolve-Folder -FolderPath $ThisTargetPath

    }

}
