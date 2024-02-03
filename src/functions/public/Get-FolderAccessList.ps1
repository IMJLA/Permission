function Get-FolderAccessList {
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
        [int]$ProgressParentId

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

    Write-Progress @Progress -Status '0% (step 1 of 4)' -CurrentOperation 'Get parent access control lists' -PercentComplete 0
    Start-Sleep -Seconds 5

    $GetFolderAceParams = @{
        LogMsgCache       = $LogMsgCache
        ThisHostname      = $TodaysHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
    }

    # We expect a small number of folders and a large number of subfolders
    # We will multithread the subfolders but not the folders
    # Multithreading overhead actually hurts performance for such a fast operation (Get-FolderAce) on a small number of items
    $i = 0
    $Count = $Folder.Count
    ForEach ($ThisFolder in $Folder) {
        [int]$PercentComplete = $i / $Count * 100
        Write-Progress @ChildProgress -Status "$PercentComplete% (parent $($i + 1) of $Count)" -CurrentOperation "Get-FolderAce -IncludeInherited '$ThisFolder'" -PercentComplete $PercentComplete
        $i++
        Get-FolderAce -LiteralPath $ThisFolder -OwnerCache $OwnerCache -LogMsgCache $LogMsgCache -IncludeInherited @GetFolderAceParams
    }

    Write-Progress @ChildProgress -Completed
    Start-Sleep -Seconds 5
    $ChildProgress['Activity'] = 'Get-FolderAccessList (child DACLs)'
    Write-Progress @Progress -Status '25% (step 2 of 4)' -CurrentOperation $ChildProgress['Activity'] -PercentComplete 25
    Start-Sleep -Seconds 5
    $SubfolderCount = $Subfolder.Count

    if ($ThreadCount -eq 1) {
        Write-Progress @ChildProgress -Status '0%' -CurrentOperation 'Initializing'
        [int]$ProgressInterval = [math]::max(($SubfolderCount / 100), 1)
        $IntervalCounter = 0
        $i = 0
        ForEach ($ThisFolder in $Subfolder) {
            $IntervalCounter++
            if ($IntervalCounter -eq $ProgressInterval) {
                [int]$PercentComplete = $i / $SubfolderCount * 100
                Write-Progress @ChildProgress -Status "$PercentComplete% (child $($i + 1) of $SubfolderCount)" -CurrentOperation "Get-FolderAce '$ThisFolder'" -PercentComplete $PercentComplete
                $IntervalCounter = 0
            }
            $i++ # increment $i after the progress to show progress conservatively rather than optimistically

            Get-FolderAce -LiteralPath $ThisFolder -LogMsgCache $LogMsgCache -OwnerCache $OwnerCache @GetFolderAceParams
        }

        Write-Progress @ChildProgress -Completed
        Start-Sleep -Seconds 5
        Write-Progress @Progress -Status '50% (step 3 of 4)' -CurrentOperation 'Parent Owners' -PercentComplete 50
        Start-Sleep -Seconds 5

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
            AddParam          = @{
                OwnerCache        = $OwnerCache
                LogMsgCache       = $LogMsgCache
                ThisHostname      = $TodaysHostname
                DebugOutputStream = $DebugOutputStream
                WhoAmI            = $WhoAmI
            }

        }

        Split-Thread @GetFolderAce

    }

    # Return ACEs for the item owners (if they do not match the owner of the item's parent folder)
    # First return the owner of the parent item
    # We expect a small number of folders and a large number of subfolders
    # We will multithread the subfolders but not the folders
    # Multithreading overhead actually hurts performance for such a fast operation (Get-FolderAce) on a small number of items
    $ChildProgress['Activity'] = 'Get-FolderAccessList (parent owners)'
    $i = 0
    ForEach ($ThisFolder in $Folder) {
        [int]$PercentComplete = $i / $Count * 100
        Write-Progress @ChildProgress -Status "$PercentComplete% (parent $($i + 1) of $Count)" -CurrentOperation "Get-OwnerAce '$ThisFolder'" -PercentComplete $PercentComplete
        $i++
        Get-OwnerAce -Item $ThisFolder -OwnerCache $OwnerCache
    }
    Write-Progress @ChildProgress -Completed
    Start-Sleep -Seconds 5
    Write-Progress @Progress -Status '75% (step 4 of 4)' -CurrentOperation 'Child Owners' -PercentComplete 75
    Start-Sleep -Seconds 5
    $ChildProgress['Activity'] = 'Get-FolderAccessList (child owners)'

    # Then return the owners of any items that differ from their parents' owners
    if ($ThreadCount -eq 1) {

        $IntervalCounter = 0
        $i = 0
        ForEach ($Child in $Subfolder) {
            Write-Progress @ChildProgress -Status '0%' -CurrentOperation 'Initializing'
            $IntervalCounter++
            if ($IntervalCounter -eq $ProgressInterval) {
                [int]$PercentComplete = $i / $SubfolderCount * 100
                Write-Progress @ChildProgress -Status "$PercentComplete% (child $($i + 1) of $SubfolderCount))" -CurrentOperation "Get-FolderAce '$Child'" -PercentComplete $PercentComplete
                $IntervalCounter = 0
            }
            $i++
            Get-OwnerAce -Item $Child -OwnerCache $OwnerCache

        }
        Write-Progress @ChildProgress -Completed
        Start-Sleep -Seconds 5

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
            AddParam          = @{
                OwnerCache = $OwnerCache
            }
        }

        Split-Thread @GetOwnerAce

    }

    Write-Progress @Progress -Completed
    Start-Sleep -Seconds 5

}
