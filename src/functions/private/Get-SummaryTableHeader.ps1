function Get-SummaryTableHeader {
    param (

        # How many levels of child items were enumerated for the report
        [int]$RecurseDepth,

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
        [string]$GroupBy = 'item'

    )

    switch ($GroupBy) {

        'account' {

            if ($NoMembers) {

                'Includes accounts directly listed in the permissions only (option to include group members was declined)'

            } else {

                'Includes accounts in the permissions, and their group members'

            }
            break

        }

        'item' {

            switch ($RecurseDepth ) {
                0 {
                    'Includes the source path only (option to report on child items was declined)'
                    break
                }
                -1 {
                    'Includes the source path and all child items with unique permissions'
                    break
                }
                default {
                    "Includes the source path and $RecurseDepth levels of child items with unique permissions"
                    break
                }
            }
            break

        }

        'source' {
            break
        }

    }

}
