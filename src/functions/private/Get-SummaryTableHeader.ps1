function Get-SummaryTableHeader {
    param (
        [int]$RecurseDepth,
        [string]$GroupBy
    )

    switch ($GroupBy) {

        'account' {

            if ($NoMembers) {

                switch ($RecurseDepth ) {
                    0 {
                        'Includes accounts directly listed in the ACLs of the target folders only'
                    }
                    -1 {
                        'Includes accounts directly listed in the ACLs of the target folders and all subfolders with unique permissions'
                    }
                    default {
                        "Includes accounts directly listed in the ACLs of the target folders and $RecurseDepth levels of subfolders with unique permissions"
                    }
                }

            } else {

                switch ($RecurseDepth ) {
                    0 {
                        'Includes accounts (and their group members) in the ACLs of the target folders only'
                    }
                    -1 {
                        'Includes accounts (and their group members) in the ACLs of the target folders and all subfolders with unique permissions'
                    }
                    default {
                        "Includes accounts (and their group members) in the ACLs of the target folders and $RecurseDepth levels of subfolders with unique permissions"
                    }
                }

            }

        }

        'item' {

            switch ($RecurseDepth ) {
                0 {
                    'Includes the target folder only (option to report on subfolders was declined)'
                }
                -1 {
                    'Includes the target folder and all subfolders with unique permissions'
                }
                default {
                    "Includes the target folder and $RecurseDepth levels of subfolders with unique permissions"
                }
            }

        }

        'target' { }

    }

}
