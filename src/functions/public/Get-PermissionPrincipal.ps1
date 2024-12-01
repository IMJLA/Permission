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

        # Properties of each Account to display on the report
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description')

    )

    $Progress = Get-PermissionProgress -Activity 'Get-PermissionPrincipal' -Cache $Cache
    [string[]]$IDs = $Cache.Value['AceGuidByID'].Value.Keys
    $Count = $IDs.Count
    Write-Progress @Progress -Status "0% (identity 0 of $Count) ConvertFrom-ResolvedID" -CurrentOperation 'Initialize' -PercentComplete 0
    $Log = @{ 'Cache' = $Cache }

    $AdsiParams = @{
        'AccountProperty' = $AccountProperty
        'Cache'           = $Cache
    }

    $ThreadCount = $Cache.Value['ThreadCount'].Value

    if ($ThreadCount -eq 1) {

        if ($NoGroupMembers) {
            $AdsiParams['NoGroupMembers'] = $true
        }

        [int]$ProgressInterval = [math]::max(($Count / 100), 1)
        $IntervalCounter = 0
        $i = 0

        ForEach ($ThisID in $IDs) {

            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {

                [int]$PercentComplete = $i / $Count * 100
                Write-Progress @Progress -Status "$PercentComplete% (identity $($i + 1) of $Count) ConvertFrom-ResolvedID" -CurrentOperation $ThisID -PercentComplete $PercentComplete
                $IntervalCounter = 0

            }

            $i++
            Write-LogMsg @Log -Text "ConvertFrom-ResolvedID -IdentityReference '$ThisID'" -Expand $AdsiParams -ExpansionMap $Cache.Value['LogCacheMap'].Value
            ConvertFrom-ResolvedID -IdentityReference $ThisID @AdsiParams

        }

    } else {

        if ($NoGroupMembers) {
            $AdsiParams['AddSwitch'] = 'NoGroupMembers'
        }

        $SplitThreadParams = @{
            Command              = 'ConvertFrom-ResolvedID'
            InputObject          = $IDs
            InputParameter       = 'IdentityReference'
            ObjectStringProperty = 'Name'
            #TodaysHostname       = $ThisHostname
            #WhoAmI               = $WhoAmI
            #LogBuffer            = $LogBuffer
            #Threads              = $ThreadCount
            #ProgressParentId     = $Progress['Id']
            AddParam             = $AdsiParams
        }

        Write-LogMsg @Log -Text 'Split-Thread' -Expand $SplitThreadParams
        Split-Thread @SplitThreadParams

    }

    Write-Progress @Progress -Completed

}
