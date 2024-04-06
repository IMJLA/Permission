function Get-SummaryTableHeader {
    param (
        [int]$RecurseDepth,
        [string]$GroupBy
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
                    'Includes the target folder only (option to report on subfolders was declined)'
                    break
                }
                -1 {
                    'Includes the target folder and all subfolders with unique permissions'
                    break
                }
                default {
                    "Includes the target folder and $RecurseDepth levels of subfolders with unique permissions"
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
