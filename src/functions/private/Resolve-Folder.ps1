function Resolve-Folder {

    # Resolve the provided FolderPath to all of its associated UNC paths, including all DFS folder targets

    param (

        # Path of the folder(s) to resolve to all their associated UNC paths
        [String]$TargetPath,

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $RegEx = '^(?<DriveLetter>\w):'

    if ($TargetPath -match $RegEx) {

        $GetCimInstanceParams = @{
            Cache       = $Cache
            ClassName   = 'Win32_MappedLogicalDisk'
            KeyProperty = 'DeviceID'
        }

        Write-LogMsg -Text "Get-CachedCimInstance -ComputerName '$ThisHostname'" -Expand $GetCimInstanceParams -MapKeyName 'LogCacheMap' -Cache $Cache
        $MappedNetworkDrives = Get-CachedCimInstance -ComputerName $ThisHostname @GetCimInstanceParams

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
            $FQDN = ConvertTo-PermissionFqdn -ComputerName $Server -Cache $Cache
            $UNC -replace "^\\\\$Server\\", "\\$FQDN\"
        }

    } else {

        ## Workaround in place: Get-NetDfsEnum -Verbose parameter is not used due to errors when it is used with the PsRunspace module for multithreading
        ## https://github.com/IMJLA/Export-Permission/issues/46
        ## https://github.com/IMJLA/PsNtfs/issues/1
        Write-LogMsg -Text "Get-NetDfsEnum -FolderPath '$TargetPath'" -Cache $Cache
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
            $FQDN = ConvertTo-PermissionFqdn -ComputerName $Server -Cache $Cache
            $TargetPath -replace "^\\\\$Server\\", "\\$FQDN\"

        }

    }

}
