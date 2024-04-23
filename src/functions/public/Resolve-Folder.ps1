function Resolve-Folder {

    # Resolve the provided FolderPath to all of its associated UNC paths, including all DFS folder targets

    param (

        # Path of the folder(s) to resolve to all their associated UNC paths
        [String]$TargetPath,

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
        [Hashtable]$LogBuffer = ([Hashtable]::Synchronized(@{}))
    )

    $Log = @{
        Buffer       = $LogBuffer
        ThisHostname = $ThisHostname
        Type         = $DebugOutputstream
        WhoAmI       = $WhoAmI
    }

    $LogSplat = @{
        LogBuffer         = $LogBuffer
        ThisHostname      = $ThisHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
    }

    $RegEx = '^(?<DriveLetter>\w):'

    if ($TargetPath -match $RegEx) {

        Write-LogMsg @Log -Text "Get-CachedCimInstance -ComputerName $ThisHostname -ClassName Win32_MappedLogicalDisk"
        $MappedNetworkDrives = Get-CachedCimInstance -ComputerName $ThisHostname -ClassName Win32_MappedLogicalDisk -KeyProperty DeviceID -CimCache $CimCache -ThisFqdn $ThisFqdn @LogSplat

        $MatchingNetworkDrive = $MappedNetworkDrives |
        Where-Object -FilterScript { $_.DeviceID -eq "$($Matches.DriveLetter):" }

        if ($MatchingNetworkDrive) {
            # Resolve mapped network drives to their UNC path
            $UNC = $MatchingNetworkDrive.ProviderName
        } else {
            # Resolve local drive letters to their UNC paths using administrative shares
            $UNC = $TargetPath -replace $RegEx, "\\$(hostname)\$($Matches.DriveLetter)$"
        }

        if ($UNC) {
            # Replace hostname with FQDN in the path
            $Server = $UNC.split('\')[2]
            $FQDN = ConvertTo-DnsFqdn -ComputerName $Server @LogSplat
            $UNC -replace "^\\\\$Server\\", "\\$FQDN\"
        }

    } else {

        ## Workaround in place: Get-NetDfsEnum -Verbose parameter is not used due to errors when it is used with the PsRunspace module for multithreading
        ## https://github.com/IMJLA/Export-Permission/issues/46
        ## https://github.com/IMJLA/PsNtfs/issues/1
        Write-LogMsg @Log -Text "Get-NetDfsEnum -FolderPath '$TargetPath'"
        $AllDfs = Get-NetDfsEnum -FolderPath $TargetPath -ErrorAction SilentlyContinue

        if ($AllDfs) {

            $MatchingDfsEntryPaths = $AllDfs |
            Group-Object -Property DfsEntryPath |
            Where-Object -FilterScript {
                $TargetPath -match [regex]::Escape($_.Name)
            }

            # Filter out the DFS Namespace
            # TODO: I know this is an inefficient n2 algorithm, but my brain is fried...plez...halp...leeloo dallas multipass
            $RemainingDfsEntryPaths = $MatchingDfsEntryPaths |
            Where-Object -FilterScript {
                -not [bool]$(
                    ForEach ($ThisEntryPath in $MatchingDfsEntryPaths) {
                        if ($ThisEntryPath.Name -match "$([regex]::Escape("$($_.Name)")).+") { $true }
                    }
                )
            } |
            Sort-Object -Property Name

            $RemainingDfsEntryPaths |
            Select-Object -Last 1 -ExpandProperty Group |
            ForEach-Object {
                $_.FullOriginalQueryPath -replace [regex]::Escape($_.DfsEntryPath), $_.DfsTarget
            }

        } else {

            $Server = $TargetPath.split('\')[2]
            $FQDN = ConvertTo-DnsFqdn -ComputerName $Server @LogSplat
            $TargetPath -replace "^\\\\$Server\\", "\\$FQDN\"

        }

    }

}
