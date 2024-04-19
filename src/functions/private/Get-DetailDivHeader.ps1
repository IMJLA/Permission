function Get-DetailDivHeader {

    param (
        [String]$GroupBy,
        [String]$Split
    )

    if ( $GroupBy -eq $Split ) {

        'Permissions'

    } else {

        switch ($GroupBy) {
            'account' { 'Folders Included in Those Permissions'; break }
            'item' { 'Accounts Included in Those Permissions'; break }
            'target' { 'Target Paths'; break }
            'none' { 'Permissions'; break }
        }

    }

}
