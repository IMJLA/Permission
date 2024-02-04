function Expand-AcctPermission {

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
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId

    )

    $Progress = @{
        Activity = 'Expand-AcctPermission'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }

    Write-Progress @Progress -Status '0% (step 1 of 1)' -CurrentOperation 'Initializing' -PercentComplete 0
    Start-Sleep -Seconds 5

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $Count = $SecurityPrincipal.Count

    if ($ThreadCount -eq 1) {

        [int]$ProgressInterval = [math]::max(($Count / 100), 1)
        $IntervalCounter = 0
        $i = 0

        ForEach ($ThisPrinc in $SecurityPrincipal) {

            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {

                [int]$PercentComplete = $i / $Count * 100
                Write-Progress @Progress -Status "$PercentComplete%" -CurrentOperation "Expand-AccountPermission '$($ThisPrinc.Name)'" -PercentComplete $PercentComplete
                $IntervalCounter = 0

            }

            $i++
            Write-LogMsg @LogParams -Text "Expand-AccountPermission -AccountPermission $($ThisPrinc.Name)"
            Expand-AccountPermission -AccountPermission $ThisPrinc
        }

    } else {

        $ExpandAccountPermissionParams = @{
            Command              = 'Expand-AccountPermission'
            InputObject          = $SecurityPrincipal
            InputParameter       = 'AccountPermission'
            TodaysHostname       = $ThisHostname
            ObjectStringProperty = 'Name'
            Timeout              = 1200
            Threads              = $ThreadCount
            AddParam             = @{
                WhoAmI      = $WhoAmI
                LogMsgCache = $LogMsgCache
            }
        }

        Write-LogMsg @LogParams -Text "Split-Thread -Command 'Expand-AccountPermission' -InputParameter 'AccountPermission' -InputObject `$SecurityPrincipal -ObjectStringProperty 'Name'"
        Split-Thread @ExpandAccountPermissionParams

    }

    Write-Progress @Progress -Completed
    Start-Sleep -Seconds 5

}
