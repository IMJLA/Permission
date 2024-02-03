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
        [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]$OwnerCache = [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]::new()

    )

    Write-Progress -Activity 'Get-FolderAccessList' -Status '0%' -CurrentOperation 'Initializing' -PercentComplete 0 -Id 0

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
        [int]$PercentComplete = $i / $Count
        Write-Progress -Activity 'Get-FolderAccessList (parent folders)' -Status "$PercentComplete%" -CurrentOperation "Get-FolderAce -IncludeInherited '$ThisFolder'" -PercentComplete $PercentComplete -ParentId 0 -Id 1
        $i++
        Get-FolderAce -LiteralPath $ThisFolder -OwnerCache $OwnerCache -LogMsgCache $LogMsgCache -IncludeInherited @GetFolderAceParams
    }
    Write-Progress -Activity 'Get-FolderAccessList (parent folders)' -Completed -Id 1

    if ($ThreadCount -eq 1) {

        [int]$ProgressInterval = [math]::max(($Subfolder.Count / 100), 1)
        $ProgressCounter = 0
        $i = 0
        ForEach ($ThisFolder in $Subfolder) {
            $ProgressCounter++
            if ($ProgressCounter -eq $ProgressInterval) {
                [int]$PercentComplete = $i / $Subfolder.Count * 100
                Write-Progress -Activity 'Get-FolderAccessList (subfolder DACLs)' -Status "$PercentComplete%" -CurrentOperation "Get-FolderAce '$ThisFolder'" -PercentComplete $PercentComplete -ParentId 0 -Id 1
                $ProgressCounter = 0
            }
            $i++ # increment $i after the progress to show progress conservatively rather than optimistically

            Get-FolderAce -LiteralPath $ThisFolder -LogMsgCache $LogMsgCache -OwnerCache $OwnerCache @GetFolderAceParams
        }
        Write-Progress -Activity 'Get-FolderAccessList (subfolder DACLs)' -Completed -Id 1

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
    $i = 0
    ForEach ($ThisFolder in $Folder) {
        [int]$PercentComplete = $i / $Count
        Write-Progress -Activity 'Get-FolderAccessList (parent folder owners)' -Status "$PercentComplete%" -CurrentOperation "Get-FolderAce -IncludeInherited '$ThisFolder'" -PercentComplete $PercentComplete -ParentId 0 -Id 1
        $i++
        Get-OwnerAce -Item $ThisFolder -OwnerCache $OwnerCache
    }
    Write-Progress -Activity 'Get-FolderAccessList (parent folder owners)' -Completed -Id 1

    # Then return the owners of any items that differ from their parents' owners
    if ($ThreadCount -eq 1) {

        $ProgressCounter = 0
        $i = 0
        ForEach ($Child in $Subfolder) {
            $ProgressCounter++
            if ($ProgressCounter -eq $ProgressInterval) {
                [int]$PercentComplete = $i / $Subfolder.Count * 100
                Write-Progress -Activity 'Get-FolderAccessList (subfolder owners)' -Status "$PercentComplete%" -CurrentOperation "Get-FolderAce '$Child'" -PercentComplete $PercentComplete -ParentId 0 -Id 1
                $ProgressCounter = 0
            }
            $i++
            Get-OwnerAce -Item $Child -OwnerCache $OwnerCache

        }
        Write-Progress -Activity 'Get-FolderAccessList (subfolder owners)' -Completed -Id 1

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

    Write-Progress -Activity 'Get-FolderAccessList' -Completed -Id 0

}
