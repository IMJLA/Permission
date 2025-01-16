function Get-DetailDivHeader {

    param (
        <#
        How to group the permissions in the output stream and within each exported file. Interacts with the SplitBy parameter:

        | SplitBy | GroupBy | Behavior |
        |---------|---------|----------|
        | none    | none    | 1 file with all permissions in a flat list |
        | none    | account | 1 file with all permissions grouped by account |
        | none    | item    | 1 file with all permissions grouped by item |
        | none    | source    | 1 file with all permissions grouped by source path |
        | account | none    | 1 file per account; in each file, sort permissions by item path |
        | account | account | (same as -SplitBy account -GroupBy none) |
        | account | item    | 1 file per account; in each file, group permissions by item and sort by item path |
        | account | source  | 1 file per account; in each file, group permissions by source path and sort by item path |
        | source  | none    | 1 file per source path; in each file, sort permissions by item path |
        | source  | account | 1 file per source path; in each file, group permissions by account and sort by account name |
        | source  | item    | 1 file per source path; in each file, group permissions by item and sort by item path |
        | source  | source  | (same as -SplitBy source -GroupBy none) |
        #>
        [ValidateSet('account', 'item', 'none', 'source')]
        [string]$GroupBy = 'item',
        [String]$Split
    )

    if ( $GroupBy -eq $Split ) {

        'Permissions'

    } else {

        switch ($GroupBy) {
            'account' { 'Access for Each Account'; break }
            'item' {

                if ($Split -eq 'Account') { 'Permissions' }
                else { 'Accounts Included in Those Permissions' }
                break

            }
            'source' { 'Source Paths'; break }
            'none' { 'Permissions'; break }
        }

    }

}
