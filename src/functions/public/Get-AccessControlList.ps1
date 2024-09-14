function Get-AccessControlList {

    # Get folder access control lists
    # Returns an object representing each effective permission on a folder
    # This includes each Access Control Entry in the Discretionary Access List, as well as the folder's Owner

    param (

        # Path to the item whose permissions to export (inherited ACEs will be included)
        [Hashtable]$TargetPath,

        # Number of asynchronous threads to use
        [uint16]$ThreadCount = ((Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum),

        # Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module
        [String]$DebugOutputStream = 'Debug',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [String]$TodaysHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [String]$WhoAmI = (whoami.EXE),

        # Log messages which have not yet been written to disk
        [hashtable]$LogBuffer = ([Hashtable]::Synchronized(@{})),

        # Thread-safe cache of items and their owners
        [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]$OwnerCache = [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]::new(),

        # ID of the parent progress bar under which to show progress
        [int]$ProgressParentId,

        # Cache of access control lists keyed by path
        [hashtable]$Output = [Hashtable]::Synchronized(@{}),

        # Hashtable of warning messages to allow a summarized count in the Warning stream with detail in the Verbose stream
        [hashtable]$WarningCache = [Hashtable]::Synchronized(@{})
    )

    $LogParams = @{
        ThisHostname = $TodaysHostname
        Type         = $DebugOutputStream
        Buffer       = $LogBuffer
        WhoAmI       = $WhoAmI
    }

    $Progress = @{
        Activity = 'Get-AccessControlList'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $ProgressId = $ProgressParentId + 1
    } else {
        $ProgressId = 0
    }
    $Progress['Id'] = $ProgressId
    $ChildProgress = @{
        Activity = 'Get access control lists for parent and child items'
        Id       = $ProgressId + 1
        ParentId = $ProgressId
    }
    $GrandChildProgress = @{
        Activity = 'Get access control lists'
        Id       = $ProgressId + 2
        ParentId = $ProgressId + 1
    }

    Write-Progress @Progress -Status '0% (step 1 of 2) Get access control lists for parent and child items' -CurrentOperation 'Get access control lists for parent and child items' -PercentComplete 0

    $GetDirectorySecurity = @{
        LogBuffer         = $LogBuffer
        ThisHostname      = $TodaysHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
        OwnerCache        = $OwnerCache
        ACLsByPath        = $Output
        WarningCache      = $WarningCache
    }

    $TargetIndex = 0
    $ParentCount = $TargetPath.Keys.Count

    if ($ThreadCount -eq 1) {

        ForEach ($Parent in $TargetPath.Keys) {

            [int]$PercentComplete = $TargetIndex / $ParentCount * 100
            $TargetIndex++
            Write-Progress @ChildProgress -Status "$PercentComplete% (parent $TargetIndex of $ParentCount) Get access control lists" -CurrentOperation $Parent -PercentComplete $PercentComplete
            Write-Progress @GrandChildProgress -Status "0% (parent) Get-DirectorySecurity -IncludeInherited" -CurrentOperation $Parent -PercentComplete 0
            Get-DirectorySecurity -LiteralPath $Parent -IncludeInherited @GetDirectorySecurity
            $Children = $TargetPath[$Parent]
            $ChildCount = $Children.Count
            [int]$ProgressInterval = [math]::max(($ChildCount / 100), 1)
            $IntervalCounter = 0
            $ChildIndex = 0

            ForEach ($Child in $Children) {

                $IntervalCounter++

                if ($IntervalCounter -eq $ProgressInterval -or $ChildIndex -eq 0) {

                    [int]$PercentComplete = $ChildIndex / $ChildCount * 100
                    Write-Progress @GrandChildProgress -Status "$PercentComplete% (child $($ChildIndex + 1) of $ChildCount) Get-DirectorySecurity" -CurrentOperation $Child -PercentComplete $PercentComplete
                    $IntervalCounter = 0

                }

                $ChildIndex++ # increment $ChildIndex after the progress to show progress conservatively rather than optimistically
                Get-DirectorySecurity -LiteralPath $Child @GetDirectorySecurity

            }

            Write-Progress @GrandChildProgress -Completed

        }

        Write-Progress @ChildProgress -Completed

    } else {

        ForEach ($Parent in $TargetPath.Keys) {

            [int]$PercentComplete = $TargetIndex / $ParentCount * 100
            $TargetIndex++
            Write-Progress @ChildProgress -Status "$PercentComplete% (parent $TargetIndex of $ParentCount) Get access control lists" -CurrentOperation $Parent -PercentComplete $PercentComplete
            Get-DirectorySecurity -LiteralPath $Parent -IncludeInherited @GetDirectorySecurity
            $Children = $TargetPath[$Parent]

            $SplitThread = @{
                Command           = 'Get-DirectorySecurity'
                InputObject       = $Children
                InputParameter    = 'LiteralPath'
                DebugOutputStream = $DebugOutputStream
                TodaysHostname    = $TodaysHostname
                WhoAmI            = $WhoAmI
                LogBuffer         = $LogBuffer
                Threads           = $ThreadCount
                ProgressParentId  = $ChildProgress['Id']
                AddParam          = $GetDirectorySecurity
            }

            Split-Thread @SplitThread

        }

        Write-Progress @ChildProgress -Completed

    }

    if ($WarningCache.Keys.Count -ge 1) {

        $LogParams['Type'] = 'Warning' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat
        Write-LogMsg @LogParams -Text " # Errors on $($WarningCache.Keys.Count) items while getting access control lists.  See verbose log for details."

    }

    Write-Progress @Progress -Status '50% (step 2 of 2) Find non-inherited owners for parent and child items' -CurrentOperation 'Find non-inherited owners for parent and child items' -PercentComplete 50
    $ChildProgress['Activity'] = 'Get ACL owners'
    $GrandChildProgress['Activity'] = 'Get ACL owners'

    $GetOwnerAce = @{
        OwnerCache = $OwnerCache
        ACLsByPath = $Output
    }

    $ParentIndex = 0

    # Then return the owners of any items that differ from their parents' owners
    if ($ThreadCount -eq 1) {

        # Update the cache with ACEs for the item owners (if they do not match the owner of the item's parent folder)
        # First return the owner of the parent item

        ForEach ($Parent in $TargetPath.Keys) {

            [int]$PercentComplete = $ParentIndex / $ParentCount * 100
            $ParentIndex++
            Write-Progress @ChildProgress -Status "$PercentComplete% (parent $ParentIndex of $ParentCount) Find non-inherited ACL Owners" -CurrentOperation $Parent -PercentComplete $PercentComplete
            Write-Progress @GrandChildProgress -Status "0% (parent) Get-OwnerAce" -CurrentOperation $Parent -PercentComplete $PercentComplete
            Get-OwnerAce -Item $Parent @GetOwnerAce
            $Children = $TargetPath[$Parent]
            $ChildCount = $Children.Count
            [int]$ProgressInterval = [math]::max(($ChildCount / 100), 1)
            $IntervalCounter = 0
            $ChildIndex = 0

            ForEach ($Child in $Children) {

                $IntervalCounter++

                if ($IntervalCounter -eq $ProgressInterval -or $ChildIndex -eq 0) {

                    [int]$PercentComplete = $ChildIndex / $ChildCount * 100
                    Write-Progress @GrandChildProgress -Status "$PercentComplete% (child $($ChildIndex + 1) of $ChildCount)) Get-OwnerAce" -CurrentOperation $Child -PercentComplete $PercentComplete
                    $IntervalCounter = 0

                }

                $ChildIndex++
                Get-OwnerAce -Item $Child @GetOwnerAce

            }

            Write-Progress @GrandChildProgress -Completed

        }

        Write-Progress @ChildProgress -Completed

    } else {

        ForEach ($Parent in $TargetPath.Keys) {

            [int]$PercentComplete = $ParentIndex / $ParentCount * 100
            $ParentIndex++
            Write-Progress @ChildProgress -Status "$PercentComplete% (parent $ParentIndex of $ParentCount) Find non-inherited ACL Owners" -CurrentOperation $Parent -PercentComplete $PercentComplete
            Get-OwnerAce -Item $Parent @GetOwnerAce
            $Children = $TargetPath[$Parent]

            $SplitThread = @{
                Command           = 'Get-OwnerAce'
                InputObject       = $Children
                InputParameter    = 'Item'
                DebugOutputStream = $DebugOutputStream
                TodaysHostname    = $TodaysHostname
                WhoAmI            = $WhoAmI
                LogBuffer         = $LogBuffer
                Threads           = $ThreadCount
                ProgressParentId  = $ChildProgress['Id']
                AddParam          = $GetOwnerAce
            }

            Split-Thread @SplitThread

        }

    }

    Write-Progress @Progress -Completed

}
