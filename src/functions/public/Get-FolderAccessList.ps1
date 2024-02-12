function Get-FolderAccessList {

    # Get folder access control lists
    # Returns an object representing each effective permission on a folder
    # This includes each Access Control Entry in the Discretionary Access List, as well as the folder's Owner

    param (

        # Path to the item whose permissions to export (inherited ACEs will be included)
        $Folder,

        # Path to the subfolders whose permissions to report (inherited ACEs will be skipped)
        $Subfolder,

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
        [hashtable]$ACLsByPath = [hashtable]::Synchronized(@{})

    )

    $Progress = @{
        Activity = 'Get-FolderAccessList'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $ProgressId = $ProgressParentId + 1
    } else {
        $ProgressId = 0
    }
    $Progress['Id'] = $ProgressId
    $ChildProgress = @{
        Activity = 'Flatten the raw access control entries for CSV export'
        Id       = $ProgressId + 1
        ParentId = $ProgressId
    }

    Write-Progress @Progress -Status '0% (step 1 of 2)' -CurrentOperation 'Get parent access control lists' -PercentComplete 0

    $GetFolderAceParams = @{
        LogMsgCache       = $LogMsgCache
        ThisHostname      = $TodaysHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
        OwnerCache        = $OwnerCache
        ACLsByPath        = $ACLsByPath
    }

    # We expect a small number of folders and a large number of subfolders
    # We will multithread the subfolders but not the folders
    # Multithreading overhead actually hurts performance for such a fast operation (Get-FolderAce) on a small number of items
    $i = 0
    $Count = $Folder.Count

    ForEach ($ThisFolder in $Folder) {

        [int]$PercentComplete = $i / $Count * 100
        Write-Progress @ChildProgress -Status "$PercentComplete% (parent $($i + 1) of $Count) Get-FolderAce -IncludeInherited" -CurrentOperation $ThisFolder -PercentComplete $PercentComplete
        $i++
        Get-FolderAce -LiteralPath $ThisFolder -IncludeInherited @GetFolderAceParams

    }

    Write-Progress @ChildProgress -Completed
    $ChildProgress['Activity'] = 'Get-FolderAccessList (subfolders)'
    Write-Progress @Progress -Status '25% (step 2 of 4)' -CurrentOperation 'Get subfolder access control lists' -PercentComplete 25
    $SubfolderCount = $Subfolder.Count

    if ($ThreadCount -eq 1) {

        Write-Progress @ChildProgress -Status "0% (subfolder 0 of $SubfolderCount)" -CurrentOperation 'Initializing' -PercentComplete 0
        [int]$ProgressInterval = [math]::max(($SubfolderCount / 100), 1)
        $IntervalCounter = 0
        $i = 0

        ForEach ($ThisFolder in $Subfolder) {

            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {

                [int]$PercentComplete = $i / $SubfolderCount * 100
                Write-Progress @ChildProgress -Status "$PercentComplete% (subfolder $($i + 1) of $SubfolderCount) Get-FolderAce" -CurrentOperation $ThisFolder -PercentComplete $PercentComplete
                $IntervalCounter = 0

            }

            $i++ # increment $i after the progress to show progress conservatively rather than optimistically
            Get-FolderAce -LiteralPath $ThisFolder @GetFolderAceParams

        }

        Write-Progress @ChildProgress -Completed

    } else {

        $GetFolderAce = @{
            Command           = 'Get-FolderAce'
            InputObject       = $Subfolder
            InputParameter    = 'LiteralPath'
            DebugOutputStream = $DebugOutputStream
            TodaysHostname    = $TodaysHostname
            WhoAmI            = $WhoAmI
            LogMsgCache       = $LogMsgCache
            Threads           = $ThreadCount
            AddParam          = $GetFolderAceParams

        }

        Split-Thread @GetFolderAce

    }

    # Update the cache with ACEs for the item owners (if they do not match the owner of the item's parent folder)
    # First return the owner of the parent item
    Write-Progress @Progress -Status '50% (step 3 of 4) Get-OwnerAce (parent folders)' -CurrentOperation 'Get parent folder owners' -PercentComplete 50
    $ChildProgress['Activity'] = 'Get-FolderAccessList (parent owners)'
    $i = 0

    ForEach ($ThisFolder in $Folder) {

        [int]$PercentComplete = $i / $Count * 100
        Write-Progress @ChildProgress -Status "$PercentComplete% (parent $($i + 1) of $Count) Get-OwnerAce" -CurrentOperation $ThisFolder -PercentComplete $PercentComplete
        $i++
        Get-OwnerAce -Item $ThisFolder -OwnerCache $OwnerCache

    }

    Write-Progress @ChildProgress -Completed
    Write-Progress @Progress -Status '75% (step 4 of 4) Get-OwnerAce (subfolders)' -CurrentOperation 'Get subfolder owners' -PercentComplete 75
    $ChildProgress['Activity'] = 'Get-FolderAccessList (subfolder owners)'

    $GetOwnerAceParams = @{
        OwnerCache = $OwnerCache
        ACLsByPath = $ACLsByPath
    }

    # Then return the owners of any items that differ from their parents' owners
    if ($ThreadCount -eq 1) {

        $IntervalCounter = 0
        $i = 0

        ForEach ($ThisFolder in $Subfolder) {

            Write-Progress @ChildProgress -Status '0%' -CurrentOperation 'Initializing'
            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {
                [int]$PercentComplete = $i / $SubfolderCount * 100
                Write-Progress @ChildProgress -Status "$PercentComplete% (subfolder $($i + 1) of $SubfolderCount)) Get-OwnerAce" -CurrentOperation $ThisFolder -PercentComplete $PercentComplete
                $IntervalCounter = 0
            }

            $i++
            Get-OwnerAce -Item $ThisFolder @GetOwnerAceParams

        }

        Write-Progress @ChildProgress -Completed

    } else {

        $GetOwnerAce = @{
            Command           = 'Get-OwnerAce'
            InputObject       = $Subfolder
            InputParameter    = 'Item'
            DebugOutputStream = $DebugOutputStream
            TodaysHostname    = $TodaysHostname
            WhoAmI            = $WhoAmI
            LogMsgCache       = $LogMsgCache
            Threads           = $ThreadCount
            AddParam          = $GetOwnerAceParams
        }

        Split-Thread @GetOwnerAce

    }

    Write-Progress @Progress -Completed

}
