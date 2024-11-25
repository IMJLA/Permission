function Get-PermissionTrustedDomain {

    param (

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    Get-TrustedDomain -Cache $Cache

}
