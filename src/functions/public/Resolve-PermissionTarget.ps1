function Resolve-PermissionTarget {

    # Resolve each target path to all of its associated UNC paths (including all DFS folder targets)

    param (

        # Path to the NTFS folder whose permissions to export
        [System.IO.DirectoryInfo[]]$TargetPath,

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [String]$DebugOutputStream = 'Debug',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [String]$ThisHostname = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [String]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [String]$WhoAmI = (whoami.EXE),

        # In-process cache to reduce calls to other processes or to disk
        [ref]$Cache,

        # ID of the parent progress bar under which to show progress
        [int]$ProgressParentId

    )

    $Log = @{
        Buffer       = $Cache.Value['LogBuffer']
        ThisHostname = $ThisHostname
        Type         = $DebugOutputstream
        WhoAmI       = $WhoAmI
    }

    $ResolveFolderSplat = @{
        ThisFqdn          = $ThisFqdn
        Cache             = $Cache
        ThisHostname      = $ThisHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
    }

    $Parents = $Cache.Value['ParentByTargetPath']

    ForEach ($ThisTargetPath in $TargetPath) {

        Write-LogMsg @Log -Text "Resolve-Folder -TargetPath '$ThisTargetPath'" -Expand $ResolveFolderSplat -ExpandKeyMap @{ Cache = '$Cache' }
        $Parents.Value[$ThisTargetPath] = Resolve-Folder -TargetPath $ThisTargetPath @ResolveFolderSplat

    }

}
