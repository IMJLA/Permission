function Get-SummaryDivHeader {

    param (
        [string]$GroupBy,
        [string]$Split
    )

    if ( $GroupBy -eq $Split ) {

        'Permissions'

    } else {

        switch ($GroupBy) {
            'account' { 'Folders Included in Those Permissions' }
            'item' { 'Accounts Included in Those Permissions' }
            'target' { 'Target Paths' }
            'none' { 'Permissions' }
        }

    }

}
