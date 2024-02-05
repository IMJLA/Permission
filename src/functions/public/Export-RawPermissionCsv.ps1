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
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId

    )

    $Progress = @{
        Activity = 'Export-RawPermissionCsv'
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

    Write-Progress @Progress -Status '0% (step 1 of 2)' -CurrentOperation 'Flattening the raw access control entries for CSV export' -PercentComplete 0

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    Write-LogMsg @LogParams -Text "`$Formatted = ForEach (`$Obj in $`Permissions) {`[PSCustomObject]@{Path=`$Obj.SourceAccessList.Path;IdentityReference=`$Obj.IdentityReference;AccessControlType=`$Obj.AccessControlType;FileSystemRights=`$Obj.FileSystemRights;IsInherited=`$Obj.IsInherited;PropagationFlags=`$Obj.PropagationFlags;InheritanceFlags=`$Obj.InheritanceFlags;Source=`$Obj.Source}"

    # Prepare to show the progress bar, but no more often than every 1%
    $Count = $Permission.Count
    [int]$ProgressInterval = [math]::max(($Count / 100), 1)
    $IntervalCounter = 0
    $i = 0

    # 'Flatten the access control entries for CSV export'
    $Formatted = ForEach ($Obj in $Permission) {

        $IntervalCounter = 0

        if ($IntervalCounter -eq $ProgressInterval) {

            [int]$PercentComplete = $i / $Count * 100
            Write-Progress @ChildProgress -Status "$PercentComplete% (access control entry $($i + 1) of $Count)" -CurrentOperation "'$($Obj.IdentityReference)' on '$($Obj.SourceAccessList.Path)'" -PercentComplete $PercentComplete
            $IntervalCounter = 0

        }

        $i++ # increment $i after the progress to show progress conservatively rather than optimistically

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

        Write-Progress @ChildProgress -Completed
        Write-Progress @Progress -Status '50% (step 2 of 2)' -CurrentOperation "Saving '$LiteralPath'" -PercentComplete 50
        Write-LogMsg @LogParams -Text "`$Formatted | Export-Csv -NoTypeInformation -LiteralPath '$LiteralPath'"

    $Formatted |
    Export-Csv -NoTypeInformation -LiteralPath $LiteralPath

    Write-Information $LiteralPath
    Write-Progress @Progress -Completed

}
