
function Find-ServerFqdn {

    # Build a list of known ADSI server names to use to populate the caches
    # Include the FQDN of the current computer and the known trusted domains

    param (

        [uint64]$ParentCount,

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $Progress = Get-PermissionProgress -Activity 'Find-ServerFqdn' -Cache $Cache
    Write-Progress @Progress -Status "0% (path 0 of $ParentCount)" -CurrentOperation 'Initializing' -PercentComplete 0
    $ThisFqdn = $Cache.Value['ThisFqdn'].Value

    $UniqueValues = @{
        $ThisFqdn = $null
    }

    ForEach ($Value in $Cache.Value['DomainByFqdn'].Value.Keys) {
        $UniqueValues[$Value] = $null
    }

    # Add server names from the ACL paths

    $ProgressStopWatch = [System.Diagnostics.Stopwatch]::new()
    $ProgressStopWatch.Start()
    $LastRemainder = [int]::MaxValue
    $i = 0

    ForEach ($Parent in $Cache.Value['ParentBySourcePath'].Value.Values) {

        ForEach ($ThisPath in $Parent) {

            $NewRemainder = $ProgressStopWatch.ElapsedTicks % 5000

            if ($NewRemainder -lt $LastRemainder) {

                $LastRemainder = $NewRemainder
                [int]$PercentComplete = $i / $ParentCount * 100
                Write-Progress @Progress -Status "$PercentComplete% (path $($i + 1) of $ParentCount)" -CurrentOperation "Find-ServerNameInPath '$ThisPath'" -PercentComplete $PercentComplete

            }

            $i++ # increment $i after Write-Progress to show progress conservatively rather than optimistically
            $UniqueValues[(Find-ServerNameInPath -LiteralPath $ThisPath -Cache $Cache)] = $null

        }

    }

    Write-Progress @Progress -Completed
    return $UniqueValues.Keys

}
