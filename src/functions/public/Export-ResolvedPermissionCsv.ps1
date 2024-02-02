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

        [hashtable]$LogMsgCache = $Global:LogMessages

    )

    Write-Progress -Activity 'Export-ResolvedPermissionCsv' -CurrentOperation 'Initializing' -Status '0%' -PercentComplete 0

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    Write-LogMsg @LogParams -Text "`$PermissionsWithResolvedIdentityReferences |"
    Write-LogMsg @LogParams -Text "`Select-Object -Property @{ Label = 'Path'; Expression = { `$_.SourceAccessList.Path } }, * |"
    Write-LogMsg @LogParams -Text "Export-Csv -NoTypeInformation -LiteralPath '$LiteralPath'"
    Write-Progress -Activity 'Export-ResolvedPermissionCsv' -CurrentOperation "Export-Csv '$LiteralPath'" -Status "$([int]$PercentComplete)%" -PercentComplete 50

    $Permission |
    Select-Object -Property @{
        Label      = 'Path'
        Expression = { $_.SourceAccessList.Path }
    }, * |
    Export-Csv -NoTypeInformation -LiteralPath $CsvFiLiteralPathlePath2

    Write-Progress -Activity 'Export-ResolvedPermissionCsv' -Completed
    Write-Information $LiteralPath

}
