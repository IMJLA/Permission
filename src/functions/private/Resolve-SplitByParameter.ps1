function Resolve-SplitByParameter {

    param (

        <#
    How to split up the exported files:
        none    generate a single file with all permissions
        item    generate a file per item
        account generate a file per account
        all     generate 1 file per item and 1 file per account and 1 file with all permissions.
    #>
        [ValidateSet('none', 'all', 'item', 'account')]
        [string[]]$SplitBy = 'all'

    )

    $result = @{}

    foreach ($Split in $SplitBy) {

        if ($Split -eq 'none') {

            return @{'none' = $true }

        } elseif ($Split -eq 'all') {

            return @{
                'none'    = $true
                'item'    = $true
                'account' = $true
            }

        } else {

            $result[$Split] = $true

        }

    }

    return $result

}
