function Get-PermissionPrincipal {

    param (

        <#
        Do not get group members (only report the groups themselves)

        Note: By default, the -ExcludeClass parameter will exclude groups from the report.
          If using -NoGroupMembers, you most likely want to modify the value of -ExcludeClass.
          Remove the 'group' class from ExcludeClass in order to see groups on the report.
        #>
        [switch]$NoGroupMembers,

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache,

        # The current domain
        # Can be passed as a parameter to reduce calls to Get-CurrentDomain
        [PSCustomObject]$CurrentDomain = (Get-CurrentDomain -Cache $Cache),

        # Properties of each Account to display on the report
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description')

    )

    $Progress = @{
        Activity = 'Get-PermissionPrincipal'
    }
    $ProgressParentId = $Cache.Value['ProgressParentId'].Value
    if ($ProgressParentId ) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }

    [string[]]$IDs = $Cache.Value['AceGuidByID'].Value.Keys
    $Count = $IDs.Count
    Write-Progress @Progress -Status "0% (identity 0 of $Count) ConvertFrom-IdentityReferenceResolved" -CurrentOperation 'Initialize' -PercentComplete 0
    $Log = @{ 'Cache' = $Cache }

    $ADSIConversionParams = @{
        'AccountProperty' = $AccountProperty
        'Cache'           = $Cache
        'CurrentDomain'   = $CurrentDomain
    }

    $ThreadCount = $Cache.Value['ThreadCount'].Value

    if ($ThreadCount -eq 1) {

        if ($NoGroupMembers) {
            $ADSIConversionParams['NoGroupMembers'] = $true
        }

        [int]$ProgressInterval = [math]::max(($Count / 100), 1)
        $IntervalCounter = 0
        $i = 0

        ForEach ($ThisID in $IDs) {

            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {

                [int]$PercentComplete = $i / $Count * 100
                Write-Progress @Progress -Status "$PercentComplete% (identity $($i + 1) of $Count) ConvertFrom-IdentityReferenceResolved" -CurrentOperation $ThisID -PercentComplete $PercentComplete
                $IntervalCounter = 0

            }

            $i++
            Write-LogMsg @Log -Text "ConvertFrom-IdentityReferenceResolved -IdentityReference '$ThisID'" -Expand $ADSIConversionParams -ExpansionMap $Cache.Value['LogCacheMap'].Value
            ConvertFrom-IdentityReferenceResolved -IdentityReference $ThisID @ADSIConversionParams

        }

    } else {

        if ($NoGroupMembers) {
            $ADSIConversionParams['AddSwitch'] = 'NoGroupMembers'
        }

        $SplitThreadParams = @{
            Command              = 'ConvertFrom-IdentityReferenceResolved'
            InputObject          = $IDs
            InputParameter       = 'IdentityReference'
            ObjectStringProperty = 'Name'
            #TodaysHostname       = $ThisHostname
            #WhoAmI               = $WhoAmI
            #LogBuffer            = $LogBuffer
            #Threads              = $ThreadCount
            #ProgressParentId     = $Progress['Id']
            AddParam             = $ADSIConversionParams
        }

        Write-LogMsg @Log -Text 'Split-Thread' -Expand $SplitThreadParams
        Split-Thread @SplitThreadParams

    }

    Write-Progress @Progress -Completed

}
