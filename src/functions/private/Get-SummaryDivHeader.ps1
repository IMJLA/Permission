function Get-SummaryDivHeader {

    param (
        [String]$GroupBy,
        [String]$Split
    )

    if ( $GroupBy -eq $Split ) {

        'Permissions'

    } else {

        switch ($GroupBy) {
            'account' { 'Accounts With Permissions'; break }
            'item' { 'Items With Unique Permissions'; break }
            'target' { 'Target Paths'; break }
            'none' { 'Permissions'; break }
        }

    }

}
