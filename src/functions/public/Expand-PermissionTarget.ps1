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
        [String]$DebugOutputStream = 'Silent',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [String]$ThisHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [String]$WhoAmI = (whoami.EXE),

        # ID of the parent progress bar under which to show progress
        [int]$ProgressParentId,

        # In-process cache to reduce calls to other processes or to disk
        [ref]$Cache

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

    $Targets = ForEach ($Target in $Cache.Value['ParentByTargetPath'].Value.Values ) {
        $Target
    }

    $TargetCount = $Targets.Count
    Write-Progress @Progress -Status "0% (item 0 of $TargetCount)" -CurrentOperation 'Initializing...' -PercentComplete 0
    $LogBuffer = $Cache.Value['LogBuffer']

    $Log = @{
        Buffer       = $LogBuffer
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    [Hashtable]$Output = [Hashtable]::Synchronized(@{})

    $GetSubfolderParams = @{
        LogBuffer         = $LogBuffer
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
            Write-LogMsg @Log -Text "Get-Subfolder -TargetPath '$ThisFolder' -RecurseDepth $RecurseDepth"
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
            LogBuffer         = $LogBuffer
            Threads           = $ThreadCount
            ProgressParentId  = $Progress['Id']
            AddParam          = $GetSubfolderParams
        }

        Split-Thread @SplitThreadParams

    }

    Write-Progress @Progress -Completed
    return $Output

}
