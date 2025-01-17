function Resolve-AccessControlList {

    # Wrapper to multithread Resolve-Acl
    # Resolve identities in access control lists to their SIDs and NTAccount names

    param (

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache,

        # Properties of each Account to display on the report
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description')

    )

    $Log = @{ 'Cache' = $Cache }

    $Progress = Get-PermissionProgress -Activity 'Resolve-AccessControlList' -Cache $Cache
    $ACLsByPath = $Cache.Value['AclByPath']
    $Paths = $ACLsByPath.Value.Keys
    $Count = $Paths.Count
    Write-Progress @Progress -Status "0% (ACL 0 of $Count)" -CurrentOperation 'Initializing' -PercentComplete 0
    $ACEPropertyName = $ACLsByPath.Value.Values.Access[0].PSObject.Properties.GetEnumerator().Name

    $ResolveAclParams = @{
        AccountProperty = $AccountProperty
        ACEPropertyName = $ACEPropertyName
        Cache           = $Cache
    }

    $ThreadCount = $Cache.Value['ThreadCount'].Value

    if ($ThreadCount -eq 1) {


        [int]$ProgressInterval = [math]::max(($Count / 100), 1)
        $IntervalCounter = 0
        $i = 0
        Write-LogMsg @Log -ExpansionMap $Cache.Value['LogCacheMap'].Value -Expand $ResolveAclParams -Text "`$Cache.Value['AclByPath'].Value.Keys | %{ Resolve-Acl -ItemPath '`$_'" -Suffix " } # for $Count ACLs"

        ForEach ($ThisPath in $Paths) {

            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {

                [int]$PercentComplete = $i / $Count * 100
                Write-Progress @Progress -Status "$PercentComplete% (ACL $($i + 1) of $Count) Resolve-Acl" -CurrentOperation $ThisPath -PercentComplete $PercentComplete
                $IntervalCounter = 0

            }

            $i++ # increment $i after Write-Progress to show progress conservatively rather than optimistically
            #Write-LogMsg @Log -ExpansionMap $Cache.Value['LogCacheMap'].Value -Expand $ResolveAclParams -Text "Resolve-Acl -ItemPath '$ThisPath'"
            Resolve-Acl -ItemPath $ThisPath @ResolveAclParams

        }

    } else {

        $SplitThreadParams = @{
            Command          = 'Resolve-Acl'
            InputObject      = $Paths
            InputParameter   = 'ItemPath'
            TodaysHostname   = $Cache.Value['ThisHostname'].Value
            WhoAmI           = $Cache.Value['WhoAmI'].Value
            LogBuffer        = $Cache.Value['LogBuffer']
            Threads          = $ThreadCount
            ProgressParentId = $Progress['Id']
            AddParam         = $ResolveAclParams
            #DebugOutputStream    = 'Debug'
        }

        Write-LogMsg @Log -ExpansionMap $Cache.Value['LogEmptyMap'].Value -Expand $SplitThreadParams -Text 'Split-Thread'
        Split-Thread @SplitThreadParams

    }

    Write-Progress @Progress -Completed

}
