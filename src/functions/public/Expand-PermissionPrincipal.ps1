function Expand-PermissionPrincipal {

    # Expand ADSI security principals into their group members

    param (

        # Permission objects from Get-FolderAccessList whose IdentityReference to resolve
        [Parameter(ValueFromPipeline)]
        [string[]]$ResolvedID,

        # Thread-safe hashtable to use for caching directory entries and avoiding duplicate directory queries
        [hashtable]$PrincipalsByResolvedID = ([hashtable]::Synchronized(@{})),

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
        Activity = 'Format-PermissionAccount'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }

    Write-Progress @Progress -Status "0% (principal 0 of $Count)" -CurrentOperation 'Initializing' -PercentComplete 0

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $Count = $PrincipalsByResolvedID.Keys.Count

    $FormatSecurityPrincipalParams = @{
        PrincipalsByResolvedID = $PrincipalsByResolvedID
    }

    if ($ThreadCount -eq 1) {

        [int]$ProgressInterval = [math]::max(($Count / 100), 1)
        $IntervalCounter = 0
        $i = 0

        ForEach ($ThisID in $ResolvedID) {

            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {

                [int]$PercentComplete = $i / $Count * 100
                Write-Progress @Progress -Status "$PercentComplete% (principal $($i + 1) of $Count) Format-SecurityPrincipal" -CurrentOperation $ThisID -PercentComplete $PercentComplete
                $IntervalCounter = 0

            }

            $i++
            Write-LogMsg @LogParams -Text "Format-SecurityPrincipal -ResolvedID '$ThisID'"
            Format-SecurityPrincipal -ResolvedID $ThisID @FormatSecurityPrincipalParams

        }

    } else {

        $SplitThreadParams = @{
            Command              = 'Format-SecurityPrincipal'
            InputObject          = $ResolvedID
            InputParameter       = 'ResolvedID'
            Timeout              = 1200
            ObjectStringProperty = 'Name'
            TodaysHostname       = $ThisHostname
            WhoAmI               = $WhoAmI
            LogMsgCache          = $LogMsgCache
            Threads              = $ThreadCount
            AddParam             = $FormatSecurityPrincipalParams
        }

        Write-LogMsg @LogParams -Text "Split-Thread -Command 'Format-SecurityPrincipal' -InputParameter 'SecurityPrincipal' -InputObject `$SecurityPrincipal -ObjectStringProperty 'Name'"
        Split-Thread @SplitThreadParams

    }

    Write-Progress @Progress -Completed

}
