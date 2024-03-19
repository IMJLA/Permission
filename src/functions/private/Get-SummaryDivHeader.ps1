function Get-SummaryDivHeader {
    param (
        [string]$GroupBy
    )

    switch ($GroupBy) {
        'account' { 'Accounts with Permissions in This Report' }
        'item' { 'Folders with Permissions in This Report' }
        'target' { 'Target Folders Analyzed in This Report' }
    }

}
