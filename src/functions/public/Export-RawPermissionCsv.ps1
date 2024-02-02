function Export-RawPermissionCsv {

    # Export permissions to CSV

    param (

        # Permission objects from Get-FolderAccessList to export to CSV
        [Object[]]$Permission,

        # Path to the CSV file to create
        # Will be passed to the LiteralPath parameter of Export-Csv
        [string]$LiteralPath,

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Hostname to use in the log messages and/or output object
        [string]$ThisHostname = (HOSTNAME.EXE),

        # Hostname to use in the log messages and/or output object
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages

    )

    $LogParams = @{
        LogMsgCache       = $LogMsgCache
        ThisHostname      = $ThisHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
    }

    $Activity = "`$Formatted = ForEach (`$Obj in $`Permissions) {`[PSCustomObject]@{Path=`$Obj.SourceAccessList.Path;IdentityReference=`$Obj.IdentityReference;AccessControlType=`$Obj.AccessControlType;FileSystemRights=`$Obj.FileSystemRights;IsInherited=`$Obj.IsInherited;PropagationFlags=`$Obj.PropagationFlags;InheritanceFlags=`$Obj.InheritanceFlags;Source=`$Obj.Source}"
    Write-LogMsg @LogParams -Text $Activity
    Write-Progress -Activity $Activity -PercentComplete 50


    $Formatted = ForEach ($Obj in $Permission) {
        [PSCustomObject]@{
            Path              = $Obj.SourceAccessList.Path
            IdentityReference = $Obj.IdentityReference
            AccessControlType = $Obj.AccessControlType
            FileSystemRights  = $Obj.FileSystemRights
            IsInherited       = $Obj.IsInherited
            PropagationFlags  = $Obj.PropagationFlags
            InheritanceFlags  = $Obj.InheritanceFlags
            Source            = $Obj.Source
        }
    }

    Write-Progress -Activity $Activity -Completed
    $Activity = "`$Formatted | Export-Csv -NoTypeInformation -LiteralPath '$LiteralPath'"
    Write-LogMsg @LogParams -Text $Activity
    Write-Progress -Activity $Activity -PercentComplete 50

    $Formatted |
    Export-Csv -NoTypeInformation -LiteralPath $LiteralPath

    Write-Progress -Activity $Activity -Completed
    Write-Information $LiteralPath

}
