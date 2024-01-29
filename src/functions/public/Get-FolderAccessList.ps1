function Get-FolderAccessList {
    param (

        # Path to the item whose permissions to export (inherited ACEs will be included)
        $Folder,

        # Path to the subfolders whose permissions to report (inherited ACEs will be skipped)
        $Subfolder,

        # Number of asynchronous threads to use
        [uint16]$ThreadCount = ((Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum),

        # Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module
        [string]$DebugOutputStream = 'Silent',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$TodaysHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # Thread-safe cache of items and their owners
        [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]$OwnerCache = [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]::new()

    )

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $TodaysHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    # We expect a small number of folders and a large number of subfolders
    # We will multithread the subfolders but not the folders
    # Multithreading overhead actually hurts performance for such a fast operation (Get-FolderAce) on a small number of items
    $i = 0
    ForEach ($ThisFolder in $Folder) {
        $PercentComplete = $i / $Folder.Count
        Write-Progress -Activity "Get-FolderAce -IncludeInherited" -CurrentOperation $ThisFolder -PercentComplete $PercentComplete
        $i++
        Get-FolderAce -LiteralPath $ThisFolder -OwnerCache $OwnerCache -IncludeInherited
    }
    Write-Progress -Activity "Get-FolderAce -IncludeInherited" -Completed

    if ($ThreadCount -eq 1) {

        [int]$ProgressInterval = [math]::max(($Subfolder.Count / 100), 1)
        $ProgressCounter = 0
        $i = 0
        Write-Progress -Activity "Get-FolderAce" -CurrentOperation 'Starting' -PercentComplete 0
        ForEach ($ThisFolder in $Subfolder) {
            $ProgressCounter++
            if ($ProgressCounter -eq $ProgressInterval) {
                $PercentComplete = $i / $Subfolder.Count * 100
                Write-Progress -Activity "Get-FolderAce" -CurrentOperation $ThisFolder -PercentComplete $PercentComplete
                $ProgressCounter = 0
            }
            $i++ # increment $i after the progress to show progress conservatively rather than optimistically

            Get-FolderAce -LiteralPath $ThisFolder -OwnerCache $OwnerCache
        }
        Write-Progress -Activity "Get-FolderAce" -Completed

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
                OwnerCache = $OwnerCache
            }
        }
        Split-Thread @GetFolderAce

    }

    # Return ACEs for the item owners (if they do not match the owner of the item's parent folder)
    # First return the owner of the parent item
    Get-OwnerAce -Item $Folder -OwnerCache $OwnerCache
    # Then return the owners of any items that differ from their parents' owners
    if ($ThreadCount -eq 1) {

        $ProgressCounter = 0
        $i = 0
        ForEach ($Child in $Subfolder) {
            $ProgressCounter++
            if ($ProgressCounter -eq $ProgressInterval) {
                $PercentComplete = $i / $Subfolder.Count * 100
                Write-Progress -Activity "Get-OwnerAce" -CurrentOperation $Child -PercentComplete $PercentComplete
                $ProgressCounter = 0
            }
            $i++
            Get-OwnerAce -Item $Child -OwnerCache $OwnerCache

        }
        Write-Progress -Activity "Get-OwnerAce" -Completed

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

}
