function Get-CachedCimInstance {

    param (

        # Name of the computer to query via CIM
        [String]$ComputerName,

        # Name of the CIM class whose instances to return
        [String]$ClassName,

        # Name of the CIM namespace containing the class
        [String]$Namespace,

        # CIM query to run. Overrides ClassName if used (but not efficiently, so don't use both)
        [String]$Query,

        [Parameter(Mandatory)]
        [String]$KeyProperty,

        [string[]]$CacheByProperty = $KeyProperty,

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $Log = @{
        'Cache'  = $Cache
        'Suffix' = " # for ComputerName '$ComputerName'"
    }

    if ($PSBoundParameters.ContainsKey('ClassName')) {
        $InstanceCacheKey = "$ClassName`By$KeyProperty"
    } else {
        $InstanceCacheKey = "$Query`By$KeyProperty"
    }

    $CimCache = $Cache.Value['CimCache']
    $CimServer = $CimCache.Value[$ComputerName]
    $String = [type]'String'

    if ($CimServer) {

        #Write-LogMsg @Log -Text " # CIM server cache hit"
        $InstanceCache = $CimServer.Value[$InstanceCacheKey]

        if ($InstanceCache) {

            #Write-LogMsg @Log -Text " # CIM instance cache hit for '$InstanceCacheKey'"
            return $InstanceCache.Value.Values

        } else {
            #Write-LogMsg @Log -Text " # CIM instance cache miss for '$InstanceCacheKey'"
        }

    } else {

        #Write-LogMsg @Log -Text " # CIM server cache miss"
        $CimServer = New-PermissionCacheRef -Key $String -Value ([type]'System.Management.Automation.PSReference')
        $CimCache.Value[$ComputerName] = $CimServer

    }

    Write-LogMsg @Log -Text "`$CimSession = Get-CachedCimSession -ComputerName '$ComputerName' -Cache `$Cache"
    $CimSession = Get-CachedCimSession -ComputerName $ComputerName -Cache $Cache

    if ($CimSession) {

        $GetCimInstanceParams = @{
            Cache       = $Cache
            CimSession  = $CimSession
            ErrorAction = 'SilentlyContinue'
            Debug       = $false
        }

        $Cache.Value['LogCimSessionMap'] = $Cache.Value['LogCacheMap'].Value + @{ 'CimSession' = '$CimSession' }

        if ($Namespace) {
            $GetCimInstanceParams['Namespace'] = $Namespace
        }

        if ($PSBoundParameters.ContainsKey('ClassName')) {

            Write-LogMsg @Log -Text "Get-CimInstance -ClassName '$ClassName'" -Expand $GetCimInstanceParams -MapKeyName 'LogCimSessionMap'
            $CimInstance = Get-CimInstance -ClassName $ClassName @GetCimInstanceParams

        }

        if ($PSBoundParameters.ContainsKey('Query')) {

            Write-LogMsg @Log -Text "Get-CimInstance -Query '$Query'" -Expand $GetCimInstanceParams -MapKeyName 'LogCimSessionMap'
            $CimInstance = Get-CimInstance -Query $Query @GetCimInstanceParams

        }

        if ($CimInstance) {

            $CimInstanceType = [System.Collections.Generic.List[CimInstance]]

            ForEach ($Prop in $CacheByProperty) {

                $InstanceCache = New-PermissionCacheRef -Key $String -Value $CimInstanceType

                if ($PSBoundParameters.ContainsKey('ClassName')) {
                    $InstanceCacheKey = "$ClassName`By$Prop"
                } else {
                    $InstanceCacheKey = "$Query`By$Prop"
                }

                #Write-LogMsg @Log -Text " # Create the '$InstanceCacheKey' cache"
                $CimServer.Value[$InstanceCacheKey] = $InstanceCache

                ForEach ($Instance in $CimInstance) {

                    $InstancePropertyValue = $Instance.$Prop
                    #Write-LogMsg @Log -Text " # Add '$InstancePropertyValue' to the '$InstanceCacheKey' cache"
                    $InstanceCache.Value[$InstancePropertyValue] = $Instance

                }

            }

            return $CimInstance

        } else {
            #Write-LogMsg @Log -Text " # No CIM instance returned # for $ClassName$Query"
        }

    } else {
        $Log['Type'] = 'Warning'
        Write-LogMsg @Log -Text ' # CIM connection failure'
    }

}
