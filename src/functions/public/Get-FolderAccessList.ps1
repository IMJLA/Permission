function Get-FolderAccessList {
    param (

        # Path to the item whose permissions to export
        $FolderTargets,

        <#
        How many levels of subfolder to enumerate

            Set to 0 to ignore all subfolders

            Set to -1 (default) to recurse infinitely

            Set to any whole number to enumerate that many levels
        #>
        $LevelsOfSubfolders,

        # Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module
        [string]$DebugOutputStream = 'Silent',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$TodaysHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages

    )
    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $TodaysHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    ForEach ($ThisFolder in $FolderTargets) {
        $Subfolders = $null
        $Subfolders = Get-Subfolder -TargetPath $ThisFolder -FolderRecursionDepth $LevelsOfSubfolders -ErrorAction Continue
        Write-LogMsg @LogParams -Text "Folders (including parent): $($Subfolders.Count + 1)"
        Get-FolderAce -LiteralPath $ThisFolder -IncludeInherited
        if ($Subfolders) {
            $GetFolderAce = @{
                Command           = Get-FolderAce
                InputObject       = $Subfolders
                InputParameter    = 'LiteralPath'
                DebugOutputStream = $DebugOutputStream
                TodaysHostname    = $TodaysHostname
                WhoAmI            = $WhoAmI
                LogMsgCache       = $LogMsgCache
            }
            Split-Thread @GetFolderAce
        }
    }
}
