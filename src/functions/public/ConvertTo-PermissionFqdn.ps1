function ConvertTo-PermissionFqdn {

    param (

        # DNS or NetBIOS hostname whose DNS FQDN to lookup
        [Parameter(Mandatory)]
        [string]$ComputerName,

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    Write-LogMsg -Text "ConvertTo-DnsFqdn -ComputerName '$ComputerName' -Cache `$Cache" -Cache $Cache
    ConvertTo-DnsFqdn -ComputerName $ComputerName -Cache $Cache

}
