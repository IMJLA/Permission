function Get-SummaryDivHeader {

    param (
        [String]$GroupBy,
        [String]$Split
    )

    if ( $GroupBy -eq $Split ) {

        'Permissions'

    } else {

        switch ($GroupBy) {
            'account' { 'Accounts with Access'; break }
            'item' { 'Items in Those Paths with Unique Permissions'; break }
            'target' { 'Target Paths'; break }
            'none' { 'Permissions'; break }
        }

    }

}
