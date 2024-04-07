function Expand-PermissionTarget {

    # Expand a folder path into the paths of its subfolders

    param (

        <#
        How many levels of subfolder to enumerate

            Set to 0 to ignore all subfolders

            Set to -1 (default) to recurse infinitely

            Set to any whole number to enumerate that many levels
        #>
        [int]$RecurseDepth,

        # Number of asynchronous threads to use
        [uint16]$ThreadCount = ((Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum),

        # Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module
        [string]$DebugOutputStream = 'Silent',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$ThisHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = ([hashtable]::Synchronized(@{})),

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId,

        [hashtable]$TargetPath

    )

    $Progress = @{
        Activity = 'Expand-PermissionTarget'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }

    $Targets = $TargetPath.Values | ForEach-Object { $_ }
    $TargetCount = $Targets.Count
    Write-Progress @Progress -Status "0% (item 0 of $TargetCount)" -CurrentOperation "Initializing..." -PercentComplete 0

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    [hashtable]$Output = [hashtable]::Synchronized(@{})

    $GetSubfolderParams = @{
        LogMsgCache       = $LogMsgCache
        ThisHostname      = $ThisHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
        Output            = $Output
        RecurseDepth      = $RecurseDepth
        ErrorAction       = 'Continue'
    }

    if ($ThreadCount -eq 1 -or $TargetCount -eq 1) {

        [int]$ProgressInterval = [math]::max(($TargetCount / 100), 1)
        $IntervalCounter = 0
        $i = 0

        ForEach ($ThisFolder in $Targets) {

            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {
                [int]$PercentComplete = $i / $TargetCount * 100
                Write-Progress @Progress -Status "$PercentComplete% (item $($i + 1) of $TargetCount))" -CurrentOperation "Get-Subfolder '$($ThisFolder)'" -PercentComplete $PercentComplete
                $IntervalCounter = 0
            }

            $i++ # increment $i after the progress to show progress conservatively rather than optimistically
            Write-LogMsg @LogParams -Text "Get-Subfolder -TargetPath '$ThisFolder' -RecurseDepth $RecurseDepth"
            Get-Subfolder -TargetPath $ThisFolder @GetSubfolderParams

        }

    } else {

        $SplitThreadParams = @{
            Command           = 'Get-Subfolder'
            InputObject       = $Targets
            InputParameter    = 'TargetPath'
            DebugOutputStream = $DebugOutputStream
            TodaysHostname    = $ThisHostname
            WhoAmI            = $WhoAmI
            LogMsgCache       = $LogMsgCache
            Threads           = $ThreadCount
            AddParam          = $GetSubfolderParams
        }

        Split-Thread @SplitThreadParams

    }

    Write-Progress @Progress -Completed
    return $Output

}
