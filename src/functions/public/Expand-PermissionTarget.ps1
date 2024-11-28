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

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $Progress = @{
        Activity = 'Expand-PermissionTarget'
    }

    $ProgressParentId = $Cache.Value['ProgressParentId']

    if ($ProgressParentId) {
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
    $Output = [Hashtable]::Synchronized(@{})

    $GetSubfolderParams = @{
        Cache        = $Cache
        Output       = $Output
        RecurseDepth = $RecurseDepth
        ErrorAction  = 'Continue'
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
            DebugOutputStream = $Cache.Value['DebugOutputStream'].Value
            TodaysHostname    = $Cache.Value['ThisHostname'].Value
            WhoAmI            = $Cache.Value['WhoAmI'].Value
            LogBuffer         = $LogBuffer
            Threads           = $Cache.Value['ThreadCount'].Value
            ProgressParentId  = $Progress['Id']
            AddParam          = $GetSubfolderParams
        }

        Split-Thread @SplitThreadParams

    }

    Write-Progress @Progress -Completed
    return $Output

}
