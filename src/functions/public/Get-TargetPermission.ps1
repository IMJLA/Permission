function Get-TargetPermission {

    # Get folder access control lists
    # Returns an object representing each effective permission on a folder
    # This includes each Access Control Entry in the Discretionary Access List, as well as the folder's Owner

    param (

        # Path to the item whose permissions to export (inherited ACEs will be included)
        $TargetPath,

        # Path to the subfolders whose permissions to report (inherited ACEs will be skipped)
        [string[]]$Children,

        # Number of asynchronous threads to use
        [uint16]$ThreadCount = ((Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum),

        # Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module
        [string]$DebugOutputStream = 'Debug',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$TodaysHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # Thread-safe cache of items and their owners
        [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]$OwnerCache = [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]::new(),

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId,

        # Cache of access control lists keyed by path
        [hashtable]$AclByPath = [hashtable]::Synchronized(@{})

    )

    $Progress = @{
        Activity = 'Get-FolderAcl'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $ProgressId = $ProgressParentId + 1
    } else {
        $ProgressId = 0
    }
    $Progress['Id'] = $ProgressId
    $ChildProgress = @{
        Activity = 'Get folder access control lists'
        Id       = $ProgressId + 1
        ParentId = $ProgressId
    }

    Write-Progress @Progress -Status '0% (step 1 of 2)' -CurrentOperation 'Get parent folder access control lists' -PercentComplete 0

    $GetDirectorySecurity = @{
        LogMsgCache       = $LogMsgCache
        ThisHostname      = $TodaysHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
        OwnerCache        = $OwnerCache
        ACLsByPath        = $AclByPath
    }

    # We expect a small number of folders and a large number of subfolders
    # We will multithread the subfolders but not the folders
    # Multithreading overhead actually hurts performance for such a fast operation (Get-FolderAcl) on a small number of items
    $i = 0
    $Count = $TargetPath.Count

    ForEach ($ThisFolder in $TargetPath) {

        [int]$PercentComplete = $i / $Count * 100
        Write-Progress @ChildProgress -Status "$PercentComplete% (parent $($i + 1) of $Count) Get-DirectorySecurity -IncludeInherited" -CurrentOperation $ThisFolder -PercentComplete $PercentComplete
        $i++
        Get-DirectorySecurity -LiteralPath $ThisFolder -IncludeInherited @GetDirectorySecurity

    }

    Write-Progress @ChildProgress -Completed
    $ChildProgress['Activity'] = 'Get-FolderAcl (subfolders)'
    Write-Progress @Progress -Status '25% (step 2 of 4)' -CurrentOperation 'Get subfolder access control lists' -PercentComplete 25
    $ChildrenCount = $Children.Count

    if ($ThreadCount -eq 1) {

        Write-Progress @ChildProgress -Status "0% (subfolder 0 of $ChildrenCount)" -CurrentOperation 'Initializing' -PercentComplete 0
        [int]$ProgressInterval = [math]::max(($ChildrenCount / 100), 1)
        $IntervalCounter = 0
        $i = 0

        ForEach ($ThisFolder in $Children) {

            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {

                [int]$PercentComplete = $i / $ChildrenCount * 100
                Write-Progress @ChildProgress -Status "$PercentComplete% (subfolder $($i + 1) of $ChildrenCount) Get-DirectorySecurity" -CurrentOperation $ThisFolder -PercentComplete $PercentComplete
                $IntervalCounter = 0

            }

            $i++ # increment $i after the progress to show progress conservatively rather than optimistically
            Get-DirectorySecurity -LiteralPath $ThisFolder @GetDirectorySecurity

        }

        Write-Progress @ChildProgress -Completed

    } else {

        $SplitThread = @{
            Command           = 'Get-DirectorySecurity'
            InputObject       = $Children
            InputParameter    = 'LiteralPath'
            DebugOutputStream = $DebugOutputStream
            TodaysHostname    = $TodaysHostname
            WhoAmI            = $WhoAmI
            LogMsgCache       = $LogMsgCache
            Threads           = $ThreadCount
            AddParam          = $GetDirectorySecurity

        }

        Split-Thread @SplitThread

    }

    # Update the cache with ACEs for the item owners (if they do not match the owner of the item's parent folder)
    # First return the owner of the parent item
    Write-Progress @Progress -Status '50% (step 3 of 4) Get-OwnerAce (parent folders)' -CurrentOperation 'Get parent folder owners' -PercentComplete 50
    $ChildProgress['Activity'] = 'Get-FolderAcl (parent owners)'
    $i = 0

    $GetOwnerAce = @{
        OwnerCache = $OwnerCache
        ACLsByPath = $AclByPath
    }

    ForEach ($ThisFolder in $TargetPath) {

        [int]$PercentComplete = $i / $Count * 100
        $i++
        Write-Progress @ChildProgress -Status "$PercentComplete% (parent $i of $Count) Get-OwnerAce" -CurrentOperation $ThisFolder -PercentComplete $PercentComplete
        Get-OwnerAce -Item $ThisFolder @GetOwnerAce

    }

    Write-Progress @ChildProgress -Completed
    Write-Progress @Progress -Status '75% (step 4 of 4) Get-OwnerAce (subfolders)' -CurrentOperation 'Get subfolder owners' -PercentComplete 75
    $ChildProgress['Activity'] = 'Get-FolderAcl (subfolder owners)'

    # Then return the owners of any items that differ from their parents' owners
    if ($ThreadCount -eq 1) {

        $IntervalCounter = 0
        $i = 0

        ForEach ($ThisFolder in $Children) {

            Write-Progress @ChildProgress -Status '0%' -CurrentOperation 'Initializing'
            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {

                [int]$PercentComplete = $i / $ChildrenCount * 100
                Write-Progress @ChildProgress -Status "$PercentComplete% (subfolder $($i + 1) of $ChildrenCount)) Get-OwnerAce" -CurrentOperation $ThisFolder -PercentComplete $PercentComplete
                $IntervalCounter = 0

            }

            $i++
            Get-OwnerAce -Item $ThisFolder @GetOwnerAce

        }

        Write-Progress @ChildProgress -Completed

    } else {

        $SplitThread = @{
            Command           = 'Get-OwnerAce'
            InputObject       = $Children
            InputParameter    = 'Item'
            DebugOutputStream = $DebugOutputStream
            TodaysHostname    = $TodaysHostname
            WhoAmI            = $WhoAmI
            LogMsgCache       = $LogMsgCache
            Threads           = $ThreadCount
            AddParam          = $GetOwnerAce
        }

        Split-Thread @SplitThread

    }

    Write-Progress @Progress -Completed

}
