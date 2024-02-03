function Expand-Folder {

    # Expand a folder path into the paths of its subfolders

    param (

        # Path to return along, with the paths to its subfolders
        $Folder,

        <#
        How many levels of subfolder to enumerate

            Set to 0 to ignore all subfolders

            Set to -1 (default) to recurse infinitely

            Set to any whole number to enumerate that many levels
        #>
        $LevelsOfSubfolders,

        # Number of asynchronous threads to use
        [uint16]$ThreadCount = ((Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum),

        # Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module
        [string]$DebugOutputStream = 'Silent',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$ThisHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId

    )

    $Progress = @{
        Activity = 'Expand-Folder'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }

    Write-Progress @Progress -Status "0%" -CurrentOperation "Initializing..." -PercentComplete 0
    Start-Sleep -Seconds 5

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $GetSubfolderParams = @{
        LogMsgCache       = $LogMsgCache
        ThisHostname      = $ThisHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
    }

    $FolderCount = @($Folder).Count
    if ($ThreadCount -eq 1 -or $FolderCount -eq 1) {

        [int]$ProgressInterval = [math]::max(($FolderCount / 100), 1)
        $IntervalCounter = 0
        $i = 0
        ForEach ($ThisFolder in $Folder) {
            $IntervalCounter++
            if ($IntervalCounter -eq $ProgressInterval) {
                $PercentComplete = $i / $FolderCount * 100
                Write-Progress @Progress -Status "$([int]$PercentComplete)% (item $($i + 1) of $FolderCount))" -CurrentOperation "Get-Subfolder '$($ThisFolder)'" -PercentComplete $PercentComplete
                $IntervalCounter = 0
            }
            $i++ # increment $i after the progress to show progress conservatively rather than optimistically

            $Subfolders = $null
            $Subfolders = Get-Subfolder -TargetPath $ThisFolder -FolderRecursionDepth $LevelsOfSubfolders -ErrorAction Continue @GetSubfolderParams
            Write-LogMsg @LogParams -Text "# Folders (including parent): $($Subfolders.Count + 1) for '$ThisFolder'"
            $Subfolders
        }

    } else {

        $GetSubfolder = @{
            Command           = 'Get-Subfolder'
            InputObject       = $Folder
            InputParameter    = 'TargetPath'
            DebugOutputStream = $DebugOutputStream
            TodaysHostname    = $ThisHostname
            WhoAmI            = $WhoAmI
            LogMsgCache       = $LogMsgCache
            Threads           = $ThreadCount
            AddParam          = @{
                LogMsgCache       = $LogMsgCache
                ThisHostname      = $ThisHostname
                DebugOutputStream = $DebugOutputStream
                WhoAmI            = $WhoAmI
            }
        }
        Split-Thread @GetSubfolder

    }

    Write-Progress -Activity 'Expand-Folder' -Completed
    Start-Sleep -Seconds 5

}
