
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
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName)

    )

    Write-Progress -Activity 'Get-UniqueAdsiServerName' -CurrentOperation 'Initializing' -Status '0%' -PercentComplete 0

    $UniqueValues = @{}

    ForEach ($Value in $Known) {
        $UniqueValues[$Value] = $null
    }

    ForEach ($Value in $FilePath) {
        $UniqueValues[$Value] = $null
    }

    # Add server names from the ACL paths
    [int]$ProgressInterval = [math]::max(($Permissions.Count / 100), 1)
    $ProgressCounter = 0
    $i = 0

    ForEach ($ThisPath in $Permissions.SourceAccessList.Path) {
        $ProgressCounter++
        if ($ProgressCounter -eq $ProgressInterval) {
            $PercentComplete = $i / $Permissions.Count * 100
            Write-Progress -Activity 'Get-UniqueAdsiServerName' -CurrentOperation "Find-ServerNameInPath '$ThisPath'" -Status "$([int]$PercentComplete)%" -PercentComplete 50
            $ProgressCounter = 0
        }
        $i++ # increment $i after Write-Progress to show progress conservatively rather than optimistically
        $UniqueValues[(Find-ServerNameInPath -LiteralPath $ThisPath -ThisFqdn $ThisFqdn)] = $null
    }

    Write-Progress -Activity 'Get-UniqueAdsiServerName' -Completed

    return $UniqueValues.Keys

}
