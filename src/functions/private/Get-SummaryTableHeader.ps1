function Get-SummaryTableHeader {
    param (
        [int]$RecurseDepth,
        [String]$GroupBy
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
                    'Includes the target path only (option to report on child items was declined)'
                    break
                }
                -1 {
                    'Includes the target path and all child items with unique permissions'
                    break
                }
                default {
                    "Includes the target path and $RecurseDepth levels of child items with unique permissions"
                    break
                }
            }
            break

        }

        'target' {
            break
        }

    }

}
