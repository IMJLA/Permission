
# Build a list of known ADSI server names to use to populate the caches
# Include the FQDN of the current computer and the known trusted domains
function Find-ServerFqdn {

    param (

        # Known server FQDNs to include in the output
        [string[]]$Known,

        # File paths whose server FQDNs to include in the output
        [Hashtable]$TargetPath,

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [String]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # ID of the parent progress bar under which to show progress
        [int]$ProgressParentId

    )

    $Progress = @{
        Activity = 'Find-ServerFqdn'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $ProgressId = $ProgressParentId + 1
    } else {
        $ProgressId = 0
    }

    $Progress['Id'] = $ProgressId
    $Count = $TargetPath.Keys.Count
    Write-Progress @Progress -Status "0% (path 0 of $Count)" -CurrentOperation 'Initializing' -PercentComplete 0

    $UniqueValues = @{
        $ThisFqdn = $null
    }

    ForEach ($Value in $Known) {
        $UniqueValues[$Value] = $null
    }

    # Add server names from the ACL paths

    $ProgressStopWatch = [System.Diagnostics.Stopwatch]::new()
    $ProgressStopWatch.Start()
    $LastRemainder = [int]::MaxValue
    $i = 0

    ForEach ($ThisPath in $TargetPath.Keys) {

        $NewRemainder = $ProgressStopWatch.ElapsedTicks % 5000

        if ($NewRemainder -lt $LastRemainder) {

            $LastRemainder = $NewRemainder
            [int]$PercentComplete = $i / $Count * 100
            Write-Progress @Progress -Status "$PercentComplete% (path $($i + 1) of $Count)" -CurrentOperation "Find-ServerNameInPath '$ThisPath'" -PercentComplete $PercentComplete

        }

        $i++ # increment $i after Write-Progress to show progress conservatively rather than optimistically
        $UniqueValues[(Find-ServerNameInPath -LiteralPath $ThisPath -ThisFqdn $ThisFqdn)] = $null
    }

    Write-Progress @Progress -Completed

    return $UniqueValues.Keys

}
