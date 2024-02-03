function Export-ResolvedPermissionCsv {

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

        [hashtable]$LogMsgCache = $Global:LogMessages,

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId

    )

    $Progress = @{
        Activity = 'Export-RawPermissionCsv'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    Write-LogMsg @LogParams -Text "`$PermissionsWithResolvedIdentityReferences | `Select-Object -Property @{ Label = 'Path'; Expression = { `$_.SourceAccessList.Path } }, * | Export-Csv -NoTypeInformation -LiteralPath '$LiteralPath'"
    Write-Progress @Progress -Status '0% (step 1 of 1)' -CurrentOperation "Export-Csv '$LiteralPath'" -PercentComplete 50

    $Permission |
    Select-Object -Property @{
        Label      = 'Path'
        Expression = { $_.SourceAccessList.Path }
    }, * |
    Export-Csv -NoTypeInformation -LiteralPath $LiteralPath

    Write-Progress @Progress -Completed
    Write-Information $LiteralPath

}
