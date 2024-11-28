function ConvertTo-PermissionFqdn {

    param (

        # DNS or NetBIOS hostname whose DNS FQDN to lookup
        [Parameter(Mandatory)]
        [string]$ComputerName,

        # Update the ThisFqdn cache instead of returning the Fqdn
        [switch]$ThisFqdn,

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    Write-LogMsg -Text "ConvertTo-DnsFqdn -ComputerName '$ComputerName' -Cache `$Cache -ThisFqdn:$ThisFqdn" -Cache $Cache
    ConvertTo-DnsFqdn -ComputerName $ComputerName -Cache $Cache -ThisFqdn:$ThisFqdn

}
