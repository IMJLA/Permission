function Get-SummaryTableHeader {
    param (
        [int]$RecurseDepth,
        [string]$GroupBy
    )

    if ($GroupBy -eq 'account') {

        'Account Details'

    } else {

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

}
