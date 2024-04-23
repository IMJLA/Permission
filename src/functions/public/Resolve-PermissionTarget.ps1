function Resolve-PermissionTarget {

    # Resolve each target path to all of its associated UNC paths (including all DFS folder targets)

    param (

        # Path to the NTFS folder whose permissions to export
        [Parameter(ValueFromPipeline)]
        [ValidateScript({ Test-Path $_ })]
        [System.IO.DirectoryInfo[]]$TargetPath,

        # Cache of CIM sessions and instances to reduce connections and queries
        [Hashtable]$CimCache = ([Hashtable]::Synchronized(@{})),

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

        # Log messages which have not yet been written to disk
        [Hashtable]$LogBuffer = ([Hashtable]::Synchronized(@{})),

        [Hashtable]$Output = [Hashtable]::Synchronized(@{}),

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId

    )

    $Log = @{
        Buffer       = $LogBuffer
        ThisHostname = $ThisHostname
        Type         = $DebugOutputstream
        WhoAmI       = $WhoAmI
    }

    $ResolveFolderSplat = @{
        DebugOutputStream = $DebugOutputStream
        CimCache          = $CimCache
        ThisFqdn          = $ThisFqdn
    }

    ForEach ($ThisTargetPath in $TargetPath) {

        Write-LogMsg @Log -Text "Resolve-Folder -TargetPath '$ThisTargetPath'"
        $Output[$ThisTargetPath] = Resolve-Folder -TargetPath $ThisTargetPath @Log @ResolveFolderSplat

    }

}
