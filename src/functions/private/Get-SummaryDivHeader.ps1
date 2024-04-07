function Get-SummaryDivHeader {

    param (
        [string]$GroupBy,
        [string]$Split
    )

    if ( $GroupBy -eq $Split ) {

        'Permissions'

    } else {

        switch ($GroupBy) {
            'account' { 'Folders Included in Those Permissions'; break }
            'item' { 'Items With Unique Permissions'; break }
            'target' { 'Target Paths'; break }
            'none' { 'Permissions'; break }
        }

    }

}
