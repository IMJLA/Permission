function Format-PermissionAccount {

    param (

        # Permission objects from Get-FolderAccessList whose IdentityReference to resolve
        [Parameter(ValueFromPipeline)]
        [object[]]$SecurityPrincipal,

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Maximum number of concurrent threads to allow
        [int]$ThreadCount = (Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum,

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages

    )

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $Count = $SecurityPrincipal.Count

    if ($ThreadCount -eq 1) {

        [int]$ProgressInterval = [math]::max(($Count / 100), 1)
        $ProgressCounter = 0
        $i = 0

        ForEach ($ThisPrinc in $SecurityPrincipal) {

            $ProgressCounter++

            if ($ProgressCounter -eq $ProgressInterval) {

                $PercentComplete = $i / $Count * 100
                Write-Progress -Activity 'Format-SecurityPrincipal' -Status "$([int]$PercentComplete)%" -CurrentOperation $ThisPrinc.Name -PercentComplete $PercentComplete
                $ProgressCounter = 0

            }
            $i++

            Write-LogMsg @LogParams -Text "Format-SecurityPrincipal -SecurityPrincipal $($ThisPrinc.Name)"
            Format-SecurityPrincipal -SecurityPrincipal $ThisPrinc

        }

        Write-Progress -Activity 'Format-SecurityPrincipal' -Completed

    } else {

        $FormatSecurityPrincipalParams = @{
            Command              = 'Format-SecurityPrincipal'
            InputObject          = $SecurityPrincipal
            InputParameter       = 'SecurityPrincipal'
            Timeout              = 1200
            ObjectStringProperty = 'Name'
            TodaysHostname       = $ThisHostname
            WhoAmI               = $WhoAmI
            LogMsgCache          = $LogMsgCache
            Threads              = $ThreadCount
        }

        Write-LogMsg @LogParams -Text "Split-Thread -Command 'Format-SecurityPrincipal' -InputParameter 'SecurityPrincipal' -InputObject `$SecurityPrincipal -ObjectStringProperty 'Name'"
        Split-Thread @FormatSecurityPrincipalParams

    }

}
