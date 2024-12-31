function Resolve-SplitByParameter {

    param (

        <#
        How to split up the exported files:

        | Value   | Behavior |
        |---------|----------|
        | none    | generate 1 report file with all permissions |
        | source  | generate 1 report file per source path (default) |
        | item    | generate 1 report file per item |
        | account | generate 1 report file per account |
        #>
        [ValidateSet('account', 'item', 'none', 'source')]
        [string[]]$SplitBy = 'source'

    )

    $result = @{}

    foreach ($Split in $SplitBy) {

        if ($Split -eq 'none') {

            return @{'none' = $true }

        } elseif ($Split -eq 'all') {

            return @{
                'source'  = $true
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
