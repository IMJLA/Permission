function Get-DetailDivHeader {
    param (
        [string]$GroupBy
    )

    switch ($GroupBy) {
        'account' { 'Folders Included in Those Permissions' }
        'item' { 'Accounts Included in Those Permissions' }
        'target' { 'Target Folders Analyzed in This Report' }
        'none' { 'Permissions' }
    }

}
