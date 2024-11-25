function Resolve-AccessControlList {

    # Wrapper to multithread Resolve-Acl
    # Resolve identities in access control lists to their SIDs and NTAccount names

    param (

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [String]$DebugOutputStream = 'Debug',

        # Maximum number of concurrent threads to allow
        [int]$ThreadCount = (Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum,

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [String]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [String]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [String]$WhoAmI = (whoami.EXE),

        # ID of the parent progress bar under which to show progress
        [int]$ProgressParentId,

        # String translations indexed by value in the [System.Security.AccessControl.InheritanceFlags] enum
        # Parameter default value is on a single line as a workaround to a PlatyPS bug
        [string[]]$InheritanceFlagResolved = @('this folder but not subfolders', 'this folder and subfolders', 'this folder and files, but not subfolders', 'this folder, subfolders, and files'),

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache,

        # Properties of each Account to display on the report
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description')

    )

    $Log = @{ ThisHostname = $ThisHostname ; Type = $DebugOutputStream ; Buffer = $Cache.Value['LogBuffer'] ; WhoAmI = $WhoAmI }

    $Progress = @{
        Activity = 'Resolve-AccessControlList'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }

    $ACLsByPath = $Cache.Value['AclByPath']
    $Paths = $ACLsByPath.Value.Keys
    $Count = $Paths.Count
    Write-Progress @Progress -Status "0% (ACL 0 of $Count)" -CurrentOperation 'Initializing' -PercentComplete 0
    $ACEPropertyName = $ACLsByPath.Value.Values.Access[0].PSObject.Properties.GetEnumerator().Name

    $ResolveAclParams = @{
        AccountProperty         = $AccountProperty
        ACEPropertyName         = $ACEPropertyName
        Cache                   = $Cache
        InheritanceFlagResolved = $InheritanceFlagResolved
        ThisHostName            = $ThisHostName
        ThisFqdn                = $ThisFqdn
        WhoAmI                  = $WhoAmI
    }

    if ($ThreadCount -eq 1) {

        [int]$ProgressInterval = [math]::max(($Count / 100), 1)
        $IntervalCounter = 0
        $i = 0
        Write-LogMsg @Log -Text "`$Cache.Value['AclByPath'].Value.Keys | %{ Resolve-Acl -ItemPath '`$_'" -Expand $ResolveAclParams -Suffix " } # for $Count ACLs" -ExpandKeyMap @{ Cache = '$Cache' }

        ForEach ($ThisPath in $Paths) {

            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {

                [int]$PercentComplete = $i / $Count * 100
                Write-Progress @Progress -Status "$PercentComplete% (ACL $($i + 1) of $Count) Resolve-Acl" -CurrentOperation $ThisPath -PercentComplete $PercentComplete
                $IntervalCounter = 0

            }

            $i++ # increment $i after Write-Progress to show progress conservatively rather than optimistically
            #Write-LogMsg @Log -Text "Resolve-Acl -ItemPath '$ThisPath'" -Expand $ResolveAclParams
            Resolve-Acl -ItemPath $ThisPath @ResolveAclParams

        }

    } else {

        $SplitThreadParams = @{
            Command          = 'Resolve-Acl'
            InputObject      = $Paths
            InputParameter   = 'ItemPath'
            TodaysHostname   = $ThisHostname
            WhoAmI           = $WhoAmI
            LogBuffer        = $Cache.Value['LogBuffer']
            Threads          = $ThreadCount
            ProgressParentId = $Progress['Id']
            AddParam         = $ResolveAclParams
            #DebugOutputStream    = 'Debug'
        }

        Write-LogMsg @Log -Text 'Split-Thread' -Expand $SplitThreadParams
        Split-Thread @SplitThreadParams

    }

    Write-Progress @Progress -Completed

}
