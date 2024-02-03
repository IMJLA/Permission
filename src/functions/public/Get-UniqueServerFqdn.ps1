
# Build a list of known ADSI server names to use to populate the caches
# Include the FQDN of the current computer and the known trusted domains
function Get-UniqueServerFqdn {

    param (

        # Known server FQDNs to include in the output
        [string[]]$Known,

        # File paths whose server FQDNs to include in the output
        [string[]]$FilePath,

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId

    )

    $Progress = @{
        Activity = 'Expand-Folder'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }

    Write-Progress @Progress -Status '0%' -CurrentOperation 'Initializing' -PercentComplete 0

    $UniqueValues = @{}

    ForEach ($Value in $Known) {
        $UniqueValues[$Value] = $null
    }

    #why would this be needed?  why add the full path?  I am expecting only fqdns as output right?
    #ForEach ($Value in $FilePath) {
    #    $UniqueValues[$Value] = $null
    #}

    # Add server names from the ACL paths
    $Count = $FilePath.Count
    [int]$ProgressInterval = [math]::max(($Count / 100), 1)
    $IntervalCounter = 0
    $i = 0

    ForEach ($ThisPath in $FilePath) {
        $IntervalCounter++
        if ($IntervalCounter -eq $ProgressInterval) {
            [int]$PercentComplete = $i / $Count * 100
            Write-Progress @Progress -Status "$PercentComplete% ($($i + 1) of $Count paths)" -CurrentOperation "Find-ServerNameInPath '$ThisPath'" -PercentComplete $PercentComplete
            $IntervalCounter = 0
        }
        $i++ # increment $i after Write-Progress to show progress conservatively rather than optimistically
        $UniqueValues[(Find-ServerNameInPath -LiteralPath $ThisPath -ThisFqdn $ThisFqdn)] = $null
    }

    Write-Progress @Progress -Completed

    return $UniqueValues.Keys

}
