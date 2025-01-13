function Update-PermissionCache {

    <#
    Pre-populate caches in memory to avoid redundant ADSI and CIM queries
    Use known ADSI and CIM server FQDNs to populate six caches:
       Three caches of known ADSI directory servers
         The first cache is keyed on domain SID (e.g. S-1-5-2)
         The second cache is keyed on domain FQDN (e.g. ad.contoso.com)
         The first cache is keyed on domain NetBIOS name (e.g. CONTOSO)
       Two caches of known Win32_Account instances
         The first cache is keyed on SID (e.g. S-1-5-2)
         The second cache is keyed on the Caption (NT Account name e.g. CONTOSO\user1)
       Also populate a cache of DirectoryEntry objects for any domains that have them
     This prevents threads that start near the same time from finding the cache empty and attempting costly operations to populate it
     This prevents repetitive queries to the same directory servers
    #>

    param (

        # FQDNs of the ADSI servers to use to populate the cache
        [string[]]$Fqdn,

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $Progress = Get-PermissionProgress -Activity 'Initialize-Cache' -Cache $Cache
    $Count = $Fqdn.Count
    $LogBuffer = $Cache.Value['LogBuffer']

    $GetAdsiServer = @{
        Cache = $Cache
    }

    $ThreadCount = $Cache.Value['ThreadCount'].Value

    if ($ThreadCount -eq 1) {

        $i = 0

        ForEach ($ThisServerName in $Fqdn) {

            [int]$PercentComplete = $i / $Count * 100
            $i++ # increment $i after Write-Progress to show progress conservatively rather than optimistically
            Write-Progress -Status "$PercentComplete% (FQDN $i of $Count) Get-AdsiServer" -CurrentOperation "Get-AdsiServer '$ThisServerName'" -PercentComplete $PercentComplete @Progress
            Write-LogMsg -Text "Get-AdsiServer -Fqdn '$ThisServerName'" -Expand $GetAdsiServer -Cache $Cache -ExpansionMap $Cache.Value['LogCacheMap'].Value
            $null = Get-AdsiServer -Fqdn $ThisServerName @GetAdsiServer

        }

    } else {

        $SplitThread = @{
            Command          = 'Get-AdsiServer'
            InputObject      = $Fqdn
            InputParameter   = 'Fqdn'
            TodaysHostname   = $ThisHostname
            WhoAmI           = $WhoAmI
            LogBuffer        = $LogBuffer
            Timeout          = 600
            Threads          = $ThreadCount
            ProgressParentId = $ProgressParentId
            AddParam         = $GetAdsiServer
        }

        Write-LogMsg -Text "Split-Thread -Command 'Get-AdsiServer' -InputParameter AdsiServer -InputObject @('$($Fqdn -join "',")')" -Cache $Cache
        $null = Split-Thread @SplitThread

    }

    Write-Progress @Progress -Completed

}
